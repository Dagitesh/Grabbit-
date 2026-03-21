const VendorNotification = require('../modules/notification/vendorNotification.model');

async function notifyVendor(vendorUserId, type, title, body, metadata = null) {
  if (!vendorUserId) return;
  await VendorNotification.create({
    vendor_user_id: vendorUserId,
    type,
    title,
    body: body || null,
    metadata,
  });
}

module.exports = { notifyVendor };
