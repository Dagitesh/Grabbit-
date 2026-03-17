const express = require('express');
const { authenticate, authorize } = require('../../middleware/auth');
const { ROLES } = require('../../config/constants');
const vendorProfileRepository = require('./vendorProfile.repository');
const Deal = require('../deal/deal.model');
const Order = require('../order/order.model');

const router = express.Router();

router.use(authenticate, authorize(ROLES.VENDOR));

// GET /api/vendor/profile
router.get('/profile', async (req, res, next) => {
  try {
    const profile = await vendorProfileRepository.getOrCreate(req.user.id);
    res.json(profile.toJSON());
  } catch (err) {
    next(err);
  }
});

// PUT /api/vendor/profile
router.put('/profile', async (req, res, next) => {
  try {
    const { business_name, business_description, phone, location, tin } = req.body;
    const profile = await vendorProfileRepository.getOrCreate(req.user.id, {
      business_name: business_name || 'My Business',
      business_description: business_description ?? null,
      phone: phone || '',
      location: location ?? null,
      tin: tin ?? null,
    });
    await profile.update({
      business_name: business_name ?? profile.business_name,
      business_description: business_description !== undefined ? business_description : profile.business_description,
      phone: phone ?? profile.phone,
      location: location !== undefined ? location : profile.location,
      ...(tin !== undefined && { tin: tin || null }),
    });
    res.json(profile.toJSON());
  } catch (err) {
    next(err);
  }
});

// GET /api/vendor/dashboard
router.get('/dashboard', async (req, res, next) => {
  try {
    const profile = await vendorProfileRepository.getOrCreate(req.user.id);
    const now = new Date();
    const deals = await Deal.findAll({
      where: { vendor_id: req.user.id },
      attributes: ['id', 'is_active', 'expiry_date'],
    });
    const totalDeals = deals.length;
    const activeDeals = deals.filter(
      (d) => d.is_active && new Date(d.expiry_date) >= now
    ).length;
    const expiredDeals = totalDeals - activeDeals;
    const vendorDealIds = (await Deal.findAll({ where: { vendor_id: req.user.id }, attributes: ['id'] })).map((d) => d.id);
    const totalOrders = vendorDealIds.length
      ? await Order.count({ where: { deal_id: vendorDealIds } })
      : 0;

    res.json({
      vendor: profile.toJSON(),
      stats: {
        totalDeals,
        activeDeals,
        expiredDeals,
        totalOrders,
        revenue: null,
      },
    });
  } catch (err) {
    next(err);
  }
});

// GET /api/vendor/deals
router.get('/deals', async (req, res, next) => {
  try {
    const deals = await Deal.findAll({
      where: { vendor_id: req.user.id },
      order: [['created_at', 'DESC']],
    });
    const list = deals.map((d) => {
      const j = d.toJSON();
      j.expiry_date = j.expiry_date ? new Date(j.expiry_date).toISOString().slice(0, 10) : j.expiry_date;
      return j;
    });
    res.json(list);
  } catch (err) {
    next(err);
  }
});

// GET /api/vendor/orders
router.get('/orders', async (req, res, next) => {
  try {
    const User = require('../user/user.model');
    const vendorDealIds = (await Deal.findAll({ where: { vendor_id: req.user.id }, attributes: ['id'] })).map((d) => d.id);
    if (vendorDealIds.length === 0) return res.json([]);
    const orders = await Order.findAll({
      where: { deal_id: vendorDealIds },
      include: [
        { model: Deal, as: 'deal', attributes: ['id', 'title', 'discounted_price', 'discount_price'] },
        { model: User, as: 'customer', attributes: ['id', 'full_name', 'email'] },
      ],
      order: [['created_at', 'DESC']],
    });
    const list = orders.map((o) => {
      const j = o.toJSON();
      j.deal_title = o.deal?.title ?? '';
      j.deal_id = o.deal_id;
      j.customer_name = o.customer?.full_name ?? o.customer?.email ?? 'Customer';
      j.discounted_price = o.deal ? Number(o.deal.discounted_price) : null;
      j.quantity = o.quantity;
      j.created_at = o.created_at;
      return j;
    });
    res.json(list);
  } catch (err) {
    next(err);
  }
});

module.exports = router;
