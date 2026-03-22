const authService = require('./auth.service');

const authController = {
  async register(req, res, next) {
    try {
      const { first_name, last_name, email, phone, password, subcity_id } = req.body;
      const result = await authService.register({
        first_name,
        last_name,
        email,
        phone,
        password,
        subcity_id,
      });
      res.status(201).json(result);
    } catch (err) {
      next(err);
    }
  },

  async login(req, res, next) {
    try {
      const { email, password } = req.body;
      const result = await authService.login(email, password);
      res.json(result);
    } catch (err) {
      next(err);
    }
  },

  async verifyOtp(req, res, next) {
    try {
<<<<<<< HEAD
      const { phone } = req.body;
      const otpCode = req.body.otpCode ?? req.body.otp;
      const result = await authService.verifyOtp(phone, otpCode);
=======
      const { email } = req.body;
      const otpCode = req.body.otpCode ?? req.body.otp;
      const result = await authService.verifyOtp(email, otpCode);
>>>>>>> b4445c22d74b08dfbe6b25d0ba95eee6eaf515aa
      res.json(result);
    } catch (err) {
      next(err);
    }
  },

  async refreshTokens(req, res, next) {
    try {
      const { refreshToken } = req.body;
      const result = await authService.refreshTokens(refreshToken);
      res.json(result);
    } catch (err) {
      next(err);
    }
  },
};

module.exports = authController;
