const User = require('../modules/user/user.model');
const VendorProfile = require('../modules/vendor/vendorProfile.model');
const Deal = require('../modules/deal/deal.model');
const Order = require('../modules/order/order.model');

User.hasOne(VendorProfile, { foreignKey: 'user_id' });
VendorProfile.belongsTo(User, { foreignKey: 'user_id' });

User.hasMany(Deal, { foreignKey: 'vendor_id' });
Deal.belongsTo(User, { foreignKey: 'vendor_id' });

User.hasMany(Order, { foreignKey: 'user_id', as: 'customerOrders' });
Order.belongsTo(User, { foreignKey: 'user_id', as: 'customer' });

Deal.hasMany(Order, { foreignKey: 'deal_id' });
Order.belongsTo(Deal, { foreignKey: 'deal_id', as: 'deal' });
