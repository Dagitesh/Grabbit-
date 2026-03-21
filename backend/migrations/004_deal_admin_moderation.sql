-- Admin moderation: hide deals from public feed, store reason, notify vendor
ALTER TABLE deals
  ADD COLUMN IF NOT EXISTS removed_by_admin BOOLEAN NOT NULL DEFAULT false;

ALTER TABLE deals
  ADD COLUMN IF NOT EXISTS admin_removal_reason_code VARCHAR(64);

ALTER TABLE deals
  ADD COLUMN IF NOT EXISTS admin_removal_reason_label TEXT;

ALTER TABLE deals
  ADD COLUMN IF NOT EXISTS admin_removed_at TIMESTAMPTZ;

CREATE INDEX IF NOT EXISTS idx_deals_removed_by_admin ON deals (removed_by_admin) WHERE removed_by_admin = true;
