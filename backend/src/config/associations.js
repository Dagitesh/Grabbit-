const User = require('../modules/user/user.model');
const VendorProfile = require('../modules/vendor/vendorProfile.model');
const CustomerProfile = require('../modules/customer/customerProfile.model');
const Location = require('../modules/location/location.model');
const Category = require('../modules/category/category.model');
const Deal = require('../modules/deal/deal.model');
const Order = require('../modules/order/order.model');
const Payment = require('../modules/payment/payment.model');
const Review = require('../modules/review/review.model');

User.hasOne(VendorProfile, { foreignKey: 'user_id' });
VendorProfile.belongsTo(User, { foreignKey: 'user_id' });

User.hasOne(CustomerProfile, { foreignKey: 'user_id' });
CustomerProfile.belongsTo(User, { foreignKey: 'user_id' });

User.hasMany(Location, { foreignKey: 'vendor_id' });
Location.belongsTo(User, { foreignKey: 'vendor_id' });

Category.hasMany(Deal, { foreignKey: 'category_id' });
Deal.belongsTo(Category, { foreignKey: 'category_id', as: 'categoryRef' });
User.hasMany(Deal, { foreignKey: 'vendor_id' });
Deal.belongsTo(User, { foreignKey: 'vendor_id' });
Deal.belongsTo(Location, { foreignKey: 'location_id', as: 'branch' });
Location.hasMany(Deal, { foreignKey: 'location_id', as: 'deals' });

User.hasMany(Order, { foreignKey: 'user_id', as: 'customerOrders' });
Order.belongsTo(User, { foreignKey: 'user_id', as: 'customer' });

Deal.hasMany(Order, { foreignKey: 'deal_id' });
Order.belongsTo(Deal, { foreignKey: 'deal_id', as: 'deal' });

Order.hasOne(Payment, { foreignKey: 'order_id' });
Payment.belongsTo(Order, { foreignKey: 'order_id' });

Order.hasOne(Review, { foreignKey: 'order_id' });
Review.belongsTo(Order, { foreignKey: 'order_id' });
