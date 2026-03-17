require('dotenv').config();
const { Sequelize } = require('sequelize');

const commonOpts = {
  dialect: 'postgres',
  logging: process.env.NODE_ENV === 'development' ? console.log : false,
  pool: { max: 5, min: 0, acquire: 30000, idle: 10000 },
};

// Prefer DATABASE_URL (e.g. Render internal URL) so connection always uses the right host
const sequelize = process.env.DATABASE_URL
  ? new Sequelize(process.env.DATABASE_URL, commonOpts)
  : new Sequelize(
      process.env.DB_NAME || 'grabbit_db',
      process.env.DB_USER || 'postgres',
      process.env.DB_PASSWORD || '',
      {
        host: process.env.DB_HOST || 'localhost',
        port: process.env.DB_PORT || 5432,
        ...commonOpts,
      }
    );

module.exports = { sequelize, Sequelize };
