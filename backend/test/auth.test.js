import test from 'node:test';
import assert from 'node:assert/strict';
import { createServer } from 'node:http';
import { mkdtempSync, rmSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { createAuthApp } from '../src/server.js';
import { openDatabase } from '../src/db.js';
import { hashPassword, verifyPassword } from '../src/passwords.js';

function withServer(fn) {
  const dir = mkdtempSync(join(tmpdir(), 'saferoom-auth-'));
  const { handler } = createAuthApp({
    dbPath: join(dir, 'test.db'),
    secret: 'test-secret-that-is-definitely-long-enough',
    host: '127.0.0.1',
    port: 0,
    accessTtlSeconds: 900,
    refreshTtlDays: 30,
    allowedOrigins: ['*'],
    exposeResetTokens: true,
    rateLimitMax: 1000,
    authRateLimitMax: 1000,
    rateLimitWindowMs: 60000,
    enforceHttps: false,
  });
  const server = createServer(handler);
  return new Promise((resolve, reject) => {
    server.listen(0, '127.0.0.1', async () => {
      const base = `http://127.0.0.1:${server.address().port}`;
      try {
        await fn(base, dir);
        resolve();
      } catch (error) {
        reject(error);
      } finally {
        server.close();
        rmSync(dir, { recursive: true, force: true });
      }
    });
    server.on('error', reject);
  });
}

async function api(base, path, { method = 'GET', body, token } = {}) {
  const response = await fetch(`${base}${path}`, {
    method,
    headers: {
      ...(body ? { 'Content-Type': 'application/json' } : {}),
      ...(token ? { Authorization: `Bearer ${token}` } : {}),
    },
    ...(body ? { body: JSON.stringify(body) } : {}),
  });
  const json = await response.json().catch(() => ({}));
  return { status: response.status, json };
}

const credentials = { email: 'Test.User@Example.com', password: 'correct horse battery' };

test('password hashing uses scrypt and verifies correctly', () => {
  const hash = hashPassword(credentials.password);
  assert.match(hash, /^scrypt\$/);
  assert.equal(verifyPassword(credentials.password, hash), true);
  assert.equal(verifyPassword('wrong-password', hash), false);
});

test('register -> login -> me -> logout works end-to-end', () =>
  withServer(async (base, dir) => {
    const registered = await api(base, '/api/auth/register', {
      method: 'POST',
      body: credentials,
    });
    assert.equal(registered.status, 201);
    assert.equal(registered.json.user.email, credentials.email.toLowerCase());
    assert.ok(registered.json.accessToken);
    assert.ok(registered.json.refreshToken);
    assert.equal(registered.json.user.emotional_profile, null);

    const db = openDatabase(join(dir, 'test.db'));
    const row = db.findUserByEmail(credentials.email);
    assert.notEqual(row.password_hash, credentials.password);
    assert.match(row.password_hash, /^scrypt\$/);

    const duplicate = await api(base, '/api/auth/register', {
      method: 'POST',
      body: credentials,
    });
    assert.equal(duplicate.status, 409);
    assert.equal(duplicate.json.error.code, 'email_taken');

    const badLogin = await api(base, '/api/auth/login', {
      method: 'POST',
      body: { email: credentials.email, password: 'wrong-password' },
    });
    assert.equal(badLogin.status, 401);
    assert.equal(badLogin.json.error.code, 'invalid_credentials');

    const login = await api(base, '/api/auth/login', { method: 'POST', body: credentials });
    assert.equal(login.status, 200);

    const me = await api(base, '/api/auth/me', { token: login.json.accessToken });
    assert.equal(me.status, 200);
    assert.equal(me.json.user.id, login.json.user.id);

    const noAuth = await api(base, '/api/auth/me');
    assert.equal(noAuth.status, 401);

    const tampered = await api(base, '/api/auth/me', {
      token: `${login.json.accessToken}tampered`,
    });
    assert.equal(tampered.status, 401);

    const logout = await api(base, '/api/auth/logout', {
      method: 'POST',
      body: { refreshToken: login.json.refreshToken },
    });
    assert.equal(logout.status, 200);

    const revokedRefresh = await api(base, '/api/auth/refresh', {
      method: 'POST',
      body: { refreshToken: login.json.refreshToken },
    });
    assert.equal(revokedRefresh.status, 401);

    db.close();
  }));

test('refresh tokens rotate and old tokens cannot be reused', () =>
  withServer(async (base) => {
    const session = await api(base, '/api/auth/register', { method: 'POST', body: credentials });
    const refreshed = await api(base, '/api/auth/refresh', {
      method: 'POST',
      body: { refreshToken: session.json.refreshToken },
    });
    assert.equal(refreshed.status, 200);
    assert.notEqual(refreshed.json.refreshToken, session.json.refreshToken);

    const replay = await api(base, '/api/auth/refresh', {
      method: 'POST',
      body: { refreshToken: session.json.refreshToken },
    });
    assert.equal(replay.status, 401);
    assert.equal(replay.json.error.code, 'invalid_refresh_token');
  }));

test('emotional profile persists and is returned by /me', () =>
  withServer(async (base) => {
    const session = await api(base, '/api/auth/register', { method: 'POST', body: credentials });
    const profile = {
      mood_baseline: 7,
      stress_level: 3,
      energy_level: 8,
      happiness_triggers: ['family'],
      anger_triggers: ['traffic'],
      calming_factors: ['breathing'],
      preferred_color: '#6B5CE7',
      spiritual_preference: 'Islam',
      work_rhythm: 'regular',
    };
    const saved = await api(base, '/api/me/emotional-profile', {
      method: 'PUT',
      token: session.json.accessToken,
      body: profile,
    });
    assert.equal(saved.status, 200);
    assert.equal(saved.json.emotionalProfile.mood_baseline, 7);

    const me = await api(base, '/api/auth/me', { token: session.json.accessToken });
    assert.equal(me.json.user.emotional_profile.happiness_triggers[0], 'family');
  }));

test('password reset changes password and revokes sessions', () =>
  withServer(async (base) => {
    const session = await api(base, '/api/auth/register', { method: 'POST', body: credentials });
    const forgot = await api(base, '/api/auth/forgot-password', {
      method: 'POST',
      body: { email: credentials.email },
    });
    assert.equal(forgot.status, 200);
    assert.ok(forgot.json.resetToken);

    const reset = await api(base, '/api/auth/reset-password', {
      method: 'POST',
      body: { token: forgot.json.resetToken, newPassword: 'a-brand-new-password' },
    });
    assert.equal(reset.status, 200);

    const oldLogin = await api(base, '/api/auth/login', { method: 'POST', body: credentials });
    assert.equal(oldLogin.status, 401);

    const newLogin = await api(base, '/api/auth/login', {
      method: 'POST',
      body: { email: credentials.email, password: 'a-brand-new-password' },
    });
    assert.equal(newLogin.status, 200);

    const oldRefresh = await api(base, '/api/auth/refresh', {
      method: 'POST',
      body: { refreshToken: session.json.refreshToken },
    });
    assert.equal(oldRefresh.status, 401);
  }));

test('validation rejects weak passwords and malformed emails', () =>
  withServer(async (base) => {
    const weak = await api(base, '/api/auth/register', {
      method: 'POST',
      body: { email: 'ok@example.com', password: 'short' },
    });
    assert.equal(weak.status, 400);
    assert.equal(weak.json.error.code, 'validation_error');

    const invalidEmail = await api(base, '/api/auth/register', {
      method: 'POST',
      body: { email: 'not-an-email', password: 'long-enough-password' },
    });
    assert.equal(invalidEmail.status, 400);
    assert.ok(invalidEmail.json.error.fields.email);
  }));
