import { randomBytes } from 'node:crypto';
import { existsSync, mkdirSync, readFileSync, writeFileSync } from 'node:fs';
import { dirname, resolve } from 'node:path';

function readOrCreateSecret(secretPath) {
  if (existsSync(secretPath)) {
    return readFileSync(secretPath, 'utf8').trim();
  }
  const secret = randomBytes(48).toString('base64url');
  mkdirSync(dirname(secretPath), { recursive: true });
  writeFileSync(secretPath, secret, { mode: 0o600 });
  return secret;
}

function parseBool(value, fallback = false) {
  if (value == null) return fallback;
  return ['1', 'true', 'yes', 'on'].includes(String(value).toLowerCase());
}

export function loadConfig(env = process.env) {
  const nodeEnv = (env.NODE_ENV ?? 'development').toLowerCase();
  const isProduction = nodeEnv === 'production';

  const dbPath = resolve(env.SAFEROOM_DB_PATH ?? './backend/data/saferoom.db');
  mkdirSync(dirname(dbPath), { recursive: true });

  let secret = env.SAFEROOM_JWT_SECRET;
  if (!secret) {
    if (isProduction) {
      throw new Error(
        'SAFEROOM_JWT_SECRET must be set in production (min 32 chars).',
      );
    }
    secret = readOrCreateSecret(
      resolve(env.SAFEROOM_JWT_SECRET_FILE ?? './backend/data/jwt_secret'),
    );
  }

  if (secret.length < 32) {
    throw new Error('SAFEROOM_JWT_SECRET must be at least 32 characters long');
  }

  const allowedOrigins = (env.SAFEROOM_ALLOWED_ORIGINS ?? (isProduction ? '' : '*'))
    .split(',')
    .map((origin) => origin.trim())
    .filter(Boolean);

  if (isProduction) {
    if (allowedOrigins.length === 0 || allowedOrigins.includes('*')) {
      throw new Error(
        'SAFEROOM_ALLOWED_ORIGINS must be set to explicit origins in production (no "*").',
      );
    }
  }

  const rateLimitWindowMs = Number.parseInt(
    env.SAFEROOM_RATE_LIMIT_WINDOW_MS ?? '60000',
    10,
  );
  const rateLimitMax = Number.parseInt(env.SAFEROOM_RATE_LIMIT_MAX ?? '60', 10);
  const authRateLimitMax = Number.parseInt(
    env.SAFEROOM_AUTH_RATE_LIMIT_MAX ?? '10',
    10,
  );

  return Object.freeze({
    nodeEnv,
    isProduction,
    host: env.HOST ?? '0.0.0.0',
    port: Number.parseInt(env.PORT ?? '3000', 10),
    dbPath,
    secret,
    accessTtlSeconds: Number.parseInt(env.ACCESS_TOKEN_TTL_SECONDS ?? '900', 10),
    refreshTtlDays: Number.parseInt(env.REFRESH_TOKEN_TTL_DAYS ?? '30', 10),
    allowedOrigins,
    exposeResetTokens: parseBool(env.SAFEROOM_EXPOSE_RESET_TOKENS, false),
    enforceHttps: parseBool(env.SAFEROOM_ENFORCE_HTTPS, isProduction),
    trustProxy: parseBool(env.SAFEROOM_TRUST_PROXY, false),
    rateLimitWindowMs: Number.isFinite(rateLimitWindowMs) ? rateLimitWindowMs : 60000,
    rateLimitMax: Number.isFinite(rateLimitMax) ? rateLimitMax : 60,
    authRateLimitMax: Number.isFinite(authRateLimitMax) ? authRateLimitMax : 10,
  });
}
