/**
 * Applies SQL files in backend/migrations/ in lexical order (001 → 002 → …).
 * Required for schema v3 columns (subcity_id, owner_name, etc.). `sequelize.sync()` alone
 * does not run these files.
 */
require('dotenv').config();
const fs = require('fs');
const path = require('path');
const { sequelize } = require('../src/config/database');

async function run() {
  const migrationsDir = path.join(__dirname, '..', 'migrations');
  const files = fs
    .readdirSync(migrationsDir)
    .filter((f) => f.endsWith('.sql'))
    .sort();

  if (files.length === 0) {
    console.warn('No .sql files in migrations/');
    process.exit(0);
  }

  await sequelize.authenticate();
  console.log(`Database: applying ${files.length} SQL migration(s)…`);

  for (const file of files) {
    const fullPath = path.join(migrationsDir, file);
    const sql = fs.readFileSync(fullPath, 'utf8');
    console.log(`→ ${file}`);
    await sequelize.query(sql);
  }

  console.log('SQL migrations completed successfully.');
  await sequelize.close();
  process.exit(0);
}

run().catch((err) => {
  console.error('SQL migration failed:', err.message);
  if (err.original) console.error('PG:', err.original.message || err.original);
  if (err.parent && err.parent !== err.original) console.error('Parent:', err.parent.message);
  if (process.env.DEBUG_MIGRATIONS === '1') console.error(err);
  process.exit(1);
});
