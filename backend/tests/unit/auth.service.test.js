jest.mock('bcryptjs', () => ({
  hash: jest.fn(),
  compare: jest.fn(),
}));

jest.mock('../../src/modules/user/user.repository', () => ({
  findByEmail: jest.fn(),
  create: jest.fn(),
  findById: jest.fn(),
  clearOtpAndVerify: jest.fn(),
}));

jest.mock('../../src/modules/customer/customerProfile.model', () => ({
  create: jest.fn(),
}));

jest.mock('../../src/modules/subcity/subcity.model', () => ({
  findByPk: jest.fn(),
}));

const bcrypt = require('bcryptjs');
const userRepository = require('../../src/modules/user/user.repository');
const CustomerProfile = require('../../src/modules/customer/customerProfile.model');
const Subcity = require('../../src/modules/subcity/subcity.model');
const authService = require('../../src/modules/auth/auth.service');

describe('auth.service', () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  describe('register', () => {
    it('rejects invalid subcity', async () => {
      Subcity.findByPk.mockResolvedValue(null);
      await expect(
        authService.register({
          first_name: 'A',
          last_name: 'B',
          email: 'a@b.com',
          phone: '1',
          password: 'secret1',
          subcity_id: '00000000-0000-4000-8000-000000000001',
        })
      ).rejects.toMatchObject({ statusCode: 400 });
    });

    it('rejects duplicate email', async () => {
      Subcity.findByPk.mockResolvedValue({ id: 'sc1', name: 'Bole' });
      userRepository.findByEmail.mockResolvedValue({ id: 'u1' });
      await expect(
        authService.register({
          first_name: 'A',
          last_name: 'B',
          email: 'taken@b.com',
          phone: '1',
          password: 'secret1',
          subcity_id: '00000000-0000-4000-8000-000000000001',
        })
      ).rejects.toMatchObject({ statusCode: 409 });
    });

    it('creates customer when subcity valid and email free', async () => {
      Subcity.findByPk.mockResolvedValue({ id: 'sc1', name: 'Bole' });
      userRepository.findByEmail.mockResolvedValue(null);
      bcrypt.hash.mockResolvedValue('hashed-pass');
      userRepository.create.mockResolvedValue({
        id: 'new-user-id',
        full_name: 'A B',
        email: 'new@b.com',
        role: 'CUSTOMER',
        is_verified: false,
      });
      CustomerProfile.create.mockResolvedValue({});

      const result = await authService.register({
        first_name: 'A',
        last_name: 'B',
        email: 'new@b.com',
        phone: '+251911',
        password: 'secret1',
        subcity_id: '00000000-0000-4000-8000-000000000001',
      });

      expect(result.role).toBe('CUSTOMER');
      expect(result.is_verified).toBe(false);
      expect(CustomerProfile.create).toHaveBeenCalled();
    });
  });

  describe('login', () => {
    it('rejects unknown user', async () => {
      userRepository.findByEmail.mockResolvedValue(null);
      await expect(authService.login('x@y.com', 'pw')).rejects.toMatchObject({ statusCode: 401 });
    });

    it('rejects wrong password', async () => {
      userRepository.findByEmail.mockResolvedValue({
        password_hash: 'hash',
        is_verified: true,
      });
      bcrypt.compare.mockResolvedValue(false);
      await expect(authService.login('x@y.com', 'wrong')).rejects.toMatchObject({ statusCode: 401 });
    });

    it('rejects unverified account', async () => {
      userRepository.findByEmail.mockResolvedValue({
        password_hash: 'hash',
        is_verified: false,
      });
      bcrypt.compare.mockResolvedValue(true);
      await expect(authService.login('x@y.com', 'ok')).rejects.toMatchObject({ statusCode: 403 });
    });

    it('returns tokens when verified and password matches', async () => {
      userRepository.findByEmail.mockResolvedValue({
        id: 'u1',
        full_name: 'Test User',
        email: 't@t.com',
        phone: null,
        password_hash: 'hash',
        role: 'CUSTOMER',
        is_verified: true,
      });
      bcrypt.compare.mockResolvedValue(true);

      const result = await authService.login('t@t.com', 'password');

      expect(result.accessToken).toBeTruthy();
      expect(result.refreshToken).toBeTruthy();
      expect(result.user.email).toBe('t@t.com');
      expect(result.expiresIn).toBe(900);
    });
  });

  describe('verifyOtp', () => {
    it('rejects invalid OTP', async () => {
      userRepository.findByEmail.mockResolvedValue({ id: 'u1' });
      const userWithOtp = {
        otp_code: '111111',
        otp_expires_at: new Date(Date.now() + 60000),
      };
      userRepository.findById.mockResolvedValue(userWithOtp);

      await expect(authService.verifyOtp('u@u.com', '999999')).rejects.toMatchObject({ statusCode: 400 });
    });
  });

  describe('refreshTokens', () => {
    it('rejects token without refresh type', async () => {
      const jwt = require('jsonwebtoken');
      const bad = jwt.sign({ sub: 'u1' }, process.env.JWT_REFRESH_SECRET, { expiresIn: '1h' });
      await expect(authService.refreshTokens(bad)).rejects.toMatchObject({ statusCode: 401 });
    });
  });
});
