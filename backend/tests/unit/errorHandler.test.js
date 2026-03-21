const errorHandler = require('../../src/utils/errorHandler');

beforeAll(() => {
  jest.spyOn(console, 'error').mockImplementation(() => {});
});

afterAll(() => {
  console.error.mockRestore();
});

function mockRes() {
  const res = {};
  res.status = jest.fn().mockReturnValue(res);
  res.json = jest.fn().mockReturnValue(res);
  return res;
}

describe('errorHandler', () => {
  it('returns JSON with success false and message', () => {
    const err = new Error('Something broke');
    err.statusCode = 400;
    const req = {};
    const res = mockRes();
    const next = jest.fn();

    errorHandler(err, req, res, next);

    expect(res.status).toHaveBeenCalledWith(400);
    expect(res.json).toHaveBeenCalledWith(
      expect.objectContaining({
        success: false,
        message: 'Something broke',
      })
    );
  });

  it('defaults to 500 when no statusCode', () => {
    const err = new Error('Internal');
    const res = mockRes();
    errorHandler(err, {}, res, jest.fn());
    expect(res.status).toHaveBeenCalledWith(500);
  });

  it('includes errors array from express-validator style err.errors', () => {
    const err = new Error('Validation failed');
    err.statusCode = 422;
    err.errors = [{ msg: 'Email is required', path: 'email' }];
    const res = mockRes();
    errorHandler(err, {}, res, jest.fn());
    expect(res.json).toHaveBeenCalledWith(
      expect.objectContaining({
        success: false,
        errors: err.errors,
      })
    );
  });
});
