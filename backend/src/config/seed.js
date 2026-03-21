require('dotenv').config();
const { sequelize } = require('./database');

require('../modules/subcity/subcity.model');
require('../modules/category/category.model');
require('../modules/appConfig/appConfig.model');

const Subcity = require('../modules/subcity/subcity.model');
const Category = require('../modules/category/category.model');
const AppConfig = require('../modules/appConfig/appConfig.model');

const ADDIS_SUBCITIES = [
  { name: 'Addis Ketema', sort_order: 1 },
  { name: 'Akaky Kaliti', sort_order: 2 },
  { name: 'Arada', sort_order: 3 },
  { name: 'Bole', sort_order: 4 },
  { name: 'Gulele', sort_order: 5 },
  { name: 'Kirkos', sort_order: 6 },
  { name: 'Kolfe Keranio', sort_order: 7 },
  { name: 'Lideta', sort_order: 8 },
  { name: 'Nifas Silk-Lafto', sort_order: 9 },
  { name: 'Yeka', sort_order: 10 },
  { name: 'Lemi Kura', sort_order: 11 },
  { name: 'Other', sort_order: 99 },
];

/** Predefined deal categories (Meat, Vegan, Pastries, Drinks, Urgent) */
const DEFAULT_CATEGORIES = [
  { name: 'Meat', icon: 'dinner_dining' },
  { name: 'Vegan', icon: 'eco' },
  { name: 'Pastries', icon: 'bakery_dining' },
  { name: 'Drinks', icon: 'local_drink' },
  { name: 'Urgent', icon: 'schedule' },
];

async function run() {
  try {
    await sequelize.authenticate();

    const syncOpts = process.env.DB_SYNC_ALTER === 'true' ? { alter: true } : {};
    await sequelize.sync(syncOpts);

    for (const s of ADDIS_SUBCITIES) {
      // eslint-disable-next-line no-await-in-loop
      await Subcity.findOrCreate({
        where: { name: s.name },
        defaults: { sort_order: s.sort_order },
      });
    }

    for (const c of DEFAULT_CATEGORIES) {
      // eslint-disable-next-line no-await-in-loop
      await Category.findOrCreate({ where: { name: c.name }, defaults: c });
    }

    const existingConfig = await AppConfig.findOne();
    if (!existingConfig) {
      await AppConfig.create({ intro_image_url: null });
    }

    console.log('Seed completed (subcities + categories).');
    process.exit(0);
  } catch (err) {
    console.error('Seed failed:', err);
    process.exit(1);
  }
}

run();
