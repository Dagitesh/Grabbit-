const jwt = require('jsonwebtoken');
const { ROLES } = require('../config/constants');

function authenticate(req, res, next) {
  const authHeader = req.headers.authorization;
  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    const err = new Error('Access token required');
    err.statusCode = 401;
    return next(err);
  }

  const token = authHeader.split(' ')[1];
  try {
    const decoded = jwt.verify(token, process.env.JWT_ACCESS_SECRET);
    req.user = { id: decoded.sub, role: decoded.role };
    next();
  } catch (e) {
    const err = new Error('Invalid or expired token');
    err.statusCode = 401;
    next(err);
  }
}

function authorize(...allowedRoles) {
  const set = new Set(allowedRoles.length ? allowedRoles : Object.values(ROLES));
  return (req, res, next) => {
    if (!req.user) {
      const err = new Error('Unauthorized');
      err.statusCode = 401;
      return next(err);
    }
    if (!set.has(req.user.role)) {
      const err = new Error('Forbidden');
      err.statusCode = 403;
      return next(err);
    }
    next();
  };
}

module.exports = { authenticate, authorize };
