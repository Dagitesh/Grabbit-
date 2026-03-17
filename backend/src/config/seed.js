require('dotenv').config();
const { sequelize } = require('./database');

// Ensure models are registered
require('../modules/category/category.model');
require('../modules/appConfig/appConfig.model');

const Category = require('../modules/category/category.model');
const AppConfig = require('../modules/appConfig/appConfig.model');

async function run() {
  try {
    await sequelize.authenticate();

    // Ensure tables exist (no schema alteration unless explicitly enabled)
    const syncOpts = process.env.DB_SYNC_ALTER === 'true' ? { alter: true } : {};
    await sequelize.sync(syncOpts);

    const defaults = [
      { name: 'Bakery', icon: 'bakery_dining' },
      { name: 'Veggies', icon: 'eco' },
      { name: 'Meals', icon: 'restaurant' },
      { name: 'Dairy', icon: 'egg_outlined' },
      { name: 'Meat', icon: 'dinner_dining' },
    ];

    for (const c of defaults) {
      // eslint-disable-next-line no-await-in-loop
      await Category.findOrCreate({ where: { name: c.name }, defaults: c });
    }

    const existingConfig = await AppConfig.findOne();
    if (!existingConfig) {
      await AppConfig.create({ intro_image_url: null });
    }

    console.log('Seed completed.');
    process.exit(0);
  } catch (err) {
    console.error('Seed failed:', err);
    process.exit(1);
  }
}

run();

