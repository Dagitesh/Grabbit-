const request = require('supertest');
const { createApp } = require('../../src/app');

describe('HTTP integration (no database)', () => {
  let app;

  beforeAll(() => {
    app = createApp();
  });

  it('GET /api/health returns ok', async () => {
    const res = await request(app).get('/api/health').expect(200);
    expect(res.body.status).toBe('ok');
    expect(res.body.timestamp).toBeDefined();
  });

  it('POST /api/auth/login validates body (422)', async () => {
    const res = await request(app).post('/api/auth/login').send({}).expect(422);
    expect(res.body.success).toBe(false);
    expect(res.body.message).toBeDefined();
    expect(Array.isArray(res.body.errors)).toBe(true);
  });

  it('POST /api/auth/register validates required fields (422)', async () => {
    const res = await request(app).post('/api/auth/register').send({ email: 'bad' }).expect(422);
    expect(res.body.success).toBe(false);
  });

  it('POST /api/auth/verify-otp requires phone + 6-digit code (422)', async () => {
    const res = await request(app)
      .post('/api/auth/verify-otp')
      .send({ phone: '+251911234567', otpCode: '12' })
      .expect(422);
    expect(res.body.success).toBe(false);
  });

  it('GET unknown /api route returns JSON 404', async () => {
    const res = await request(app).get('/api/this-route-should-not-exist-xyz').expect(404);
    expect(res.body.success).toBe(false);
    expect(res.body.message).toBe('Not found');
    expect(res.body.path).toContain('/api/');
  });

  it('GET /api/me without token returns 401', async () => {
    const res = await request(app).get('/api/me').expect(401);
    expect(res.body.success).toBe(false);
  });
});
