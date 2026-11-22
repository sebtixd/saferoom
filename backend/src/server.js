import { createServer } from 'node:http';
import { randomUUID } from 'node:crypto';
import { fileURLToPath } from 'node:url';
import { resolve } from 'node:path';
import { loadConfig } from './config.js';
import { openDatabase } from './db.js';
import { hashPassword, verifyPassword } from './passwords.js';
import {
  createAccessToken,
  createOpaqueToken,
  verifyAccessToken,
  TokenError,
} from './tokens.js';

class HttpError extends Error {
  constructor(status, code, message, fields, headers) {
    super(message);
    this.name = 'HttpError';
    this.status = status;
    this.code = code;
    this.fields = fields;
    this.headers = headers;
  }
}

const EMAIL_RE = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
const RATE_LIMIT_STORE = new Map();

function validateCredentials(body) {
  const email = typeof body?.email === 'string' ? body.email.trim().toLowerCase() : '';
  const password = typeof body?.password === 'string' ? body.password : '';
  const fields = {};
  if (!EMAIL_RE.test(email)) fields.email = 'Enter a valid email address';
  if (password.length < 8) fields.password = 'Password must be at least 8 characters';
  if (Object.keys(fields).length > 0) {
    throw new HttpError(400, 'validation_error', 'Invalid registration details', fields);
  }
  return { email, password };
}

function corsHeaders(config, req) {
  const origin = req.headers.origin;
  const allowAny = config.allowedOrigins.includes('*');
  const allowedOrigin = allowAny
    ? '*'
    : origin && config.allowedOrigins.includes(origin)
      ? origin
      : null;

  const headers = {
    'Access-Control-Allow-Methods': 'GET, POST, PUT, PATCH, DELETE, OPTIONS',
    'Access-Control-Allow-Headers': 'Authorization, Content-Type',
    'Access-Control-Max-Age': '86400',
    Vary: 'Origin',
  };
  if (allowedOrigin) {
    headers['Access-Control-Allow-Origin'] = allowedOrigin;
  }
  return headers;
}

function securityHeaders(config) {
  const headers = {
    'X-Content-Type-Options': 'nosniff',
    'X-Frame-Options': 'DENY',
    'Referrer-Policy': 'no-referrer',
    'Permissions-Policy': 'geolocation=(), microphone=(), camera=()',
    'Cross-Origin-Resource-Policy': 'same-site',
  };
  if (config.isProduction || config.enforceHttps) {
    headers['Strict-Transport-Security'] = 'max-age=31536000; includeSubDomains';
  }
  return headers;
}

function send(res, config, req, status, payload, extraHeaders = {}) {
  const headers = {
    'Content-Type': 'application/json; charset=utf-8',
    'Cache-Control': 'no-store',
    ...securityHeaders(config),
    ...corsHeaders(config, req),
    ...extraHeaders,
  };
  res.writeHead(status, headers);
  res.end(JSON.stringify(payload));
}

function getClientIp(req, config) {
  if (config.trustProxy) {
    const forwarded = req.headers['x-forwarded-for'];
    if (typeof forwarded === 'string' && forwarded.trim()) {
      return forwarded.split(',')[0].trim();
    }
  }
  return req.socket?.remoteAddress || 'unknown';
}

function isHttps(req, config) {
  if (!config.enforceHttps) return true;
  if (req.socket?.encrypted) return true;
  if (config.trustProxy) {
    const proto = req.headers['x-forwarded-proto'];
    if (typeof proto === 'string' && proto.toLowerCase() === 'https') return true;
  }
  return false;
}

function enforceHttps(req, config) {
  if (isHttps(req, config)) return;
  throw new HttpError(
    400,
    'https_required',
    'HTTPS is required. Use an HTTPS endpoint in production.',
  );
}

function enforceCors(req, config) {
  const origin = req.headers.origin;
  if (!origin) return;
  if (config.allowedOrigins.includes('*')) return;
  if (!config.allowedOrigins.includes(origin)) {
    throw new HttpError(403, 'origin_not_allowed', 'Origin is not allowed');
  }
}

function isAuthRateLimitedPath(url) {
  return (
    url.pathname.startsWith('/api/auth/') ||
    url.pathname === '/api/auth/login' ||
    url.pathname === '/api/auth/register'
  );
}

function applyRateLimit(req, config, url) {
  const now = Date.now();
  const windowMs = Math.max(1000, config.rateLimitWindowMs || 60000);
  const max = isAuthRateLimitedPath(url)
    ? Math.max(1, config.authRateLimitMax || 10)
    : Math.max(1, config.rateLimitMax || 60);
  const ip = getClientIp(req, config);
  const bucketName = isAuthRateLimitedPath(url) ? 'auth' : 'general';
  const key = `${bucketName}:${ip}`;

  // Opportunistic cleanup to keep memory bounded.
  if (RATE_LIMIT_STORE.size > 5000) {
    for (const [k, v] of RATE_LIMIT_STORE) {
      if (v.resetAt <= now) RATE_LIMIT_STORE.delete(k);
    }
  }

  const existing = RATE_LIMIT_STORE.get(key);
  if (!existing || existing.resetAt <= now) {
    RATE_LIMIT_STORE.set(key, { count: 1, resetAt: now + windowMs });
    return { limit: max, remaining: max - 1, resetAt: now + windowMs };
  }

  existing.count += 1;
  const remaining = Math.max(0, max - existing.count);
  if (existing.count > max) {
    const retryAfter = Math.max(1, Math.ceil((existing.resetAt - now) / 1000));
    throw new HttpError(429, 'rate_limited', 'Too many requests. Try again later.', null, {
      'Retry-After': String(retryAfter),
      'X-RateLimit-Limit': String(max),
      'X-RateLimit-Remaining': '0',
      'X-RateLimit-Reset': String(Math.ceil(existing.resetAt / 1000)),
    });
  }

  return {
    limit: max,
    remaining,
    resetAt: existing.resetAt,
  };
}

async function readJson(req) {
  const chunks = [];
  let size = 0;
  for await (const chunk of req) {
    size += chunk.length;
    if (size > 16 * 1024) {
      throw new HttpError(413, 'payload_too_large', 'Request body is too large');
    }
    chunks.push(chunk);
  }
  if (size === 0) return {};
  try {
    return JSON.parse(Buffer.concat(chunks).toString('utf8'));
  } catch {
    throw new HttpError(400, 'invalid_json', 'Request body must be valid JSON');
  }
}

function issueSession(db, config, user) {
  const nowIso = new Date().toISOString();
  const accessToken = createAccessToken(user, config.secret, config.accessTtlSeconds);
  const refreshToken = createOpaqueToken();
  const expiresAt = new Date(
    Date.now() + config.refreshTtlDays * 24 * 60 * 60 * 1000,
  ).toISOString();
  db.saveRefreshToken({
    id: randomUUID(),
    userId: user.id,
    token: refreshToken,
    expiresAt,
    now: nowIso,
  });
  return {
    user: { ...db.publicUser(user), emotional_profile: db.getEmotionalProfile(user.id) },
    accessToken,
    refreshToken,
    expiresIn: config.accessTtlSeconds,
  };
}

function authenticatedUser(req, db, config) {
  const header = req.headers.authorization ?? '';
  const match = /^Bearer\s+(.+)$/i.exec(header);
  if (!match) {
    throw new HttpError(401, 'invalid_token', 'Authorization header is required');
  }
  let claims;
  try {
    claims = verifyAccessToken(match[1], config.secret);
  } catch (error) {
    if (error instanceof TokenError) {
      throw new HttpError(401, error.code, error.message);
    }
    throw error;
  }
  const user = db.findUserById(claims.sub);
  if (!user) {
    throw new HttpError(401, 'invalid_token', 'User no longer exists');
  }
  return user;
}

function validateProfile(body, userId, now) {
  const fields = {};
  const int = (key, min, max) => {
    const value = body?.[key];
    if (typeof value !== 'number' || !Number.isFinite(value) || value < min || value > max) {
      fields[key] = `Must be a number between ${min} and ${max}`;
      return min;
    }
    return Math.round(value);
  };
  const list = (key) => {
    const value = body?.[key];
    if (!Array.isArray(value) || !value.every((item) => typeof item === 'string')) {
      fields[key] = 'Must be a list of strings';
      return [];
    }
    return value;
  };

  const profile = {
    id: randomUUID(),
    user_id: userId,
    mood_baseline: int('mood_baseline', 1, 10),
    stress_level: int('stress_level', 1, 10),
    energy_level: int('energy_level', 1, 10),
    happiness_triggers: list('happiness_triggers'),
    anger_triggers: list('anger_triggers'),
    calming_factors: list('calming_factors'),
    preferred_color:
      typeof body?.preferred_color === 'string' ? body.preferred_color : '#6B5CE7',
    spiritual_preference:
      typeof body?.spiritual_preference === 'string' ? body.spiritual_preference : null,
    work_rhythm: typeof body?.work_rhythm === 'string' ? body.work_rhythm : 'regular',
    created_at: now,
    updated_at: now,
  };
  if (Object.keys(fields).length > 0) {
    throw new HttpError(400, 'validation_error', 'Invalid emotional profile', fields);
  }
  return profile;
}

function validateDailyTask(body, userId, now) {
  const fields = {};
  const date = typeof body?.date === 'string' ? body.date : '';
  if (!/^\d{4}-\d{2}-\d{2}$/.test(date)) {
    fields.date = 'Must be YYYY-MM-DD';
  }
  if (!Array.isArray(body?.tasks)) {
    fields.tasks = 'Must be a list of tasks';
  } else if (
    !body.tasks.every(
      (task) =>
        task &&
        typeof task.text === 'string' &&
        task.text.trim().length > 0 &&
        typeof task.completed === 'boolean',
    )
  ) {
    fields.tasks = 'Each task needs text and a completed boolean';
  }
  if (Object.keys(fields).length > 0) {
    throw new HttpError(400, 'validation_error', 'Invalid daily tasks', fields);
  }
  return {
    id: typeof body.id === 'string' && body.id ? body.id : randomUUID(),
    user_id: userId,
    date,
    tasks: body.tasks.map((task) => ({ text: task.text, completed: task.completed })),
    created_at: typeof body.created_at === 'string' ? body.created_at : now,
    updated_at: now,
  };
}

export function createAuthApp(configIn) {
  const config = configIn ?? loadConfig();
  const db = openDatabase(config.dbPath);

  async function handler(req, res) {
    const url = new URL(req.url ?? '/', 'http://localhost');
    const path = url.pathname;
    try {
      enforceHttps(req, config);
      enforceCors(req, config);

      if (req.method === 'OPTIONS') {
        res.writeHead(204, {
          ...securityHeaders(config),
          ...corsHeaders(config, req),
        });
        res.end();
        return;
      }

      const rate = applyRateLimit(req, config, url);
      const rateHeaders = {
        'X-RateLimit-Limit': String(rate.limit),
        'X-RateLimit-Remaining': String(rate.remaining),
        'X-RateLimit-Reset': String(Math.ceil(rate.resetAt / 1000)),
      };

      if (req.method === 'GET' && path === '/api/health') {
        send(res, config, req, 200, { status: 'ok' }, rateHeaders);
        return;
      }

      if (req.method === 'POST' && path === '/api/auth/register') {
        const { email, password } = validateCredentials(await readJson(req));
        if (db.findUserByEmail(email)) {
          throw new HttpError(409, 'email_taken', 'An account with this email already exists');
        }
        const now = new Date().toISOString();
        const user = db.createUser({
          id: randomUUID(),
          email,
          passwordHash: hashPassword(password),
          now,
        });
        send(res, config, req, 201, issueSession(db, config, user), rateHeaders);
        return;
      }

      if (req.method === 'POST' && path === '/api/auth/login') {
        const { email, password } = validateCredentials(await readJson(req));
        const user = db.findUserByEmail(email);
        if (!user || !verifyPassword(password, user.password_hash)) {
          throw new HttpError(401, 'invalid_credentials', 'Invalid email or password');
        }
        send(res, config, req, 200, issueSession(db, config, user), rateHeaders);
        return;
      }

      if (req.method === 'POST' && path === '/api/auth/refresh') {
        const { refreshToken } = await readJson(req);
        const stored = typeof refreshToken === 'string' ? db.findRefreshToken(refreshToken) : null;
        const now = new Date().toISOString();
        if (!stored || stored.revoked_at || stored.expires_at <= now) {
          throw new HttpError(401, 'invalid_refresh_token', 'Refresh token is invalid or expired');
        }
        const user = db.findUserById(stored.user_id);
        if (!user) {
          throw new HttpError(401, 'invalid_refresh_token', 'User no longer exists');
        }
        db.revokeRefreshToken(stored.id, now);
        send(res, config, req, 200, issueSession(db, config, user), rateHeaders);
        return;
      }

      if (req.method === 'POST' && path === '/api/auth/logout') {
        const { refreshToken } = await readJson(req);
        if (typeof refreshToken === 'string') {
          const stored = db.findRefreshToken(refreshToken);
          if (stored && !stored.revoked_at) {
            db.revokeRefreshToken(stored.id, new Date().toISOString());
          }
        }
        send(res, config, req, 200, { success: true }, rateHeaders);
        return;
      }

      if (req.method === 'GET' && path === '/api/auth/me') {
        const user = authenticatedUser(req, db, config);
        send(res, config, req, 200, {
          user: { ...db.publicUser(user), emotional_profile: db.getEmotionalProfile(user.id) },
        }, rateHeaders);
        return;
      }

      const userById = /^\/api\/users\/([^/]+)$/.exec(path);
      if (req.method === 'GET' && userById) {
        const caller = authenticatedUser(req, db, config);
        if (caller.id !== userById[1]) {
          throw new HttpError(403, 'forbidden', 'Cannot access another user');
        }
        send(res, config, req, 200, { user: db.publicUser(caller) }, rateHeaders);
        return;
      }

      if (req.method === 'PATCH' && path === '/api/me') {
        const user = authenticatedUser(req, db, config);
        const body = await readJson(req);
        if (typeof body.points !== 'number' || !Number.isInteger(body.points) || body.points < 0) {
          throw new HttpError(400, 'validation_error', 'points must be a non-negative integer', {
            points: 'Must be a non-negative integer',
          });
        }
        const updated = db.updatePoints(user.id, body.points, new Date().toISOString());
        send(res, config, req, 200, { user: db.publicUser(updated) }, rateHeaders);
        return;
      }

      if (req.method === 'PUT' && path === '/api/me/emotional-profile') {
        const user = authenticatedUser(req, db, config);
        const body = await readJson(req);
        const profile = validateProfile(body, user.id, new Date().toISOString());
        send(res, config, req, 200, { emotionalProfile: db.upsertEmotionalProfile(profile) }, rateHeaders);
        return;
      }

      if (req.method === 'GET' && path === '/api/daily-tasks') {
        const user = authenticatedUser(req, db, config);
        const requestedUserId = url.searchParams.get('user_id') ?? user.id;
        const date = url.searchParams.get('date');
        if (requestedUserId !== user.id) {
          throw new HttpError(403, 'forbidden', 'Cannot access another user');
        }
        if (!date || !/^\d{4}-\d{2}-\d{2}$/.test(date)) {
          throw new HttpError(400, 'validation_error', 'date must be YYYY-MM-DD', {
            date: 'Must be YYYY-MM-DD',
          });
        }
        send(res, config, req, 200, {
          dailyTask: db.getDailyTaskByUserAndDate(user.id, date),
        }, rateHeaders);
        return;
      }

      if (req.method === 'POST' && path === '/api/daily-tasks') {
        const user = authenticatedUser(req, db, config);
        const task = validateDailyTask(
          await readJson(req),
          user.id,
          new Date().toISOString(),
        );
        send(res, config, req, 201, { dailyTask: db.upsertDailyTask(task) }, rateHeaders);
        return;
      }

      const dailyTaskById = /^\/api\/daily-tasks\/([^/]+)$/.exec(path);
      if (req.method === 'GET' && dailyTaskById) {
        const user = authenticatedUser(req, db, config);
        const stored = db.getDailyTaskById(dailyTaskById[1]);
        if (!stored) {
          throw new HttpError(404, 'not_found', 'Daily task not found');
        }
        if (stored.user_id !== user.id) {
          throw new HttpError(403, 'forbidden', 'Cannot access another user');
        }
        send(res, config, req, 200, { dailyTask: stored }, rateHeaders);
        return;
      }

      if (req.method === 'PUT' && dailyTaskById) {
        const user = authenticatedUser(req, db, config);
        const stored = db.getDailyTaskById(dailyTaskById[1]);
        if (!stored) {
          throw new HttpError(404, 'not_found', 'Daily task not found');
        }
        if (stored.user_id !== user.id) {
          throw new HttpError(403, 'forbidden', 'Cannot modify another user');
        }
        const body = await readJson(req);
        if (!Array.isArray(body.tasks)) {
          throw new HttpError(400, 'validation_error', 'tasks must be a list', {
            tasks: 'Must be a list of tasks',
          });
        }
        const updated = db.updateDailyTaskTasks(
          stored.id,
          body.tasks,
          new Date().toISOString(),
        );
        send(res, config, req, 200, { dailyTask: updated }, rateHeaders);
        return;
      }

      if (req.method === 'POST' && path === '/api/auth/forgot-password') {
        const { email } = await readJson(req);
        const user = typeof email === 'string' ? db.findUserByEmail(email.trim().toLowerCase()) : null;
        const response = { success: true };
        if (user) {
          const token = createOpaqueToken();
          db.saveResetToken({
            id: randomUUID(),
            userId: user.id,
            token,
            expiresAt: new Date(Date.now() + 60 * 60 * 1000).toISOString(),
            now: new Date().toISOString(),
          });
          if (config.exposeResetTokens) response.resetToken = token;
        }
        send(res, config, req, 200, response, rateHeaders);
        return;
      }

      if (req.method === 'POST' && path === '/api/auth/reset-password') {
        const { token, newPassword } = await readJson(req);
        if (typeof newPassword !== 'string' || newPassword.length < 8) {
          throw new HttpError(400, 'validation_error', 'Password must be at least 8 characters', {
            newPassword: 'Must be at least 8 characters',
          });
        }
        const stored = typeof token === 'string' ? db.findResetToken(token) : null;
        const now = new Date().toISOString();
        if (!stored || stored.used_at || stored.expires_at <= now) {
          throw new HttpError(400, 'invalid_reset_token', 'Reset token is invalid or expired');
        }
        db.updatePassword(stored.user_id, hashPassword(newPassword), now);
        db.consumeResetToken(stored.id, now);
        db.revokeAllRefreshTokens(stored.user_id, now);
        send(res, config, req, 200, { success: true }, rateHeaders);
        return;
      }

      throw new HttpError(404, 'not_found', 'Endpoint not found');
    } catch (error) {
      if (error instanceof HttpError) {
        send(res, config, req, error.status, {
          error: {
            code: error.code,
            message: error.message,
            ...(error.fields ? { fields: error.fields } : {}),
          },
        });
        return;
      }
      console.error('Unhandled backend error:', error);
      send(res, config, req, 500, {
        error: { code: 'internal_error', message: 'An unexpected error occurred' },
      });
    }
  }

  return { handler, db, config };
}

const isMain =
  process.argv[1] && resolve(process.argv[1]) === fileURLToPath(import.meta.url);
if (isMain) {
  const { handler, config } = createAuthApp();
  createServer(handler).listen(config.port, config.host, () => {
    console.log(`SafeRoom auth API listening on http://${config.host}:${config.port}`);
    console.log(`Database: ${config.dbPath}`);
  });
}
