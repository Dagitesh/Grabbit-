const { body } = require('express-validator');

const registerValidation = [
  body('first_name').trim().notEmpty().withMessage('First name is required').isLength({ max: 100 }),
  body('last_name').trim().notEmpty().withMessage('Last name is required').isLength({ max: 100 }),
  body('email').trim().notEmpty().withMessage('Email is required').isEmail().normalizeEmail(),
  body('phone').trim().notEmpty().withMessage('Phone number is required').isLength({ max: 50 }),
  body('subcity_id').trim().notEmpty().withMessage('Location (subcity) is required').isUUID(),
  body('password')
    .notEmpty()
    .withMessage('Password is required')
    .isLength({ min: 6 })
    .withMessage('Password must be at least 6 characters'),
];

const loginValidation = [
  body('email').trim().notEmpty().withMessage('Email is required').isEmail().normalizeEmail(),
  body('password').notEmpty().withMessage('Password is required'),
];

const verifyOtpValidation = [

  body('phone').trim().notEmpty().withMessage('Phone number is required'),

  body().custom((_, { req }) => {
    const code = req.body.otpCode ?? req.body.otp;
    if (!code || !/^\d{6}$/.test(String(code).trim())) {
      throw new Error('A valid 6-digit OTP is required (otpCode or otp)');
    }
    return true;
  }),
];

const refreshTokenValidation = [body('refreshToken').notEmpty().withMessage('Refresh token is required')];

module.exports = {
  registerValidation,
  loginValidation,
  verifyOtpValidation,
  refreshTokenValidation,
};
