const express = require('express');
const crypto = require('crypto');
const { authenticate, authorize } = require('../../middleware/auth');
const { ROLES } = require('../../config/constants');
const Order = require('./order.model');
const Deal = require('../deal/deal.model');
const User = require('../user/user.model');

const router = express.Router();

function generateClaimCode() {
  return crypto.randomBytes(6).toString('hex').toUpperCase();
}

// POST /api/orders - customer creates order (reserve deal)
router.post('/orders', authenticate, authorize(ROLES.CUSTOMER), async (req, res, next) => {
  try {
    const { deal_id, quantity = 1 } = req.body;
    if (!deal_id) {
      const err = new Error('deal_id is required');
      err.statusCode = 400;
      return next(err);
    }
    const deal = await Deal.findByPk(deal_id);
    if (!deal) {
      const err = new Error('Deal not found');
      err.statusCode = 404;
      return next(err);
    }
    if (!deal.is_active) {
      const err = new Error('Deal is not active');
      err.statusCode = 400;
      return next(err);
    }
    const expiryVal = deal.expiry_time ?? deal.expiry_date;
    if (new Date(expiryVal) < new Date()) {
      const err = new Error('Deal has expired');
      err.statusCode = 400;
      return next(err);
    }
    const avail = deal.available_quantity ?? deal.quantity_available ?? 0;
    const qty = Math.max(1, parseInt(quantity, 10) || 1);
    if (avail < qty) {
      const err = new Error('Not enough quantity available');
      err.statusCode = 400;
      return next(err);
    }
    const expiryDate = new Date(expiryVal);
    const pickupAt = new Date(expiryDate);
    pickupAt.setHours(18, 0, 0, 0);
    if (pickupAt < new Date()) pickupAt.setDate(pickupAt.getDate() + 1);

    let claimCode = generateClaimCode();
    let exists = await Order.findOne({ where: { claim_code: claimCode } });
    while (exists) {
      claimCode = generateClaimCode();
      exists = await Order.findOne({ where: { claim_code: claimCode } });
    }

    const order = await Order.create({
      user_id: req.user.id,
      deal_id: deal.id,
      quantity: qty,
      status: 'Created',
      claim_code: claimCode,
      pickup_at: pickupAt,
    });
    const newAvail = avail - qty;
    await deal.update({ quantity_available: newAvail, available_quantity: newAvail });
    const dealPrice = deal.discount_price ?? deal.discounted_price;
    const j = order.toJSON();
    j.deal_title = deal.title;
    j.discounted_price = Number(dealPrice);
    j.quantity = order.quantity;
    j.claim_code = order.claim_code;
    res.status(201).json(j);
  } catch (err) {
    next(err);
  }
});

// GET /api/orders - customer's orders
router.get('/orders', authenticate, async (req, res, next) => {
  try {
    const orders = await Order.findAll({
      where: { user_id: req.user.id },
      include: [{ model: Deal, as: 'deal', attributes: ['id', 'title', 'discounted_price', 'discount_price'] }],
      order: [['created_at', 'DESC']],
    });
    const list = orders.map((o) => {
      const j = o.toJSON();
      j.deal_title = o.deal?.title ?? '';
      j.deal_id = o.deal_id;
      const dp = o.deal?.discount_price ?? o.deal?.discounted_price;
      j.discounted_price = o.deal ? Number(dp) : null;
      j.quantity = o.quantity;
      j.claim_code = o.claim_code;
      j.created_at = o.created_at;
      j.pickup_at = o.pickup_at ? new Date(o.pickup_at).toISOString() : null;
      return j;
    });
    res.json(list);
  } catch (err) {
    next(err);
  }
});

// PATCH /api/orders/:id/cancel - customer cancels order (rejected if < 2h before pickup)
router.patch('/orders/:id/cancel', authenticate, authorize(ROLES.CUSTOMER), async (req, res, next) => {
  try {
    const order = await Order.findByPk(req.params.id);
    if (!order || order.user_id !== req.user.id) {
      const err = new Error('Order not found');
      err.statusCode = 404;
      return next(err);
    }
    if (order.status === 'Cancelled' || order.status === 'Completed') {
      const err = new Error('Order cannot be cancelled');
      err.statusCode = 400;
      return next(err);
    }
    const pickupAt = order.pickup_at ? new Date(order.pickup_at) : null;
    if (pickupAt) {
      const twoHoursBefore = new Date(pickupAt.getTime() - 2 * 60 * 60 * 1000);
      if (new Date() > twoHoursBefore) {
        const err = new Error('Cannot cancel: less than 2 hours before pickup window');
        err.statusCode = 400;
        return next(err);
      }
    }
    await order.update({ status: 'Cancelled' });
    const deal = await Deal.findByPk(order.deal_id);
    if (deal) {
      const avail = (deal.available_quantity ?? deal.quantity_available ?? 0) + order.quantity;
      await deal.update({ quantity_available: avail, available_quantity: avail });
    }
    const j = order.toJSON();
    j.deal_title = deal?.title ?? '';
    j.deal_id = order.deal_id;
    const dp = deal?.discount_price ?? deal?.discounted_price;
    j.discounted_price = deal ? Number(dp) : null;
    j.quantity = order.quantity;
    j.claim_code = order.claim_code;
    j.pickup_at = order.pickup_at ? new Date(order.pickup_at).toISOString() : null;
    res.json(j);
  } catch (err) {
    next(err);
  }
});

module.exports = router;
