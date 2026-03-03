const authService = require('./auth.service');

const authController = {
  async register(req, res, next) {
    try {
      const { full_name, email, phone, password, role } = req.body;
      const result = await authService.register({
        full_name,
        email,
        phone,
        password,
        role,
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
      const { email, otp } = req.body;
      const result = await authService.verifyOtp(email, otp);
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
