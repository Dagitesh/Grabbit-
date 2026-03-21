function parseDealImages(val) {
  if (!val) return [];
  if (Array.isArray(val)) return val;
  try {
    return JSON.parse(val) || [];
  } catch (_) {
    return [];
  }
}

module.exports = { parseDealImages };
