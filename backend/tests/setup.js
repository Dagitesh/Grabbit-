/**
 * Runs before each test file. Keeps JWT verification deterministic in tests.
 */
process.env.NODE_ENV = 'test';

if (!process.env.JWT_ACCESS_SECRET) {
  process.env.JWT_ACCESS_SECRET = 'jest-access-secret-min-32-chars-long!!';
}
if (!process.env.JWT_REFRESH_SECRET) {
  process.env.JWT_REFRESH_SECRET = 'jest-refresh-secret-min-32-chars!!';
}
