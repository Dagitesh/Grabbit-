const User = require('../modules/user/user.model');
const VendorProfile = require('../modules/vendor/vendorProfile.model');
const VendorBranch = require('../modules/vendor/vendorBranch.model');
const CustomerProfile = require('../modules/customer/customerProfile.model');
const Subcity = require('../modules/subcity/subcity.model');
const Location = require('../modules/location/location.model');
const Category = require('../modules/category/category.model');
const Deal = require('../modules/deal/deal.model');
const Order = require('../modules/order/order.model');
const Payment = require('../modules/payment/payment.model');
const Review = require('../modules/review/review.model');
const VendorNotification = require('../modules/notification/vendorNotification.model');

User.hasOne(VendorProfile, { foreignKey: 'user_id' });
VendorProfile.belongsTo(User, { foreignKey: 'user_id', as: 'User' });

VendorProfile.hasMany(VendorBranch, { foreignKey: 'vendor_profile_id', as: 'VendorBranches' });
VendorBranch.belongsTo(VendorProfile, { foreignKey: 'vendor_profile_id' });
VendorBranch.belongsTo(Subcity, { foreignKey: 'subcity_id' });
Subcity.hasMany(VendorBranch, { foreignKey: 'subcity_id' });

User.hasOne(CustomerProfile, { foreignKey: 'user_id' });
CustomerProfile.belongsTo(User, { foreignKey: 'user_id' });
CustomerProfile.belongsTo(Subcity, { foreignKey: 'subcity_id' });
Subcity.hasMany(CustomerProfile, { foreignKey: 'subcity_id' });

User.hasMany(Location, { foreignKey: 'vendor_id' });
Location.belongsTo(User, { foreignKey: 'vendor_id' });

Category.hasMany(Deal, { foreignKey: 'category_id' });
Deal.belongsTo(Category, { foreignKey: 'category_id', as: 'categoryRef' });
Deal.belongsTo(Subcity, { foreignKey: 'subcity_id', as: 'subcity' });
Subcity.hasMany(Deal, { foreignKey: 'subcity_id' });

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
Review.belongsTo(Deal, { foreignKey: 'deal_id' });
Review.belongsTo(User, { foreignKey: 'user_id', as: 'reviewer' });
Review.belongsTo(User, { foreignKey: 'vendor_id', as: 'vendorUser' });

User.hasMany(VendorNotification, { foreignKey: 'vendor_user_id' });
VendorNotification.belongsTo(User, { foreignKey: 'vendor_user_id' });
