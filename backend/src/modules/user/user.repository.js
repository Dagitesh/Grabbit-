const User = require('./user.model');

const userRepository = {
  async create(data) {
    return User.create(data);
  },

  async findByEmail(email, options = {}) {
    if (options.includePassword) {
      return User.scope('withPassword').findOne({ where: { email } });
    }
    return User.findOne({ where: { email } });
  },

  async findById(id, options = {}) {
    if (options.includePassword) {
      return User.scope('withPassword').findByPk(id);
    }
    return User.findByPk(id);
  },

  async updateById(id, data) {
    const user = await User.findByPk(id);
    if (!user) return null;
    await user.update(data);
    return user;
  },

  async setOtp(userId, otpCode, otpExpiresAt) {
    return this.updateById(userId, {
      otp_code: otpCode,
      otp_expires_at: otpExpiresAt,
    });
  },

  async clearOtpAndVerify(userId) {
    return this.updateById(userId, {
      otp_code: null,
      otp_expires_at: null,
      is_verified: true,
    });
  },
};

module.exports = userRepository;
