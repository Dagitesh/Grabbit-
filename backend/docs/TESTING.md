# Backend testing

## Stack

- **Jest** — test runner and assertions  
- **Supertest** — HTTP assertions against the Express app (no port listen)

## Layout

| Path | Purpose |
|------|--------|
| `tests/setup.js` | `NODE_ENV=test`, fixed JWT secrets for deterministic auth tests |
| `tests/unit/` | Fast tests: pure utils, middleware, mocked `auth.service` |
| `tests/integration/http.test.js` | App wiring: health, validation **422**, **401** on `/api/me`, JSON **404** |

## Commands

```bash
cd backend
npm test              # all tests + coverage report
npm run test:watch    # watch mode
npm run test:unit     # unit only
npm run test:integration
```

## What is covered (core behaviour)

- **`parseDealImages`** — JSON / array / invalid input  
- **`dealModerationReasons`** — preset codes and `getReasonByCode`  
- **`errorHandler`** — `success`, `message`, optional `errors`  
- **`authenticate` / `authorize`** — Bearer JWT and role checks  
- **`auth.service`** — register (subcity, duplicate email, happy path), login (401/403/200), invalid OTP path, invalid refresh token type  
- **HTTP** — `/api/health`, express-validator failures on auth routes, protected route without token, unknown `/api/*` 404  

## What is not covered yet (optional next steps)

These need either **PostgreSQL** (test DB) or **refactors** to inject repositories:

- Full **order** flow (stock, expiry, cancel window)  
- **Deal** listing filters and **admin remove** + `notifyVendor`  
- **Vendor / admin** routes end-to-end  

### Suggested approach for DB integration tests

1. Create a dedicated DB (e.g. `grabbit_test`) or use `TEST_DATABASE_URL`.  
2. Set `RUN_DB_TESTS=true` and run migrations/seed in `beforeAll` (only when that flag is set).  
3. Use **supertest** + real `createApp()` and truncate tables between tests.

Until then, `npm test` stays **fast** and **CI-friendly** without Postgres.

## Refactor note

`src/app.js` exports **`createApp()`** so tests can mount the same routes as production without calling `listen()` or `sequelize.sync()`.
