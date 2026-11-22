import { DatabaseSync } from 'node:sqlite';
import { mkdirSync } from 'node:fs';
import { dirname } from 'node:path';
import { hashToken } from './tokens.js';

const SCHEMA = `
CREATE TABLE IF NOT EXISTS users (
  id            TEXT PRIMARY KEY,
  email         TEXT NOT NULL UNIQUE COLLATE NOCASE,
  password_hash TEXT NOT NULL,
  points        INTEGER NOT NULL DEFAULT 0,
  created_at    TEXT NOT NULL,
  updated_at    TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS emotional_profiles (
  id                    TEXT PRIMARY KEY,
  user_id               TEXT NOT NULL UNIQUE REFERENCES users(id) ON DELETE CASCADE,
  mood_baseline         INTEGER NOT NULL,
  stress_level          INTEGER NOT NULL,
  energy_level          INTEGER NOT NULL,
  happiness_triggers    TEXT NOT NULL DEFAULT '[]',
  anger_triggers        TEXT NOT NULL DEFAULT '[]',
  calming_factors       TEXT NOT NULL DEFAULT '[]',
  preferred_color       TEXT NOT NULL DEFAULT '#6B5CE7',
  spiritual_preference  TEXT,
  work_rhythm           TEXT NOT NULL DEFAULT 'regular',
  created_at            TEXT NOT NULL,
  updated_at            TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS refresh_tokens (
  id          TEXT PRIMARY KEY,
  user_id     TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  token_hash  TEXT NOT NULL UNIQUE,
  expires_at  TEXT NOT NULL,
  revoked_at  TEXT,
  created_at  TEXT NOT NULL
);
CREATE INDEX IF NOT EXISTS idx_refresh_user ON refresh_tokens(user_id);

CREATE TABLE IF NOT EXISTS password_reset_tokens (
  id          TEXT PRIMARY KEY,
  user_id     TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  token_hash  TEXT NOT NULL UNIQUE,
  expires_at  TEXT NOT NULL,
  used_at     TEXT,
  created_at  TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS daily_tasks (
  id          TEXT PRIMARY KEY,
  user_id     TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  date        TEXT NOT NULL,
  tasks       TEXT NOT NULL DEFAULT '[]',
  created_at  TEXT NOT NULL,
  updated_at  TEXT NOT NULL,
  UNIQUE (user_id, date)
);
CREATE INDEX IF NOT EXISTS idx_daily_tasks_user_date ON daily_tasks(user_id, date);
`;

function parseList(value) {
  try {
    const parsed = JSON.parse(value ?? '[]');
    return Array.isArray(parsed) ? parsed : [];
  } catch {
    return [];
  }
}

function publicUser(row) {
  if (!row) return null;
  return {
    id: row.id,
    email: row.email,
    is_anonymous: false,
    created_at: row.created_at,
    points: row.points,
  };
}

function profileFromRow(row) {
  if (!row) return null;
  return {
    id: row.id,
    user_id: row.user_id,
    mood_baseline: row.mood_baseline,
    stress_level: row.stress_level,
    energy_level: row.energy_level,
    happiness_triggers: parseList(row.happiness_triggers),
    anger_triggers: parseList(row.anger_triggers),
    calming_factors: parseList(row.calming_factors),
    preferred_color: row.preferred_color,
    spiritual_preference: row.spiritual_preference,
    work_rhythm: row.work_rhythm,
    created_at: row.created_at,
    updated_at: row.updated_at,
  };
}

function dailyTaskFromRow(row) {
  if (!row) return null;
  return {
    id: row.id,
    user_id: row.user_id,
    date: row.date,
    tasks: parseList(row.tasks),
    created_at: row.created_at,
    updated_at: row.updated_at,
  };
}

export function openDatabase(dbPath) {
  mkdirSync(dirname(dbPath), { recursive: true });
  const db = new DatabaseSync(dbPath);
  // Performance-oriented SQLite pragmas for a small local/embedded backend.
  db.exec('PRAGMA foreign_keys = ON;');
  db.exec('PRAGMA journal_mode = WAL;');
  db.exec('PRAGMA synchronous = NORMAL;');
  db.exec('PRAGMA temp_store = MEMORY;');
  db.exec('PRAGMA busy_timeout = 5000;');
  db.exec(SCHEMA);

  return {
    close: () => db.close(),

    createUser({ id, email, passwordHash, now }) {
      db.prepare(
        `INSERT INTO users (id, email, password_hash, points, created_at, updated_at)
         VALUES (?, ?, ?, 0, ?, ?)`,
      ).run(id, email, passwordHash, now, now);
      return this.findUserById(id);
    },

    findUserByEmail(email) {
      return db.prepare('SELECT * FROM users WHERE email = ? COLLATE NOCASE').get(email) ?? null;
    },

    findUserById(id) {
      return db.prepare('SELECT * FROM users WHERE id = ?').get(id) ?? null;
    },

    updatePassword(userId, passwordHash, now) {
      db.prepare('UPDATE users SET password_hash = ?, updated_at = ? WHERE id = ?').run(
        passwordHash,
        now,
        userId,
      );
    },

    updatePoints(userId, points, now) {
      db.prepare('UPDATE users SET points = ?, updated_at = ? WHERE id = ?').run(
        points,
        now,
        userId,
      );
      return this.findUserById(userId);
    },

    saveRefreshToken({ id, userId, token, expiresAt, now }) {
      db.prepare(
        `INSERT INTO refresh_tokens (id, user_id, token_hash, expires_at, revoked_at, created_at)
         VALUES (?, ?, ?, ?, NULL, ?)`,
      ).run(id, userId, hashToken(token), expiresAt, now);
    },

    findRefreshToken(token) {
      return (
        db
          .prepare('SELECT * FROM refresh_tokens WHERE token_hash = ?')
          .get(hashToken(token)) ?? null
      );
    },

    revokeRefreshToken(id, now) {
      db.prepare('UPDATE refresh_tokens SET revoked_at = ? WHERE id = ?').run(now, id);
    },

    revokeAllRefreshTokens(userId, now) {
      db.prepare('UPDATE refresh_tokens SET revoked_at = ? WHERE user_id = ? AND revoked_at IS NULL').run(
        now,
        userId,
      );
    },

    saveResetToken({ id, userId, token, expiresAt, now }) {
      db.prepare(
        `INSERT INTO password_reset_tokens (id, user_id, token_hash, expires_at, used_at, created_at)
         VALUES (?, ?, ?, ?, NULL, ?)`,
      ).run(id, userId, hashToken(token), expiresAt, now);
    },

    findResetToken(token) {
      return (
        db
          .prepare('SELECT * FROM password_reset_tokens WHERE token_hash = ?')
          .get(hashToken(token)) ?? null
      );
    },

    consumeResetToken(id, now) {
      db.prepare('UPDATE password_reset_tokens SET used_at = ? WHERE id = ?').run(now, id);
    },

    upsertEmotionalProfile(profile) {
      const existing = db
        .prepare('SELECT * FROM emotional_profiles WHERE user_id = ?')
        .get(profile.user_id);
      if (existing) {
        db.prepare(
          `UPDATE emotional_profiles SET
             mood_baseline = ?, stress_level = ?, energy_level = ?,
             happiness_triggers = ?, anger_triggers = ?, calming_factors = ?,
             preferred_color = ?, spiritual_preference = ?, work_rhythm = ?, updated_at = ?
           WHERE user_id = ?`,
        ).run(
          profile.mood_baseline,
          profile.stress_level,
          profile.energy_level,
          JSON.stringify(profile.happiness_triggers),
          JSON.stringify(profile.anger_triggers),
          JSON.stringify(profile.calming_factors),
          profile.preferred_color,
          profile.spiritual_preference,
          profile.work_rhythm,
          profile.updated_at,
          profile.user_id,
        );
      } else {
        db.prepare(
          `INSERT INTO emotional_profiles (
             id, user_id, mood_baseline, stress_level, energy_level,
             happiness_triggers, anger_triggers, calming_factors,
             preferred_color, spiritual_preference, work_rhythm, created_at, updated_at
           ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
        ).run(
          profile.id,
          profile.user_id,
          profile.mood_baseline,
          profile.stress_level,
          profile.energy_level,
          JSON.stringify(profile.happiness_triggers),
          JSON.stringify(profile.anger_triggers),
          JSON.stringify(profile.calming_factors),
          profile.preferred_color,
          profile.spiritual_preference,
          profile.work_rhythm,
          profile.created_at,
          profile.updated_at,
        );
      }
      return profileFromRow(
        db.prepare('SELECT * FROM emotional_profiles WHERE user_id = ?').get(profile.user_id),
      );
    },

    getEmotionalProfile(userId) {
      return profileFromRow(
        db.prepare('SELECT * FROM emotional_profiles WHERE user_id = ?').get(userId),
      );
    },

    upsertDailyTask(task) {
      db.prepare(
        `INSERT INTO daily_tasks (id, user_id, date, tasks, created_at, updated_at)
         VALUES (?, ?, ?, ?, ?, ?)
         ON CONFLICT(user_id, date) DO UPDATE SET
           tasks = excluded.tasks,
           updated_at = excluded.updated_at`,
      ).run(
        task.id,
        task.user_id,
        task.date,
        JSON.stringify(task.tasks),
        task.created_at,
        task.updated_at,
      );
      return this.getDailyTaskByUserAndDate(task.user_id, task.date);
    },

    getDailyTaskByUserAndDate(userId, date) {
      return dailyTaskFromRow(
        db
          .prepare('SELECT * FROM daily_tasks WHERE user_id = ? AND date = ?')
          .get(userId, date),
      );
    },

    getDailyTaskById(id) {
      return dailyTaskFromRow(db.prepare('SELECT * FROM daily_tasks WHERE id = ?').get(id));
    },

    updateDailyTaskTasks(id, tasks, updatedAt) {
      db.prepare('UPDATE daily_tasks SET tasks = ?, updated_at = ? WHERE id = ?').run(
        JSON.stringify(tasks),
        updatedAt,
        id,
      );
      return this.getDailyTaskById(id);
    },

    publicUser,
    profileFromRow,
  };
}
