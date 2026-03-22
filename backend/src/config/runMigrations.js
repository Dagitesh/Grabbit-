require('dotenv').config();
const { sequelize } = require('./database');
// Load all models so sequelize.sync creates/aligns tables
require('../modules/user/user.model');
require('../modules/subcity/subcity.model');
require('../modules/vendor/vendorProfile.model');
require('../modules/vendor/vendorBranch.model');
require('../modules/notification/vendorNotification.model');
require('../modules/customer/customerProfile.model');
require('../modules/location/location.model');
require('../modules/category/category.model');
require('../modules/deal/deal.model');
require('../modules/order/order.model');
require('../modules/payment/payment.model');
require('../modules/review/review.model');
require('../modules/appConfig/appConfig.model');
require('./associations');

async function run() {
  try {
    await sequelize.authenticate();
    const syncOpts = process.env.DB_SYNC_ALTER === 'true' ? { alter: true } : {};
    await sequelize.sync(syncOpts);
    console.log('Migrations/sync completed.');
    process.exit(0);
  } catch (err) {
    console.error('Migration failed:', err);
    process.exit(1);
  }
}

run();
