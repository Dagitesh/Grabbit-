const express = require('express');
const path = require('path');
const fs = require('fs');
const multer = require('multer');
const { authenticate, authorize } = require('../../middleware/auth');
const { ROLES } = require('../../config/constants');
const Category = require('../category/category.model');
const AppConfig = require('../appConfig/appConfig.model');
const VendorProfile = require('../vendor/vendorProfile.model');
const User = require('../user/user.model');
const Deal = require('../deal/deal.model');
const Order = require('../order/order.model');
const VendorBranch = require('../vendor/vendorBranch.model');
const { registerVendorByAdmin } = require('./adminVendor.service');

const router = express.Router();

const uploadsDir = path.join(__dirname, '..', '..', '..', 'uploads');
if (!fs.existsSync(uploadsDir)) {
  fs.mkdirSync(uploadsDir, { recursive: true });
}

const pdfStorage = multer.diskStorage({
  destination: (_req, _file, cb) => cb(null, uploadsDir),
  filename: (_req, file, cb) =>
    cb(null, `cert-${Date.now()}-${Math.random().toString(36).slice(2)}${path.extname(file.originalname) || '.pdf'}`),
});

const pdfUpload = multer({
  storage: pdfStorage,
  limits: { fileSize: 15 * 1024 * 1024 },
  fileFilter: (_req, file, cb) => {
    if (file.mimetype === 'application/pdf') return cb(null, true);
    cb(new Error('Certificate must be a PDF file'));
  },
});

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

// ---- Register vendor (company onboarding; PDF certificate) ----
router.post('/vendors/register', pdfUpload.single('certificate'), async (req, res, next) => {
  try {
    if (!req.file) {
      const err = new Error('certificate PDF file is required (field name: certificate)');
      err.statusCode = 400;
      return next(err);
    }
    const baseUrl = process.env.BASE_URL || `http://localhost:${process.env.PORT || 3000}`;
    const certificatePdfUrl = `${baseUrl.replace(/\/$/, '')}/uploads/${req.file.filename}`;

    let branches = [];
    try {
      branches = typeof req.body.branches === 'string' ? JSON.parse(req.body.branches || '[]') : req.body.branches || [];
    } catch {
      branches = [];
    }
    if (!Array.isArray(branches)) branches = [];

    const result = await registerVendorByAdmin(
      {
        owner_email: req.body.owner_email,
        initial_password: req.body.initial_password,
        business_name: req.body.business_name,
        owner_name: req.body.owner_name,
        tin: req.body.tin,
        business_type: req.body.business_type,
        contact_phone: req.body.contact_phone,
        address: req.body.address,
        branch_count: req.body.branch_count,
        branches,
      },
      certificatePdfUrl
    );

    const profileWithBranches = await VendorProfile.findByPk(result.profile.id, {
      include: [{ model: VendorBranch, as: 'VendorBranches' }],
    });

    res.status(201).json({
      ...result,
      profile: profileWithBranches ? profileWithBranches.toJSON() : result.profile,
      message: 'Vendor registered. Share login credentials securely with the vendor.',
    });
  } catch (err) {
    next(err);
  }
});

// Legacy: self-serve vendor queue removed — vendors are created via POST /vendors/register
router.get('/vendors/pending', async (req, res) => {
  res.json([]);
});

router.patch('/vendors/:userId/approve', async (req, res) => {
  res.status(410).json({
    success: false,
    message: 'Vendor onboarding uses POST /api/admin/vendors/register. No separate approval step.',
  });
});

router.patch('/vendors/:userId/reject', async (req, res) => {
  res.status(410).json({
    success: false,
    message: 'Vendor onboarding uses POST /api/admin/vendors/register.',
  });
});

// ---- List vendors (for admin UI) ----
router.get('/vendors', async (req, res, next) => {
  try {
    const profiles = await VendorProfile.findAll({
      include: [
        { model: User, as: 'User', attributes: ['id', 'full_name', 'email', 'phone', 'created_at'] },
        { model: VendorBranch, as: 'VendorBranches' },
      ],
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
    const [totalUsers, totalVendors, totalDeals, totalOrders, completedOrders] = await Promise.all([
      User.count({ where: { role: ROLES.CUSTOMER } }),
      VendorProfile.count(),
      Deal.count(),
      Order.count(),
      Order.count({ where: { status: 'Completed' } }),
    ]);
    res.json({
      totalUsers,
      totalVendors,
      totalDeals,
      totalOrders,
      completedOrders,
      revenue: null,
    });
  } catch (err) {
    next(err);
  }
});

module.exports = router;
