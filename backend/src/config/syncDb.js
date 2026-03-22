/**
 * Sequelize sync only (creates/alters tables from models). Does NOT run migrations/*.sql.
 * Use `npm run db:migrate` for SQL migrations, then seed.
 */
require('dotenv').config();
const { sequelize } = require('./database');
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
    console.log('Sequelize sync completed.');
    await sequelize.close();
    process.exit(0);
  } catch (err) {
    console.error('Sync failed:', err);
    process.exit(1);
  }
}

run();
