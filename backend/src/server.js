require('dotenv').config();
const { sequelize } = require('./config/database');
const { createApp } = require('./app');

const app = createApp();
const PORT = process.env.PORT || 3000;

async function connectWithRetry(maxAttempts = 24, delayMs = 5000) {
  for (let attempt = 1; attempt <= maxAttempts; attempt++) {
    try {
      await sequelize.authenticate();
      return;
    } catch (err) {
      const isRefused =
        err && (err.code === 'ECONNREFUSED' || (err.parent && err.parent.code === 'ECONNREFUSED'));
      console.warn(
        `Database connection attempt ${attempt}/${maxAttempts} failed${isRefused ? ' (connection refused)' : ''}:`,
        err.message || err
      );
      if (attempt === maxAttempts) throw err;
      await new Promise((r) => setTimeout(r, delayMs));
    }
  }
}

async function start() {
  try {
    await connectWithRetry();
    const syncOpts = process.env.DB_SYNC_ALTER === 'true' ? { alter: true } : {};
    await sequelize.sync(syncOpts);
    console.log('Database connected and synced.');
    app.listen(PORT, () => {
      console.log(`Server running on http://localhost:${PORT}`);
    });
  } catch (err) {
    console.error('Unable to start server:', err);
    process.exit(1);
  }
}

start();
