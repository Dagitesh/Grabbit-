const express = require('express');
const path = require('path');
const fs = require('fs');
const multer = require('multer');
const { Op } = require('sequelize');
const { authenticate, authorize } = require('../../middleware/auth');
const { ROLES } = require('../../config/constants');
const Category = require('../category/category.model');
const AppConfig = require('../appConfig/appConfig.model');
const VendorProfile = require('../vendor/vendorProfile.model');
const User = require('../user/user.model');
const Deal = require('../deal/deal.model');
const Order = require('../order/order.model');
const VendorBranch = require('../vendor/vendorBranch.model');
const Subcity = require('../subcity/subcity.model');
const { registerVendorByAdmin } = require('./adminVendor.service');
const { parseDealImages } = require('../../utils/parseDealImages');
const { DEAL_MODERATION_REASONS, getReasonByCode } = require('../../config/dealModerationReasons');
const { notifyVendor } = require('../../services/vendorNotify.service');

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

// ---- Deal moderation (preset reasons + remove + notify vendor) ----
router.get('/deal-moderation-reasons', (req, res) => {
  res.json(DEAL_MODERATION_REASONS);
});

router.get('/deals', async (req, res, next) => {
  try {
    const page = Math.max(1, parseInt(req.query.page, 10) || 1);
    const limit = Math.min(50, Math.max(1, parseInt(req.query.limit, 10) || 20));
    const offset = (page - 1) * limit;
    const includeRemoved = req.query.includeRemoved === 'true';
    const search = (req.query.search || '').trim();
    const where = includeRemoved ? {} : { removed_by_admin: false };
    if (search) {
      where[Op.or] = [
        { title: { [Op.iLike]: `%${search}%` } },
        { description: { [Op.iLike]: `%${search}%` } },
      ];
    }
    const { count, rows } = await Deal.findAndCountAll({
      where,
      limit,
      offset,
      order: [['created_at', 'DESC']],
      include: [
        { model: Category, as: 'categoryRef', attributes: ['id', 'name'], required: false },
        { model: Subcity, as: 'subcity', attributes: ['id', 'name'], required: false },
      ],
    });
    const vendorIds = [...new Set(rows.map((d) => d.vendor_id))];
    const vendors =
      vendorIds.length > 0
        ? await User.findAll({
            where: { id: vendorIds },
            attributes: ['id', 'full_name', 'email', 'phone'],
          })
        : [];
    const vendorMap = Object.fromEntries(vendors.map((u) => [u.id, u.toJSON()]));
    const list = rows.map((d) => {
      const j = d.toJSON();
      j.images = parseDealImages(j.images);
      j.vendor = vendorMap[j.vendor_id] || null;
      j.category_name = j.categoryRef?.name ?? j.category;
      j.subcity_name = j.subcity?.name ?? null;
      delete j.categoryRef;
      delete j.subcity;
      j.original_price = Number(j.original_price);
      j.discounted_price = Number(j.discount_price ?? j.discounted_price);
      return j;
    });
    const totalPages = Math.ceil(count / limit) || 1;
    res.json({ deals: list, total: count, page, limit, totalPages });
  } catch (err) {
    next(err);
  }
});

router.post('/deals/:id/remove', async (req, res, next) => {
  try {
    const reason = getReasonByCode(req.body?.reason_code);
    if (!reason) {
      const err = new Error(
        'Invalid or missing reason_code. Use GET /api/admin/deal-moderation-reasons for allowed values.'
      );
      err.statusCode = 400;
      return next(err);
    }
    const deal = await Deal.findByPk(req.params.id);
    if (!deal) {
      const err = new Error('Deal not found');
      err.statusCode = 404;
      return next(err);
    }
    if (deal.removed_by_admin) {
      const err = new Error('Deal was already removed');
      err.statusCode = 400;
      return next(err);
    }
    await deal.update({
      removed_by_admin: true,
      is_active: false,
      admin_removal_reason_code: reason.code,
      admin_removal_reason_label: reason.label,
      admin_removed_at: new Date(),
    });
    await notifyVendor(
      deal.vendor_id,
      'deal_removed',
      'Deal removed by moderator',
      `Your deal "${deal.title}" was removed from the marketplace. Reason: ${reason.label}`,
      {
        deal_id: deal.id,
        reason_code: reason.code,
        reason_label: reason.label,
      }
    );
    await deal.reload();
    const j = deal.toJSON();
    j.images = parseDealImages(j.images);
    j.vendor = null;
    const v = await User.findByPk(deal.vendor_id, { attributes: ['id', 'full_name', 'email', 'phone'] });
    if (v) j.vendor = v.toJSON();
    res.json({ success: true, deal: j, message: 'Deal removed. Vendor has been notified.' });
  } catch (err) {
    next(err);
  }
});

module.exports = router;
