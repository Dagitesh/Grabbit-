require('dotenv').config();
const { sequelize } = require('./database');
const User = require('../modules/user/user.model');

async function run() {
  try {
    await sequelize.authenticate();
    await sequelize.sync({ alter: true });
    console.log('Migrations/sync completed.');
    process.exit(0);
  } catch (err) {
    console.error('Migration failed:', err);
    process.exit(1);
  }
}

run();
