const VendorProfile = require('./vendorProfile.model');

const vendorProfileRepository = {
  async findByUserId(userId) {
    return VendorProfile.findOne({ where: { user_id: userId } });
  },

  async create(data) {
    return VendorProfile.create(data);
  },

  async updateByUserId(userId, data) {
    const profile = await VendorProfile.findOne({ where: { user_id: userId } });
    if (!profile) return null;
    await profile.update(data);
    return profile;
  },

  async getOrCreate(userId, defaults = {}) {
    let profile = await this.findByUserId(userId);
    if (!profile) {
      profile = await this.create({
        user_id: userId,
        business_name: defaults.business_name || 'My Business',
        phone: defaults.phone || '',
        ...defaults,
      });
    }
    return profile;
  },
};

module.exports = vendorProfileRepository;
