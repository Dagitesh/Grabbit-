const express = require('express');
const { authenticate, authorize } = require('../../middleware/auth');
const { ROLES } = require('../../config/constants');
const Deal = require('./deal.model');
const VendorProfile = require('../vendor/vendorProfile.model');
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
    const categoryId = (req.query.categoryId || req.query.category_id || '').trim();
    const minPrice = req.query.minPrice != null ? parseFloat(req.query.minPrice) : null;
    const maxPrice = req.query.maxPrice != null ? parseFloat(req.query.maxPrice) : null;
    const activeOnly = req.query.active === 'true';

    const where = {};
    if (location) {
      where.location = { [Op.iLike]: `%${location}%` };
    }
    if (categoryId) {
      where.category_id = categoryId;
    } else if (category) {
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
    let queryWhere = where;
    if (activeOnly) {
      const expiryOr = {
        [Op.or]: [
          { expiry_time: { [Op.gte]: new Date() } },
          { expiry_date: { [Op.gte]: new Date() } },
        ],
      };
      queryWhere = { [Op.and]: [{ ...where }, { is_active: true }, expiryOr] };
    }

    const { count, rows } = await Deal.findAndCountAll({
      where: queryWhere,
      limit,
      offset,
      order: [['created_at', 'DESC']],
    });

    const list = rows.map((d) => {
      const j = d.toJSON();
      const expiryVal = j.expiry_time ?? j.expiry_date;
      j.expiry_date = expiryVal ? new Date(expiryVal).toISOString().slice(0, 10) : j.expiry_date;
      j.expiry_time = expiryVal ? new Date(expiryVal).toISOString() : j.expiry_time;
      j.original_price = Number(j.original_price);
      j.discounted_price = Number(j.discount_price ?? j.discounted_price);
      j.quantity_available = j.available_quantity ?? j.quantity_available;
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
    const expiryVal = j.expiry_time ?? j.expiry_date;
    j.expiry_date = expiryVal ? new Date(expiryVal).toISOString().slice(0, 10) : j.expiry_date;
    j.expiry_time = expiryVal ? new Date(expiryVal).toISOString() : j.expiry_time;
    j.original_price = Number(j.original_price);
    j.discounted_price = Number(j.discount_price ?? j.discounted_price);
    j.quantity_available = j.available_quantity ?? j.quantity_available;
    j.images = _parseImages(j.images);
    res.json(j);
  } catch (err) {
    next(err);
  }
});

// POST /api/deals - vendor only (must be approved)
router.post('/deals', authenticate, authorize(ROLES.VENDOR), async (req, res, next) => {
  try {
    const vendorProfile = await VendorProfile.findOne({ where: { user_id: req.user.id } });
    if (!vendorProfile || !vendorProfile.is_approved) {
      const err = new Error('Your vendor account is pending approval. You cannot create deals until an admin approves your account.');
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
      discount_price,
      quantity_available,
      available_quantity,
      total_quantity,
      expiry_date,
      expiry_time,
      start_time,
      location_id,
      category_id,
    } = req.body;
    const price = discount_price ?? discounted_price;
    const qty = available_quantity ?? quantity_available;
    const total = total_quantity ?? qty;
    const expiryVal = expiry_time ?? expiry_date;
    if (!title || original_price == null || price == null || (qty == null && total == null) || !expiryVal) {
      const err = new Error('Missing required fields: title, original_price, discount_price (or discounted_price), quantity (available/total), expiry (expiry_time or expiry_date)');
      err.statusCode = 400;
      return next(err);
    }
    const expiry = new Date(expiryVal);
    if (isNaN(expiry.getTime())) {
      const err = new Error('Invalid expiry_date/expiry_time');
      err.statusCode = 400;
      return next(err);
    }
    const start = start_time ? new Date(start_time) : new Date();
    if (isNaN(start.getTime())) {
      const err = new Error('Invalid start_time');
      err.statusCode = 400;
      return next(err);
    }
    const avail = Math.max(0, parseInt(qty, 10) || 0);
    const tot = Math.max(avail, parseInt(total, 10) || avail);
    if (parseFloat(price) >= parseFloat(original_price)) {
      const err = new Error('discount_price must be less than original_price');
      err.statusCode = 400;
      return next(err);
    }
    const imagesJson = Array.isArray(images) && images.length > 0
      ? JSON.stringify(images.map((u) => String(u)))
      : null;
    const deal = await Deal.create({
      vendor_id: req.user.id,
      location_id: location_id || null,
      category_id: category_id || null,
      title: String(title).trim(),
      description: description != null ? String(description).trim() : null,
      location: location != null ? String(location).trim() || null : null,
      category: category != null ? String(category).trim() || null : null,
      images: imagesJson,
      original_price: parseFloat(original_price),
      discounted_price: parseFloat(price),
      discount_price: parseFloat(price),
      total_quantity: tot,
      quantity_available: avail,
      available_quantity: avail,
      start_time: start,
      expiry_date: expiry,
      expiry_time: expiry,
      is_active: true,
    });
    const j = deal.toJSON();
    const expiryValJson = j.expiry_time ?? j.expiry_date;
    j.expiry_date = expiryValJson ? new Date(expiryValJson).toISOString().slice(0, 10) : j.expiry_date;
    j.original_price = Number(j.original_price);
    j.discounted_price = Number(j.discount_price ?? j.discounted_price);
    j.quantity_available = j.available_quantity ?? j.quantity_available;
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
      discount_price,
      quantity_available,
      available_quantity,
      total_quantity,
      expiry_date,
      expiry_time,
      start_time,
      location_id,
      is_active,
    } = req.body;
    const updates = {};
    if (title !== undefined) updates.title = String(title).trim();
    if (description !== undefined) updates.description = description ? String(description).trim() : null;
    if (location !== undefined) updates.location = location ? String(location).trim() : null;
    if (category !== undefined) updates.category = category ? String(category).trim() : null;
    if (location_id !== undefined) updates.location_id = location_id || null;
    if (req.body.category_id !== undefined) updates.category_id = req.body.category_id || null;
    if (images !== undefined) {
      updates.images = Array.isArray(images) && images.length > 0
        ? JSON.stringify(images.map((u) => String(u)))
        : null;
    }
    if (original_price !== undefined) updates.original_price = parseFloat(original_price);
    const price = discount_price ?? discounted_price;
    if (price !== undefined) {
      updates.discounted_price = parseFloat(price);
      updates.discount_price = parseFloat(price);
    }
    const qty = available_quantity ?? quantity_available;
    if (qty !== undefined) {
      updates.quantity_available = parseInt(qty, 10);
      updates.available_quantity = parseInt(qty, 10);
    }
    if (total_quantity !== undefined) updates.total_quantity = parseInt(total_quantity, 10);
    const expiryVal = expiry_time ?? expiry_date;
    if (expiryVal !== undefined) {
      const expiry = new Date(expiryVal);
      if (!isNaN(expiry.getTime())) {
        updates.expiry_date = expiry;
        updates.expiry_time = expiry;
      }
    }
    if (start_time !== undefined) {
      const start = new Date(start_time);
      if (!isNaN(start.getTime())) updates.start_time = start;
    }
    if (typeof is_active === 'boolean') updates.is_active = is_active;
    await deal.update(updates);
    const j = (await Deal.findByPk(deal.id)).toJSON();
    const expiryVal2 = j.expiry_time ?? j.expiry_date;
    j.expiry_date = expiryVal2 ? new Date(expiryVal2).toISOString().slice(0, 10) : j.expiry_date;
    j.original_price = Number(j.original_price);
    j.discounted_price = Number(j.discount_price ?? j.discounted_price);
    j.quantity_available = j.available_quantity ?? j.quantity_available;
    j.images = _parseImages(j.images);
    res.json(j);
  } catch (err) {
    next(err);
  }
});

module.exports = router;
