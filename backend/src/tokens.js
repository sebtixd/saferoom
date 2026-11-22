import {
  createHmac,
  randomBytes,
  timingSafeEqual,
  createHash,
} from 'node:crypto';

export class TokenError extends Error {
  constructor(code, message) {
    super(message);
    this.name = 'TokenError';
    this.code = code;
  }
}

function b64url(input) {
  return Buffer.from(input).toString('base64url');
}

function sign(data, secret) {
  return createHmac('sha256', secret).update(data).digest('base64url');
}

export function createAccessToken(user, secret, ttlSeconds) {
  const now = Math.floor(Date.now() / 1000);
  const header = b64url(JSON.stringify({ alg: 'HS256', typ: 'JWT' }));
  const payload = b64url(
    JSON.stringify({
      sub: user.id,
      email: user.email,
      typ: 'access',
      iat: now,
      exp: now + ttlSeconds,
    }),
  );
  const body = `${header}.${payload}`;
  return `${body}.${sign(body, secret)}`;
}

export function verifyAccessToken(token, secret) {
  if (typeof token !== 'string') {
    throw new TokenError('invalid_token', 'Missing access token');
  }
  const parts = token.split('.');
  if (parts.length !== 3) {
    throw new TokenError('invalid_token', 'Malformed access token');
  }

  const [header, payload, signature] = parts;
  const expected = Buffer.from(sign(`${header}.${payload}`, secret));
  const actual = Buffer.from(signature);
  if (expected.length !== actual.length || !timingSafeEqual(expected, actual)) {
    throw new TokenError('invalid_token', 'Invalid access token signature');
  }

  let claims;
  try {
    claims = JSON.parse(Buffer.from(payload, 'base64url').toString('utf8'));
  } catch {
    throw new TokenError('invalid_token', 'Malformed access token payload');
  }

  if (claims.typ !== 'access' || typeof claims.sub !== 'string') {
    throw new TokenError('invalid_token', 'Invalid access token claims');
  }
  if (typeof claims.exp !== 'number' || claims.exp * 1000 <= Date.now()) {
    throw new TokenError('token_expired', 'Access token has expired');
  }
  return claims;
}

export function createOpaqueToken() {
  return randomBytes(32).toString('base64url');
}

export function hashToken(token) {
  return createHash('sha256').update(token).digest('hex');
}
