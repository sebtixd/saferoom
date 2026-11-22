# SafeRoom

A gamified mental-health Flutter app. Authentication is backed by a small,
self-contained Node.js + SQLite API in [`backend/`](backend/) — no Firebase
account is needed for signup/login/logout/session persistence.

Firebase is still used by the remaining non-auth features (chat, journal and
room state). Authentication **and the generated daily tasks** now use the local
SQLite API instead — tasks are no longer written to Cloud Firestore.

## Why this backend?

- **Zero external account or credentials** for local development. Node 26+
  includes `node:http`, `node:sqlite` and `node:crypto`, so there are no npm
  dependencies to install.
- **Real database**: SQLite with `users`, `emotional_profiles`,
  `refresh_tokens`, `password_reset_tokens` and `daily_tasks` tables, foreign
  keys and WAL.
- **Secure passwords**: scrypt (N=16384, r=8, p=1) with a random 16-byte salt
  per user and constant-time verification. Plaintext passwords are never stored.
- **Real sessions**: short-lived signed access tokens (JWT/HS256) plus opaque,
  hashed, rotating refresh tokens stored in SQLite. Tokens live in platform
  secure storage on the client (Keychain / Keystore / libsecret / web localStorage).
- **Testable**: 8 backend API tests + 14 Dart tests cover the full flow.

## Setup

### 1. Start the auth backend

Requirements: **Node.js 22.5+** (tested on Node 26). Nothing to install.

```bash
node backend/src/server.js
# or: cd backend && npm start
```

It listens on `http://0.0.0.0:3000` and creates:

- `backend/data/saferoom.db` — SQLite database
- `backend/data/jwt_secret` — a generated 48-byte signing secret (0600)

Both are gitignored. Check it with:

```bash
curl http://127.0.0.1:3000/api/health
# {"status":"ok"}
```

### 2. Run the Flutter app

```bash
export PATH=/home/sebtixd/flutter/bin:$PATH
export PUB_CACHE=/home/sebtixd/.pub-cache

flutter pub get
flutter run -d web-server --web-hostname 0.0.0.0 --web-port 8080
```

Open **http://localhost:8080**, register an account, then reload the page —
the session is restored automatically.

For a physical device/emulator, point the app at your machine's LAN address:

```bash
flutter run --dart-define=SAFEROOM_API_BASE_URL=http://192.168.1.20:3000
```

## Credentials / environment variables

Nothing is required for local development. For production, set:

| Variable | Purpose | Default |
|---|---|---|
| `SAFEROOM_JWT_SECRET` | Access-token signing secret (**must** be ≥32 chars) | generated into `backend/data/jwt_secret` |
| `SAFEROOM_DB_PATH` | SQLite file location | `./backend/data/saferoom.db` |
| `PORT` / `HOST` | HTTP listen address | `3000` / `0.0.0.0` |
| `ACCESS_TOKEN_TTL_SECONDS` | Access-token lifetime | `900` |
| `REFRESH_TOKEN_TTL_DAYS` | Refresh-token lifetime | `30` |
| `SAFEROOM_ALLOWED_ORIGINS` | Comma-separated CORS origins | `*` |
| `SAFEROOM_EXPOSE_RESET_TOKENS` | Dev-only: return reset token in API response | `false` |

Client-side build defines:

| `--dart-define` | Purpose |
|---|---|
| `SAFEROOM_API_BASE_URL` | Backend URL (default `http://127.0.0.1:3000`) |
| `SAFEROOM_GEMINI_API_KEY` | Google Gemini key for the AI chat (previously hardcoded) |

See [`backend/.env.example`](backend/.env.example) for a template.

> Password reset: `POST /api/auth/forgot-password` always returns `200` and
> stores a one-hour reset token. With `SAFEROOM_EXPOSE_RESET_TOKENS=true` the
> response includes `resetToken` so you can complete the flow with
> `POST /api/auth/reset-password`. In production, wire that token into an email
> sender instead of exposing it.

## Auth API

| Method | Path | Auth | Description |
|---|---|---|---|
| `POST` | `/api/auth/register` | – | Create account, return user + tokens |
| `POST` | `/api/auth/login` | – | Sign in, return user + tokens |
| `POST` | `/api/auth/refresh` | refresh token in body | Rotate refresh token, return new tokens |
| `POST` | `/api/auth/logout` | refresh token in body | Revoke refresh token |
| `GET` | `/api/auth/me` | Bearer access token | Current user + emotional profile |
| `GET` | `/api/users/:id` | Bearer | Current user by id |
| `PATCH` | `/api/me` | Bearer | Update points |
| `PUT` | `/api/me/emotional-profile` | Bearer | Upsert onboarding profile |
| `POST` | `/api/auth/forgot-password` | – | Create reset token |
| `POST` | `/api/auth/reset-password` | – | Consume token, set new password |
| `GET` | `/api/health` | – | Health check |

## Daily tasks API

Tasks are still *generated* with Gemini from the user's recent journal notes,
but they are stored in the local SQLite `daily_tasks` table through these
endpoints. One row per user per day (`UNIQUE(user_id, date)`), so reloads return
the same list instead of regenerating it.

| Method | Path | Auth | Description |
|---|---|---|---|
| `GET` | `/api/daily-tasks?user_id=:id&date=YYYY-MM-DD` | Bearer | Today's saved tasks (`dailyTask: null` if none) |
| `POST` | `/api/daily-tasks` | Bearer | Create/replace the day's tasks |
| `GET` | `/api/daily-tasks/:id` | Bearer | Fetch one task day by id |
| `PUT` | `/api/daily-tasks/:id` | Bearer | Update task text/completion flags |

Payloads use `{ "date": "YYYY-MM-DD", "tasks": [{ "text": "...", "completed": false }] }`.
`user_id` must match the authenticated user; mismatches return `403`.

Errors use a consistent shape:

```json
{"error": {"code": "invalid_credentials", "message": "Invalid email or password"}}
```

## Room Customization Shop (Library)

- **Entry point**: `HomeScreen` has a **Library** button (top-left). The Library screen (`lib/presentation/screens/library/library_screen.dart`) includes a clear **Customize Room / Open Shop** entry.
- **Catalog**: four pixel-art room backgrounds in `assets/images/backgrounds/` (Default free/equipped, Sunset 100 pts, Night 150 pts, Forest 200 pts), same 1024×1024 pixel-art style as the room.
- **Real flow**: backgrounds track `backgroundId`, `name`, `price`, `owned`, and `equipped`. Buying checks points, prevents double purchase, deducts points via `AuthBloc`/`UserRepository.updateUser`, and persists state. Equipping updates the live Flame room background via `SafeRoomGame.setRoomBackground`.
- **Persistence**: ownership and equipped background are stored per user in SharedPreferences under `room_customization_<userId>` (`RoomCustomizationStorage`), surviving restarts. Placed decor persistence remains in `room_state_decor_<userId>`.

## Notes notebook

The in-game Notes overlay is now a paginated notebook instead of one long note:

- Pages have `id`, `content`, `title` (first line), `createdAt`, `updatedAt`
  and a 1-based `pageNumber`.
- **Save New Page** stores the current writing as a new page; **Save Changes**
  updates the page that is already open without changing its id or creation
  time.
- A page list on the left, plus previous/next controls, lets the player open
  and edit any saved page or start a separate new one. Unsaved text is
  automatically saved when switching pages or closing the notebook.
- Pages are persisted per user in SharedPreferences under
  `notes_pages_<userId>` (legacy `user_notes` content is migrated into page 1
  on first open), so they survive app restarts.
- The paper background is light cream (`#FFF8E8`) with dark brown ink
  (`#2E1B14`) for readable contrast.

See `test/note_pages_test.dart` and `test/notes_overlay_test.dart` for the
save → restart → reopen → edit → new page verification.

## Player sprites

The player now uses real transparent pixel-art PNGs instead of canvas-drawn
rectangles. Eight 50×65 source frames live in `assets/sprites/`
(front/left/right/back × idle/walk), are rendered with nearest-neighbour
filtering, and are scaled up to a 120×156 in-game size. The joystick direction
selects the view:

| Direction value | Movement | Sprite |
|---|---|---|
| `0` | down | front |
| `1` | left | left profile |
| `2` | right | right profile |
| `3` | up | back |

`animationFrame` alternates the idle/walk pair while moving. The palette is
shared across all views and taken from the room's warm browns, cream,
lavender and muted green. Regenerate the frames with:

```bash
python3 tool/generate_player_sprites.py
```

No `pubspec.yaml` change was needed because `assets/sprites/` was already
declared as an asset directory.

## Tests and checks

```bash
# Backend API tests (Node built-in test runner)
cd backend && npm test

# Flutter analysis, unit tests, builds
flutter analyze
flutter test
flutter build web --release
flutter build linux --release

# Live end-to-end smoke test (backend must be running)
dart run tool/verify_auth_api.dart
```
