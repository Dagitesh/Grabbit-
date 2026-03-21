const { getReasonByCode, DEAL_MODERATION_REASONS } = require('../../src/config/dealModerationReasons');

describe('dealModerationReasons', () => {
  it('exports non-empty preset list', () => {
    expect(Array.isArray(DEAL_MODERATION_REASONS)).toBe(true);
    expect(DEAL_MODERATION_REASONS.length).toBeGreaterThan(0);
    DEAL_MODERATION_REASONS.forEach((r) => {
      expect(r).toHaveProperty('code');
      expect(r).toHaveProperty('label');
    });
  });

  it('getReasonByCode returns match (case-insensitive)', () => {
    expect(getReasonByCode('misleading')?.code).toBe('MISLEADING');
    expect(getReasonByCode(' PROHIBITED ')?.code).toBe('PROHIBITED');
  });

  it('getReasonByCode returns null for unknown', () => {
    expect(getReasonByCode('UNKNOWN_CODE')).toBeNull();
    expect(getReasonByCode('')).toBeNull();
    expect(getReasonByCode(null)).toBeNull();
  });
});
