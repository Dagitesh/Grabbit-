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

// Prefer DATABASE_URL (e.g. Render internal URL) so connection always uses the right host
let sequelize;
if (process.env.DATABASE_URL) {
  sequelize = new Sequelize(process.env.DATABASE_URL, commonOpts);
  try {
    const parsed = new url.URL(process.env.DATABASE_URL);
    // Log minimal connection target for troubleshooting (no secrets)
    console.log(
      `[DB] Using DATABASE_URL host=${parsed.hostname} port=${parsed.port || 5432} ssl=${sslRequired}`
    );
  } catch {
    console.log(`[DB] Using DATABASE_URL (could not parse host). ssl=${sslRequired}`);
  }
} else {
  const host = process.env.DB_HOST || 'localhost';
  const port = process.env.DB_PORT || 5432;
  console.log(`[DB] Using discrete env vars host=${host} port=${port} ssl=${sslRequired}`);
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
