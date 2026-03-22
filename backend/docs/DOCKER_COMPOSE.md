# Docker Compose (Postgres + API)

## Prerequisites

- [Docker](https://docs.docker.com/get-docker/) and Docker Compose v2 (`docker compose`)

## Quick start

From the **repository root** (where `docker-compose.yml` lives):

```bash
docker compose up --build
```

- **API:** `http://localhost:3000`
- **Health:** `GET http://localhost:3000/api/health`
- **Postgres:** `localhost:5432` (user `grabbit`, database `grabbit_db`, password default `grabbit_dev_password`)

## First run: migrations + seed

The API expects **SQL migrations** (`backend/migrations/*.sql`) for v3 columns (`subcity_id`, `owner_name`, etc.). `sequelize.sync()` on startup **does not** replace running these files.

After the stack is healthy:

```bash
docker compose exec api npm run db:migrate
docker compose exec api npm run db:seed
```

`npm run db:migrate` runs `001` → `004` in order. Idempotent where possible (`IF NOT EXISTS`).

Optional: `npm run db:sync` runs **Sequelize sync only** (no SQL files) — useful for dev; use **after** SQL migrations if you need it.

## Environment overrides

Copy `docker-compose.env.example` to `.env.docker`, edit secrets, then:

```bash
docker compose --env-file .env.docker up --build
```

**Important:** Set strong `JWT_ACCESS_SECRET` and `JWT_REFRESH_SECRET` for anything beyond local dev.

## Volumes

| Volume            | Purpose                          |
|-------------------|----------------------------------|
| `grabbit_pgdata`  | PostgreSQL data (persistent)     |
| `grabbit_uploads` | Uploaded files (`/api/upload`) |

## Stop / remove

```bash
docker compose down
```

Remove DB data as well (destructive):

```bash
docker compose down -v
```

## Flutter app

The mobile app is **not** in this Compose file. Point the app at `http://<your-host>:3000` (e.g. `10.0.2.2:3000` from Android emulator when API runs on the host).
