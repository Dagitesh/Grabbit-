require('dotenv').config();
const { Sequelize } = require('sequelize');
const url = require('url');

const sslRequired = String(process.env.DB_SSL || '').toLowerCase() === 'true';

const commonOpts = {
  dialect: 'postgres',
  logging: process.env.NODE_ENV === 'development' ? console.log : false,
  pool: { max: 5, min: 0, acquire: 30000, idle: 10000 },
  ...(sslRequired
    ? { dialectOptions: { ssl: { require: true, rejectUnauthorized: false } } }
    : {}),
};

/** Empty/whitespace DATABASE_URL must not be passed to Sequelize (crashes parsing protocol). */
function getValidDatabaseUrl() {
  const raw = process.env.DATABASE_URL;
  if (raw == null || typeof raw !== 'string') return '';
  const trimmed = raw.trim();
  if (!trimmed) return '';
  if (!/^postgres(ql)?:\/\//i.test(trimmed)) return '';
  try {
    const parsed = new url.URL(trimmed);
    if (!parsed.hostname) return '';
    return trimmed;
  } catch {
    return '';
  }
}

// Prefer DATABASE_URL (e.g. Render / Railway) when it is a real postgres:// URL
let sequelize;
const databaseUrl = getValidDatabaseUrl();
if (databaseUrl) {
  sequelize = new Sequelize(databaseUrl, commonOpts);
  try {
    const parsed = new url.URL(databaseUrl);
    if (process.env.NODE_ENV !== 'test') {
      console.log(
        `[DB] Using DATABASE_URL host=${parsed.hostname} port=${parsed.port || 5432} ssl=${sslRequired}`
      );
    }
  } catch {
    if (process.env.NODE_ENV !== 'test') {
      console.log(`[DB] Using DATABASE_URL (could not parse host). ssl=${sslRequired}`);
    }
  }
} else {
  if (process.env.DATABASE_URL != null && String(process.env.DATABASE_URL).trim() !== '') {
    console.warn(
      '[DB] DATABASE_URL is set but invalid or not postgres:// — falling back to DB_HOST/DB_* env vars'
    );
  }
  const host = process.env.DB_HOST || 'localhost';
  const port = Number(process.env.DB_PORT) || 5432;
  if (process.env.NODE_ENV !== 'test') {
    console.log(`[DB] Using discrete env vars host=${host} port=${port} ssl=${sslRequired}`);
  }
  sequelize = new Sequelize(
    process.env.DB_NAME || 'grabbit_db',
    process.env.DB_USER || 'postgres',
    process.env.DB_PASSWORD || '',
    {
      host,
      port,
      ...commonOpts,
    }
  );
}

module.exports = { sequelize, Sequelize };
