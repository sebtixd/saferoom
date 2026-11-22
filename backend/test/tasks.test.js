import test from 'node:test';
import assert from 'node:assert/strict';
import { createServer } from 'node:http';
import { mkdtempSync, rmSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { createAuthApp } from '../src/server.js';

function withServer(fn) {
  const dir = mkdtempSync(join(tmpdir(), 'saferoom-tasks-'));
  const { handler } = createAuthApp({
    dbPath: join(dir, 'test.db'),
    secret: 'test-secret-that-is-definitely-long-enough',
    host: '127.0.0.1',
    port: 0,
    accessTtlSeconds: 900,
    refreshTtlDays: 30,
    allowedOrigins: ['*'],
    exposeResetTokens: true,
  });
  const server = createServer(handler);
  return new Promise((resolve, reject) => {
    server.listen(0, '127.0.0.1', async () => {
      const base = `http://127.0.0.1:${server.address().port}`;
      try {
        await fn(base);
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
  return { status: response.status, json: await response.json().catch(() => ({})) };
}

async function register(base, email) {
  const result = await api(base, '/api/auth/register', {
    method: 'POST',
    body: { email, password: 'password123' },
  });
  return result.json;
}

test('daily tasks persist in SQLite and can be updated', () =>
  withServer(async (base) => {
    const session = await register(base, 'tasks@example.com');
    const token = session.accessToken;
    const date = '2026-11-22';
    const body = {
      date,
      tasks: [
        { text: 'Drink water', completed: false },
        { text: 'Take a walk', completed: true },
      ],
    };

    const empty = await api(
      base,
      `/api/daily-tasks?user_id=${session.user.id}&date=${date}`,
      { token },
    );
    assert.equal(empty.status, 200);
    assert.equal(empty.json.dailyTask, null);

    const created = await api(base, '/api/daily-tasks', { method: 'POST', body, token });
    assert.equal(created.status, 201);
    assert.equal(created.json.dailyTask.user_id, session.user.id);
    assert.equal(created.json.dailyTask.tasks.length, 2);
    assert.equal(created.json.dailyTask.tasks[0].completed, false);

    const fetched = await api(
      base,
      `/api/daily-tasks?user_id=${session.user.id}&date=${date}`,
      { token },
    );
    assert.equal(fetched.json.dailyTask.id, created.json.dailyTask.id);

    const byId = await api(base, `/api/daily-tasks/${created.json.dailyTask.id}`, {
      token,
    });
    assert.equal(byId.status, 200);
    assert.equal(byId.json.dailyTask.tasks.length, 2);

    const updated = await api(base, `/api/daily-tasks/${created.json.dailyTask.id}`, {
      method: 'PUT',
      token,
      body: {
        tasks: [{ text: 'Drink water', completed: true }],
      },
    });
    assert.equal(updated.status, 200);
    assert.equal(updated.json.dailyTask.tasks[0].completed, true);
  }));

test('daily tasks require auth and reject malformed payloads', () =>
  withServer(async (base) => {
    const unauth = await api(base, '/api/daily-tasks?date=2026-11-22');
    assert.equal(unauth.status, 401);

    const session = await register(base, 'tasks2@example.com');
    const invalid = await api(base, '/api/daily-tasks', {
      method: 'POST',
      token: session.accessToken,
      body: { date: 'not-a-date', tasks: [] },
    });
    assert.equal(invalid.status, 400);
    assert.equal(invalid.json.error.code, 'validation_error');
  }));
