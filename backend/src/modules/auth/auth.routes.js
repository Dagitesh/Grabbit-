const express = require('express');
const authController = require('./auth.controller');
const { validate } = require('../../middleware/validate');
const {
  registerValidation,
  loginValidation,
  verifyOtpValidation,
  refreshTokenValidation,
} = require('./auth.validation');

const router = express.Router();

router.post('/register', validate(registerValidation), authController.register);
router.post('/login', validate(loginValidation), authController.login);
router.post('/verify-otp', validate(verifyOtpValidation), authController.verifyOtp);
router.post('/refresh-token', validate(refreshTokenValidation), authController.refreshTokens);

module.exports = router;
