const { validationResult } = require('express-validator');

function validate(validations) {
  return async (req, res, next) => {
    await Promise.all(validations.map((v) => v.run(req)));
    const errors = validationResult(req);
    if (errors.isEmpty()) return next();
    const err = new Error('Validation failed');
    err.statusCode = 422;
    err.errors = errors.array();
    next(err);
  };
}

module.exports = { validate };
