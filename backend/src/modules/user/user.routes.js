const express = require('express');
const { authenticate } = require('../../middleware/auth');
const userRepository = require('./user.repository');

const router = express.Router();

router.get('/me', authenticate, async (req, res, next) => {
  try {
    const user = await userRepository.findById(req.user.id);
    if (!user) {
      const err = new Error('User not found');
      err.statusCode = 404;
      return next(err);
    }
    res.json(user.toJSON());
  } catch (err) {
    next(err);
  }
});

module.exports = router;
