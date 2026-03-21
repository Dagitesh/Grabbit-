const jwt = require('jsonwebtoken');
const { authenticate, authorize } = require('../../src/middleware/auth');
const { ROLES } = require('../../src/config/constants');

describe('auth middleware', () => {
  const secret = process.env.JWT_ACCESS_SECRET;

  describe('authenticate', () => {
    it('401 when Authorization header missing', () => {
      const req = { headers: {} };
      const res = {};
      const next = jest.fn();
      authenticate(req, res, next);
      expect(next).toHaveBeenCalledWith(expect.any(Error));
      expect(next.mock.calls[0][0].statusCode).toBe(401);
    });

    it('401 when token invalid', () => {
      const req = { headers: { authorization: 'Bearer not-a-jwt' } };
      const next = jest.fn();
      authenticate(req, {}, next);
      expect(next.mock.calls[0][0].statusCode).toBe(401);
    });

    it('sets req.user when Bearer token valid', () => {
      const token = jwt.sign({ sub: 'user-uuid-1', role: ROLES.CUSTOMER }, secret, { expiresIn: '1h' });
      const req = { headers: { authorization: `Bearer ${token}` } };
      const next = jest.fn();
      authenticate(req, {}, next);
      expect(next).toHaveBeenCalledWith();
      expect(req.user).toEqual({ id: 'user-uuid-1', role: ROLES.CUSTOMER });
    });
  });

  describe('authorize', () => {
    it('403 when role not allowed', () => {
      const middleware = authorize(ROLES.ADMIN);
      const req = { user: { id: '1', role: ROLES.CUSTOMER } };
      const next = jest.fn();
      middleware(req, {}, next);
      expect(next.mock.calls[0][0].statusCode).toBe(403);
    });

    it('calls next when role allowed', () => {
      const middleware = authorize(ROLES.VENDOR);
      const req = { user: { id: '1', role: ROLES.VENDOR } };
      const next = jest.fn();
      middleware(req, {}, next);
      expect(next).toHaveBeenCalledWith();
    });
  });
});
