const express = require('express');
const { authenticate, authorize } = require('../../middleware/auth');
const { ROLES } = require('../../config/constants');
const Order = require('./order.model');
const Deal = require('../deal/deal.model');
const User = require('../user/user.model');

const router = express.Router();

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
    if (new Date(deal.expiry_date) < new Date()) {
      const err = new Error('Deal has expired');
      err.statusCode = 400;
      return next(err);
    }
    const qty = Math.max(1, parseInt(quantity, 10) || 1);
    if (deal.quantity_available < qty) {
      const err = new Error('Not enough quantity available');
      err.statusCode = 400;
      return next(err);
    }
    const expiryDate = new Date(deal.expiry_date);
    const pickupAt = new Date(expiryDate);
    pickupAt.setHours(18, 0, 0, 0);
    if (pickupAt < new Date()) pickupAt.setDate(pickupAt.getDate() + 1);

    const order = await Order.create({
      user_id: req.user.id,
      deal_id: deal.id,
      quantity: qty,
      status: 'Created',
      pickup_at: pickupAt,
    });
    await deal.update({ quantity_available: deal.quantity_available - qty });
    const j = order.toJSON();
    j.deal_title = deal.title;
    j.discounted_price = Number(deal.discounted_price);
    j.quantity = order.quantity;
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
      include: [{ model: Deal, as: 'deal', attributes: ['id', 'title', 'discounted_price'] }],
      order: [['created_at', 'DESC']],
    });
    const list = orders.map((o) => {
      const j = o.toJSON();
      j.deal_title = o.deal?.title ?? '';
      j.deal_id = o.deal_id;
      j.discounted_price = o.deal ? Number(o.deal.discounted_price) : null;
      j.quantity = o.quantity;
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
    if (deal) await deal.update({ quantity_available: deal.quantity_available + order.quantity });
    const j = order.toJSON();
    j.deal_title = deal?.title ?? '';
    j.deal_id = order.deal_id;
    j.discounted_price = deal ? Number(deal.discounted_price) : null;
    j.quantity = order.quantity;
    j.pickup_at = order.pickup_at ? new Date(order.pickup_at).toISOString() : null;
    res.json(j);
  } catch (err) {
    next(err);
  }
});

module.exports = router;
