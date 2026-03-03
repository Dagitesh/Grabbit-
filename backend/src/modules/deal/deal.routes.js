const express = require('express');
const { authenticate, authorize } = require('../../middleware/auth');
const { ROLES } = require('../../config/constants');
const Deal = require('./deal.model');
const { Op } = require('sequelize');

const router = express.Router();

function _parseImages(val) {
  if (!val) return [];
  if (Array.isArray(val)) return val;
  try {
    return JSON.parse(val) || [];
  } catch (_) {
    return [];
  }
}

// GET /api/deals - paginated list (public or authenticated)
router.get('/deals', async (req, res, next) => {
  try {
    const page = Math.max(1, parseInt(req.query.page, 10) || 1);
    const limit = Math.min(50, Math.max(1, parseInt(req.query.limit, 10) || 10));
    const offset = (page - 1) * limit;
    const search = (req.query.search || '').trim();
    const location = (req.query.location || '').trim();
    const category = (req.query.category || '').trim();
    const minPrice = req.query.minPrice != null ? parseFloat(req.query.minPrice) : null;
    const maxPrice = req.query.maxPrice != null ? parseFloat(req.query.maxPrice) : null;
    const activeOnly = req.query.active === 'true';

    const where = {};
    if (location) {
      where.location = { [Op.iLike]: `%${location}%` };
    }
    if (category) {
      where.category = { [Op.iLike]: `%${category}%` };
    }
    if (search) {
      where[Op.or] = [
        { title: { [Op.iLike]: `%${search}%` } },
        { description: { [Op.iLike]: `%${search}%` } },
      ];
    }
    if (minPrice != null && !Number.isNaN(minPrice)) {
      where.discounted_price = where.discounted_price || {};
      where.discounted_price[Op.gte] = minPrice;
    }
    if (maxPrice != null && !Number.isNaN(maxPrice)) {
      where.discounted_price = where.discounted_price || {};
      where.discounted_price[Op.lte] = maxPrice;
    }
    if (activeOnly) {
      where.is_active = true;
      where.expiry_date = { [Op.gte]: new Date() };
    }

    const { count, rows } = await Deal.findAndCountAll({
      where,
      limit,
      offset,
      order: [['created_at', 'DESC']],
    });

    const list = rows.map((d) => {
      const j = d.toJSON();
      j.expiry_date = j.expiry_date ? new Date(j.expiry_date).toISOString().slice(0, 10) : j.expiry_date;
      j.original_price = Number(j.original_price);
      j.discounted_price = Number(j.discounted_price);
      j.images = _parseImages(j.images);
      return j;
    });

    const totalPages = Math.ceil(count / limit) || 1;
    res.json({
      deals: list,
      data: list,
      items: list,
      total: count,
      page,
      limit,
      totalPages,
      meta: { totalPages, total: count, page, limit },
    });
  } catch (err) {
    next(err);
  }
});

// GET /api/deals/:id
router.get('/deals/:id', async (req, res, next) => {
  try {
    const deal = await Deal.findByPk(req.params.id);
    if (!deal) {
      const err = new Error('Deal not found');
      err.statusCode = 404;
      return next(err);
    }
    const j = deal.toJSON();
    j.expiry_date = j.expiry_date ? new Date(j.expiry_date).toISOString().slice(0, 10) : j.expiry_date;
    j.original_price = Number(j.original_price);
    j.discounted_price = Number(j.discounted_price);
    j.images = _parseImages(j.images);
    res.json(j);
  } catch (err) {
    next(err);
  }
});

// POST /api/deals - vendor only
router.post('/deals', authenticate, authorize(ROLES.VENDOR), async (req, res, next) => {
  try {
    const {
      title,
      description,
      location,
      category,
      images,
      original_price,
      discounted_price,
      quantity_available,
      expiry_date,
    } = req.body;
    if (!title || original_price == null || discounted_price == null || quantity_available == null || !expiry_date) {
      const err = new Error('Missing required fields: title, original_price, discounted_price, quantity_available, expiry_date');
      err.statusCode = 400;
      return next(err);
    }
    const expiry = new Date(expiry_date);
    if (isNaN(expiry.getTime())) {
      const err = new Error('Invalid expiry_date');
      err.statusCode = 400;
      return next(err);
    }
    const imagesJson = Array.isArray(images) && images.length > 0
      ? JSON.stringify(images.map((u) => String(u)))
      : null;
    const deal = await Deal.create({
      vendor_id: req.user.id,
      title: String(title).trim(),
      description: description != null ? String(description).trim() : null,
      location: location != null ? String(location).trim() || null : null,
      category: category != null ? String(category).trim() || null : null,
      images: imagesJson,
      original_price: parseFloat(original_price),
      discounted_price: parseFloat(discounted_price),
      quantity_available: parseInt(quantity_available, 10),
      expiry_date: expiry,
      is_active: true,
    });
    const j = deal.toJSON();
    j.expiry_date = j.expiry_date ? new Date(j.expiry_date).toISOString().slice(0, 10) : j.expiry_date;
    j.original_price = Number(j.original_price);
    j.discounted_price = Number(j.discounted_price);
    j.images = _parseImages(j.images);
    res.status(201).json(j);
  } catch (err) {
    next(err);
  }
});

// PUT /api/deals/:id - vendor only (own deals)
router.put('/deals/:id', authenticate, authorize(ROLES.VENDOR), async (req, res, next) => {
  try {
    const deal = await Deal.findByPk(req.params.id);
    if (!deal) {
      const err = new Error('Deal not found');
      err.statusCode = 404;
      return next(err);
    }
    if (deal.vendor_id !== req.user.id) {
      const err = new Error('Forbidden');
      err.statusCode = 403;
      return next(err);
    }
    const {
      title,
      description,
      location,
      category,
      images,
      original_price,
      discounted_price,
      quantity_available,
      expiry_date,
      is_active,
    } = req.body;
    const updates = {};
    if (title !== undefined) updates.title = String(title).trim();
    if (description !== undefined) updates.description = description ? String(description).trim() : null;
    if (location !== undefined) updates.location = location ? String(location).trim() : null;
    if (category !== undefined) updates.category = category ? String(category).trim() : null;
    if (images !== undefined) {
      updates.images = Array.isArray(images) && images.length > 0
        ? JSON.stringify(images.map((u) => String(u)))
        : null;
    }
    if (original_price !== undefined) updates.original_price = parseFloat(original_price);
    if (discounted_price !== undefined) updates.discounted_price = parseFloat(discounted_price);
    if (quantity_available !== undefined) updates.quantity_available = parseInt(quantity_available, 10);
    if (expiry_date !== undefined) {
      const expiry = new Date(expiry_date);
      if (!isNaN(expiry.getTime())) updates.expiry_date = expiry;
    }
    if (typeof is_active === 'boolean') updates.is_active = is_active;
    await deal.update(updates);
    const j = (await Deal.findByPk(deal.id)).toJSON();
    j.expiry_date = j.expiry_date ? new Date(j.expiry_date).toISOString().slice(0, 10) : j.expiry_date;
    j.original_price = Number(j.original_price);
    j.discounted_price = Number(j.discounted_price);
    j.images = _parseImages(j.images);
    res.json(j);
  } catch (err) {
    next(err);
  }
});

module.exports = router;
