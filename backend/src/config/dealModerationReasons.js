/** Preset reasons when admin removes a deal (audit + vendor notification). */
const DEAL_MODERATION_REASONS = [
  { code: 'MISLEADING', label: 'Misleading or inaccurate listing' },
  { code: 'PROHIBITED', label: 'Prohibited or restricted item or service' },
  { code: 'POLICY_VIOLATION', label: 'Violates marketplace policy or terms' },
  { code: 'INAPPROPRIATE_MEDIA', label: 'Inappropriate or low-quality images' },
  { code: 'PRICING_FRAUD', label: 'Suspicious or fraudulent pricing' },
  { code: 'DUPLICATE_SPAM', label: 'Duplicate listing or spam' },
  { code: 'OTHER', label: 'Other (see platform communication)' },
];

function getReasonByCode(code) {
  if (!code || typeof code !== 'string') return null;
  const c = code.trim().toUpperCase();
  return DEAL_MODERATION_REASONS.find((r) => r.code === c) || null;
}

module.exports = { DEAL_MODERATION_REASONS, getReasonByCode };
