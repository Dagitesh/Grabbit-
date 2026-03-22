-- Grabbit schema v3: Addis subcities, customer profile fields, vendor admin onboarding,
-- vendor branches, deal subcity, reviews denormalized fields, vendor notifications.
-- Run after 001/002. Back up first.

-- =============================================================================
-- 1. SUBCITIES (Addis Ababa)
-- =============================================================================
CREATE TABLE IF NOT EXISTS subcities (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name VARCHAR(100) NOT NULL,
  sort_order INTEGER NOT NULL DEFAULT 0,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CONSTRAINT subcities_name_key UNIQUE (name)
);

ALTER TABLE subcities ALTER COLUMN id SET DEFAULT gen_random_uuid();
ALTER TABLE subcities ALTER COLUMN created_at SET DEFAULT NOW();
ALTER TABLE subcities ALTER COLUMN updated_at SET DEFAULT NOW();

-- Explicit ids + timestamps: legacy `subcities` tables may lack defaults on id/timestamps.
INSERT INTO subcities (id, name, sort_order, created_at, updated_at) VALUES
  (gen_random_uuid(), 'Addis Ketema', 1, NOW(), NOW()),
  (gen_random_uuid(), 'Akaky Kaliti', 2, NOW(), NOW()),
  (gen_random_uuid(), 'Arada', 3, NOW(), NOW()),
  (gen_random_uuid(), 'Bole', 4, NOW(), NOW()),
  (gen_random_uuid(), 'Gulele', 5, NOW(), NOW()),
  (gen_random_uuid(), 'Kirkos', 6, NOW(), NOW()),
  (gen_random_uuid(), 'Kolfe Keranio', 7, NOW(), NOW()),
  (gen_random_uuid(), 'Lideta', 8, NOW(), NOW()),
  (gen_random_uuid(), 'Nifas Silk-Lafto', 9, NOW(), NOW()),
  (gen_random_uuid(), 'Yeka', 10, NOW(), NOW()),
  (gen_random_uuid(), 'Lemi Kura', 11, NOW(), NOW()),
  (gen_random_uuid(), 'Other', 99, NOW(), NOW())
ON CONFLICT (name) DO NOTHING;

-- =============================================================================
-- 2. CUSTOMER_PROFILES: first/last name, subcity, preferences
-- =============================================================================
ALTER TABLE customer_profiles ADD COLUMN IF NOT EXISTS first_name VARCHAR(100);
ALTER TABLE customer_profiles ADD COLUMN IF NOT EXISTS last_name VARCHAR(100);
ALTER TABLE customer_profiles ADD COLUMN IF NOT EXISTS subcity_id UUID REFERENCES subcities(id) ON DELETE SET NULL;
ALTER TABLE customer_profiles ADD COLUMN IF NOT EXISTS saved_preferences TEXT;

-- =============================================================================
-- 3. VENDOR_PROFILES: remove approval flag; add admin-onboarding fields
-- =============================================================================
ALTER TABLE vendor_profiles DROP COLUMN IF EXISTS is_approved;
ALTER TABLE vendor_profiles ADD COLUMN IF NOT EXISTS owner_name VARCHAR(255);
ALTER TABLE vendor_profiles ADD COLUMN IF NOT EXISTS business_type VARCHAR(100);
ALTER TABLE vendor_profiles ADD COLUMN IF NOT EXISTS certificate_pdf_url TEXT;
ALTER TABLE vendor_profiles ADD COLUMN IF NOT EXISTS address TEXT;
ALTER TABLE vendor_profiles ADD COLUMN IF NOT EXISTS branch_count INTEGER DEFAULT 1;

-- =============================================================================
-- 4. VENDOR_BRANCHES
-- =============================================================================
CREATE TABLE IF NOT EXISTS vendor_branches (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  vendor_profile_id UUID NOT NULL REFERENCES vendor_profiles(id) ON DELETE CASCADE,
  subcity_id UUID REFERENCES subcities(id) ON DELETE SET NULL,
  address_detail VARCHAR(500),
  sort_order INTEGER NOT NULL DEFAULT 0,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_vendor_branches_profile ON vendor_branches(vendor_profile_id);

-- =============================================================================
-- 5. DEALS: subcity for filtering
-- =============================================================================
ALTER TABLE deals ADD COLUMN IF NOT EXISTS subcity_id UUID REFERENCES subcities(id) ON DELETE SET NULL;
CREATE INDEX IF NOT EXISTS idx_deals_subcity_id ON deals(subcity_id);

-- =============================================================================
-- 6. REVIEWS: attach to deal + customer + vendor for listing & notifications
-- =============================================================================
ALTER TABLE reviews ADD COLUMN IF NOT EXISTS deal_id UUID REFERENCES deals(id) ON DELETE CASCADE;
ALTER TABLE reviews ADD COLUMN IF NOT EXISTS user_id UUID REFERENCES users(id) ON DELETE SET NULL;
ALTER TABLE reviews ADD COLUMN IF NOT EXISTS vendor_id UUID REFERENCES users(id) ON DELETE CASCADE;

UPDATE reviews r
SET deal_id = o.deal_id, user_id = o.user_id
FROM orders o
WHERE r.order_id = o.id AND (r.deal_id IS NULL OR r.user_id IS NULL);

UPDATE reviews r
SET vendor_id = d.vendor_id
FROM deals d
WHERE r.deal_id = d.id AND r.vendor_id IS NULL;

-- =============================================================================
-- 7. VENDOR_NOTIFICATIONS
-- =============================================================================
CREATE TABLE IF NOT EXISTS vendor_notifications (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  vendor_user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  type VARCHAR(32) NOT NULL,
  title VARCHAR(255) NOT NULL,
  body TEXT,
  metadata JSONB,
  read_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_vendor_notifications_vendor ON vendor_notifications(vendor_user_id);
CREATE INDEX IF NOT EXISTS idx_vendor_notifications_unread ON vendor_notifications(vendor_user_id) WHERE read_at IS NULL;
