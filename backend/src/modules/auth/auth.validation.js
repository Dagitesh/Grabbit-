const { body } = require('express-validator');
const { ROLES } = require('../../config/constants');

const registerValidation = [
  body('full_name').trim().notEmpty().withMessage('Full name is required').isLength({ max: 255 }),
  body('email').trim().notEmpty().withMessage('Email is required').isEmail().normalizeEmail(),
  body('password')
    .notEmpty()
    .withMessage('Password is required')
    .isLength({ min: 6 })
    .withMessage('Password must be at least 6 characters'),
  body('phone').optional().trim().isLength({ max: 50 }),
  body('role')
    .optional()
    .isIn([ROLES.CUSTOMER, ROLES.VENDOR])
    .withMessage('Role must be CUSTOMER or VENDOR'),
];

const loginValidation = [
  body('email').trim().notEmpty().withMessage('Email is required').isEmail().normalizeEmail(),
  body('password').notEmpty().withMessage('Password is required'),
];

const verifyOtpValidation = [
  body('email').trim().notEmpty().withMessage('Email is required').isEmail().normalizeEmail(),
  body('otp')
    .notEmpty()
    .withMessage('OTP is required')
    .isLength({ min: 6, max: 6 })
    .withMessage('OTP must be 6 digits')
    .isNumeric()
    .withMessage('OTP must be numeric'),
];

const refreshTokenValidation = [body('refreshToken').notEmpty().withMessage('Refresh token is required')];

module.exports = {
  registerValidation,
  loginValidation,
  verifyOtpValidation,
  refreshTokenValidation,
};
