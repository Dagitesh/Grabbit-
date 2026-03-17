const express = require('express');
const { authenticate, authorize } = require('../../middleware/auth');
const { ROLES } = require('../../config/constants');
const Category = require('../category/category.model');
const AppConfig = require('../appConfig/appConfig.model');
const VendorProfile = require('../vendor/vendorProfile.model');
const User = require('../user/user.model');
const Deal = require('../deal/deal.model');
const Order = require('../order/order.model');

const router = express.Router();

// ---- Public: categories list (for Explore page) ----
router.get('/categories', async (req, res, next) => {
  try {
    const categories = await Category.findAll({
      order: [['name', 'ASC']],
      attributes: ['id', 'name', 'icon', 'created_at'],
    });
    res.json(categories.map((c) => c.toJSON()));
  } catch (err) {
    next(err);
  }
});

// ---- Public: app config (intro image) ----
router.get('/app-config', async (req, res, next) => {
  try {
    const row = await AppConfig.findOne({ order: [['updated_at', 'DESC']] });
    res.json(row ? row.toJSON() : { intro_image_url: null, updated_at: null });
  } catch (err) {
    next(err);
  }
});

// ---- Admin-only below ----
router.use(authenticate, authorize(ROLES.ADMIN));

// ---- Categories CRUD ----
router.post('/categories', async (req, res, next) => {
  try {
    const { name, icon } = req.body;
    if (!name || !name.trim()) {
      const err = new Error('Category name is required');
      err.statusCode = 400;
      return next(err);
    }
    const category = await Category.create({
      name: String(name).trim(),
      icon: (icon && String(icon).trim()) || 'category',
    });
    res.status(201).json(category.toJSON());
  } catch (err) {
    next(err);
  }
});

router.put('/categories/:id', async (req, res, next) => {
  try {
    const category = await Category.findByPk(req.params.id);
    if (!category) {
      const err = new Error('Category not found');
      err.statusCode = 404;
      return next(err);
    }
    const { name, icon } = req.body;
    if (name !== undefined) category.name = String(name).trim();
    if (icon !== undefined) category.icon = String(icon).trim();
    await category.save();
    res.json(category.toJSON());
  } catch (err) {
    next(err);
  }
});

router.delete('/categories/:id', async (req, res, next) => {
  try {
    const category = await Category.findByPk(req.params.id);
    if (!category) {
      const err = new Error('Category not found');
      err.statusCode = 404;
      return next(err);
    }
    await category.destroy();
    res.status(204).send();
  } catch (err) {
    next(err);
  }
});

// ---- Vendor approval ----
router.get('/vendors/pending', async (req, res, next) => {
  try {
    const profiles = await VendorProfile.findAll({
      where: { is_approved: false },
      include: [{ model: User, as: 'User', attributes: ['id', 'full_name', 'email', 'phone', 'created_at'] }],
      order: [['created_at', 'DESC']],
    });
    const list = profiles.map((p) => {
      const j = p.toJSON();
      j.user = j.User;
      delete j.User;
      return j;
    });
    res.json(list);
  } catch (err) {
    next(err);
  }
});

router.patch('/vendors/:userId/approve', async (req, res, next) => {
  try {
    const profile = await VendorProfile.findOne({ where: { user_id: req.params.userId } });
    if (!profile) {
      const err = new Error('Vendor profile not found');
      err.statusCode = 404;
      return next(err);
    }
    await profile.update({ is_approved: true });
    res.json(profile.toJSON());
  } catch (err) {
    next(err);
  }
});

router.patch('/vendors/:userId/reject', async (req, res, next) => {
  try {
    const profile = await VendorProfile.findOne({ where: { user_id: req.params.userId } });
    if (!profile) {
      const err = new Error('Vendor profile not found');
      err.statusCode = 404;
      return next(err);
    }
    await profile.update({ is_approved: false });
    res.json(profile.toJSON());
  } catch (err) {
    next(err);
  }
});

// ---- App config (intro image) ----
router.put('/app-config', async (req, res, next) => {
  try {
    let row = await AppConfig.findOne({ order: [['updated_at', 'DESC']] });
    if (!row) {
      row = await AppConfig.create({ intro_image_url: req.body.intro_image_url || null });
    } else {
      await row.update({ intro_image_url: req.body.intro_image_url ?? row.intro_image_url });
    }
    res.json(row.toJSON());
  } catch (err) {
    next(err);
  }
});

// ---- Admin dashboard stats ----
router.get('/dashboard', async (req, res, next) => {
  try {
    const [totalUsers, totalVendors, pendingVendors, totalDeals, totalOrders, completedOrders] = await Promise.all([
      User.count(),
      VendorProfile.count(),
      VendorProfile.count({ where: { is_approved: false } }),
      Deal.count(),
      Order.count(),
      Order.count({ where: { status: 'Completed' } }),
    ]);
    res.json({
      totalUsers,
      totalVendors,
      pendingVendors,
      totalDeals,
      totalOrders,
      completedOrders,
      revenue: null, // can be computed from Payment when needed
    });
  } catch (err) {
    next(err);
  }
});

module.exports = router;
