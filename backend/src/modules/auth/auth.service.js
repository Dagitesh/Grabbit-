const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const { v4: uuidv4 } = require('uuid');
const userRepository = require('../user/user.repository');
const CustomerProfile = require('../customer/customerProfile.model');
const Subcity = require('../subcity/subcity.model');
const {
  ROLES,
  OTP_EXPIRY_MINUTES,
  ACCESS_TOKEN_EXPIRY,
  REFRESH_TOKEN_EXPIRY,
  OTP_LENGTH,
} = require('../../config/constants')
const { normalizePhoneE164, sendRegistrationOtp } = require('../../services/sms.service');


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
  /** Public self-registration: customers only. Vendors are created by admin. */
  async register({ first_name, last_name, email, phone, password, subcity_id }) {
    const subcity = await Subcity.findByPk(subcity_id);
    if (!subcity) {
      const err = new Error('Invalid location (subcity). Choose a valid Addis Ababa subcity.');
      err.statusCode = 400;
      throw err;
    }

    const existing = await userRepository.findByEmail(email);
    if (existing) {
      const err = new Error('Email already registered');
      err.statusCode = 409;
      throw err;
    }


    const normalizedPhone = normalizePhoneE164(phone);
    if (!normalizedPhone || normalizedPhone.length < 10) {
      const err = new Error('A valid phone number is required for SMS verification');
      err.statusCode = 400;
      throw err;
    }
    const existingPhone = await userRepository.findByPhone(normalizedPhone);
    if (existingPhone) {
      const err = new Error('Phone number already registered');
      err.statusCode = 409;
      throw err;
    }


    const fn = String(first_name).trim();
    const ln = String(last_name).trim();
    const full_name = `${fn} ${ln}`.trim();

    const hashedPassword = await bcrypt.hash(password, SALT_ROUNDS);
    const otpCode = generateOtp();
    const otpExpiresAt = getOtpExpiry();

    const user = await userRepository.create({
      id: uuidv4(),
      full_name,
      email: String(email).trim().toLowerCase(),

      phone: normalizedPhone,

      password_hash: hashedPassword,
      role: ROLES.CUSTOMER,
      is_verified: false,
      otp_code: otpCode,
      otp_expires_at: otpExpiresAt,
    });

    await CustomerProfile.create({
      user_id: user.id,
      first_name: fn,
      last_name: ln,
      subcity_id,
    });


    try {
      await sendRegistrationOtp(normalizedPhone, otpCode);
    } catch (smsErr) {
      console.error('[SMS] Failed to send OTP:', smsErr.message || smsErr);
      try {
        await CustomerProfile.destroy({ where: { user_id: user.id } });
        await user.destroy();
      } catch (cleanupErr) {
        console.error('[SMS] Rollback failed:', cleanupErr.message || cleanupErr);
      }
      const err = new Error('Could not send verification SMS. Please try again later.');
      err.statusCode = 503;
      throw err;

    }

    return {
      id: user.id,
      full_name: user.full_name,
      email: user.email,
      role: user.role,
      is_verified: user.is_verified,
      subcity_id,

      message: 'Registration successful. Enter the verification code sent to your phone via SMS.',

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


  async verifyOtp(phone, otpCode) {
    const normalizedPhone = normalizePhoneE164(phone);
    const user = await userRepository.findByPhone(normalizedPhone, { includePassword: false });
    if (!user) {
      const err = new Error('User not found for this phone number');

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


    const fresh = await userRepository.findById(user.id);
    const accessToken = generateAccessToken(fresh.id, fresh.role);
    const refreshToken = generateRefreshToken(fresh.id);

    return {
      message: 'Phone verified successfully. Welcome to Grabbit.',
      user: {
        id: fresh.id,
        full_name: fresh.full_name,
        email: fresh.email,
        phone: fresh.phone,
        role: fresh.role,
        is_verified: fresh.is_verified,
      },
      accessToken,
      refreshToken,
      expiresIn: 900,

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
