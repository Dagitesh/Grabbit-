const { parseDealImages } = require('../../src/utils/parseDealImages');

describe('parseDealImages', () => {
  it('returns empty array for null/undefined', () => {
    expect(parseDealImages(null)).toEqual([]);
    expect(parseDealImages(undefined)).toEqual([]);
  });

  it('returns same array if already array', () => {
    const arr = ['https://a.com/1.jpg'];
    expect(parseDealImages(arr)).toBe(arr);
  });

  it('parses JSON array string', () => {
    expect(parseDealImages('["https://x.com/a.png"]')).toEqual(['https://x.com/a.png']);
  });

  it('returns empty array on invalid JSON', () => {
    expect(parseDealImages('not-json')).toEqual([]);
  });
});
