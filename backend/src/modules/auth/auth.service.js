const bcrypt = require('bcrypt');
const jwt = require('jsonwebtoken');
const { v4: uuidv4 } = require('uuid');
const userRepository = require('../user/user.repository');
const VendorProfile = require('../vendor/vendorProfile.model');
const {
  ROLES,
  OTP_EXPIRY_MINUTES,
  ACCESS_TOKEN_EXPIRY,
  REFRESH_TOKEN_EXPIRY,
  OTP_LENGTH,
} = require('../../config/constants');

const SALT_ROUNDS = 12;

function generateOtp() {
  const digits = '0123456789';
  let otp = '';
  for (let i = 0; i < OTP_LENGTH; i++) {
    otp += digits[Math.floor(Math.random() * 10)];
  }
  return otp;
}

function getOtpExpiry() {
  const date = new Date();
  date.setMinutes(date.getMinutes() + OTP_EXPIRY_MINUTES);
  return date;
}

function generateAccessToken(userId, role) {
  return jwt.sign(
    { sub: userId, role },
    process.env.JWT_ACCESS_SECRET,
    { expiresIn: ACCESS_TOKEN_EXPIRY }
  );
}

function generateRefreshToken(userId) {
  return jwt.sign(
    { sub: userId, type: 'refresh' },
    process.env.JWT_REFRESH_SECRET,
    { expiresIn: REFRESH_TOKEN_EXPIRY }
  );
}

const authService = {
  async register({ full_name, email, phone, password, role }) {
    const effectiveRole = role || ROLES.CUSTOMER;
    if (effectiveRole === ROLES.ADMIN) {
      const err = new Error('Admin role cannot be self-registered');
      err.statusCode = 403;
      throw err;
    }
    const existing = await userRepository.findByEmail(email);
    if (existing) {
      const err = new Error('Email already registered');
      err.statusCode = 409;
      throw err;
    }

    const hashedPassword = await bcrypt.hash(password, SALT_ROUNDS);
    const otpCode = generateOtp();
    const otpExpiresAt = getOtpExpiry();

    const user = await userRepository.create({
      id: uuidv4(),
      full_name,
      email,
      phone: phone || null,
      password_hash: hashedPassword,
      role: effectiveRole,
      is_verified: false,
      otp_code: otpCode,
      otp_expires_at: otpExpiresAt,
    });

    // When role is VENDOR, create VendorProfile with pending approval
    if (user.role === ROLES.VENDOR) {
      await VendorProfile.create({
        user_id: user.id,
        business_name: 'My Business',
        phone: phone || '',
        is_approved: false,
      });
    }

    // In production: send OTP via email/SMS mock service
    if (process.env.MOCK_OTP_LOG === 'true') {
      console.log(`[MOCK OTP] Email ${email} -> OTP: ${otpCode} (expires in ${OTP_EXPIRY_MINUTES} min)`);
    }

    return {
      id: user.id,
      full_name: user.full_name,
      email: user.email,
      role: user.role,
      is_verified: user.is_verified,
      message: 'Registration successful. Please verify your email with the OTP sent.',
    };
  },

  async login(email, password) {
    const user = await userRepository.findByEmail(email, { includePassword: true });
    if (!user) {
      const err = new Error('Invalid email or password');
      err.statusCode = 401;
      throw err;
    }

    const match = await bcrypt.compare(password, user.password_hash);
    if (!match) {
      const err = new Error('Invalid email or password');
      err.statusCode = 401;
      throw err;
    }

    if (!user.is_verified) {
      const err = new Error('Account not verified. Please verify with OTP first.');
      err.statusCode = 403;
      throw err;
    }

    const accessToken = generateAccessToken(user.id, user.role);
    const refreshToken = generateRefreshToken(user.id);

    return {
      user: {
        id: user.id,
        full_name: user.full_name,
        email: user.email,
        phone: user.phone,
        role: user.role,
        is_verified: user.is_verified,
      },
      accessToken,
      refreshToken,
      expiresIn: 900, // 15 min in seconds
    };
  },

  async verifyOtp(email, otpCode) {
    const user = await userRepository.findByEmail(email, { includePassword: false });
    if (!user) {
      const err = new Error('User not found');
      err.statusCode = 404;
      throw err;
    }

    const userWithOtp = await userRepository.findById(user.id, { includePassword: true });
    if (!userWithOtp.otp_code || !userWithOtp.otp_expires_at) {
      const err = new Error('No OTP found. Please request a new one.');
      err.statusCode = 400;
      throw err;
    }

    if (new Date() > new Date(userWithOtp.otp_expires_at)) {
      const err = new Error('OTP has expired. Please register again or request a new OTP.');
      err.statusCode = 400;
      throw err;
    }

    if (userWithOtp.otp_code !== String(otpCode).trim()) {
      const err = new Error('Invalid OTP');
      err.statusCode = 400;
      throw err;
    }

    await userRepository.clearOtpAndVerify(user.id);

    return {
      message: 'Email verified successfully. You can now log in.',
    };
  },

  async refreshTokens(refreshToken) {
    const decoded = jwt.verify(refreshToken, process.env.JWT_REFRESH_SECRET);
    if (decoded.type !== 'refresh') {
      const err = new Error('Invalid refresh token');
      err.statusCode = 401;
      throw err;
    }

    const user = await userRepository.findById(decoded.sub);
    if (!user) {
      const err = new Error('User not found');
      err.statusCode = 401;
      throw err;
    }

    const accessToken = generateAccessToken(user.id, user.role);
    const newRefreshToken = generateRefreshToken(user.id);

    return {
      accessToken,
      refreshToken: newRefreshToken,
      expiresIn: 900,
    };
  },
};

module.exports = authService;
