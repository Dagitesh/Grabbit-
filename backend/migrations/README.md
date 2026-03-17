# Backend migrations

## SQL migration (schema v2)

Run the PostgreSQL migration **once** after backing up your database:

```bash
# From repo root; set DB connection as needed
psql -U postgres -d grabbit_db -f backend/migrations/001_grabbit_schema_v2.sql
```

Or set `PGPASSWORD` and connection params and run from your SQL client.

After that, start the backend as usual; `npm run db:migrate` (Sequelize sync) will align with the migrated schema.

## Sequelize sync

`npm run db:migrate` runs Sequelize `sync({ alter: true })` and does not run the SQL file above. Run the SQL migration first for constraints and new tables, then use the app as normal.
