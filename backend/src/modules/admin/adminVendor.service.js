const bcrypt = require('bcryptjs');
const { v4: uuidv4 } = require('uuid');
const User = require('../user/user.model');
const VendorProfile = require('../vendor/vendorProfile.model');
const VendorBranch = require('../vendor/vendorBranch.model');
const { ROLES } = require('../../config/constants');

const SALT_ROUNDS = 12;

/**
 * Admin-only: create vendor user + profile + optional branch rows.
 * @param {object} payload - from multipart fields
 * @param {string} certificatePdfUrl - public URL to uploaded PDF
 */
async function registerVendorByAdmin(payload, certificatePdfUrl) {
  const {
    owner_email,
    initial_password,
    business_name,
    owner_name,
    tin,
    business_type,
    contact_phone,
    address,
    branch_count,
    branches,
  } = payload;

  if (!owner_email || !initial_password || !business_name) {
    const err = new Error('owner_email, initial_password, and business_name are required');
    err.statusCode = 400;
    throw err;
  }
  if (!certificatePdfUrl) {
    const err = new Error('Certificate PDF is required');
    err.statusCode = 400;
    throw err;
  }

  const existing = await User.findOne({ where: { email: String(owner_email).trim().toLowerCase() } });
  if (existing) {
    const err = new Error('Email already registered');
    err.statusCode = 409;
    throw err;
  }

  const hashedPassword = await bcrypt.hash(String(initial_password), SALT_ROUNDS);
  const displayName = String(owner_name || business_name).trim();

  const user = await User.create({
    id: uuidv4(),
    full_name: displayName,
    email: String(owner_email).trim().toLowerCase(),
    phone: contact_phone ? String(contact_phone).trim() : null,
    password_hash: hashedPassword,
    role: ROLES.VENDOR,
    is_verified: true,
    otp_code: null,
    otp_expires_at: null,
  });

  const profile = await VendorProfile.create({
    user_id: user.id,
    business_name: String(business_name).trim(),
    owner_name: owner_name ? String(owner_name).trim() : null,
    tin: tin ? String(tin).trim() : null,
    business_type: business_type ? String(business_type).trim() : null,
    phone: contact_phone ? String(contact_phone).trim() : '',
    address: address ? String(address).trim() : null,
    location: address ? String(address).trim() : null,
    branch_count: branch_count != null ? Math.max(1, parseInt(branch_count, 10) || 1) : (Array.isArray(branches) ? branches.length : 1),
    certificate_pdf_url: certificatePdfUrl,
  });

  if (Array.isArray(branches) && branches.length > 0) {
    for (let i = 0; i < branches.length; i += 1) {
      const b = branches[i];
      if (b && b.subcity_id) {
        // eslint-disable-next-line no-await-in-loop
        await VendorBranch.create({
          vendor_profile_id: profile.id,
          subcity_id: b.subcity_id,
          address_detail: b.address_detail ? String(b.address_detail) : null,
          sort_order: i,
        });
      }
    }
  }

  return {
    user: {
      id: user.id,
      email: user.email,
      role: user.role,
      full_name: user.full_name,
    },
    profile: profile.toJSON(),
  };
}

module.exports = { registerVendorByAdmin };
