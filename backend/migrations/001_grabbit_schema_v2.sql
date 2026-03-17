-- Grabbit Schema v2 Migration
-- Run against existing PostgreSQL DB. Back up data first.
-- Ensures: User (email/phone unique), CustomerProfile & VendorProfile 1:1, Location, Deal (Location + checks), Order (claim_code), Payment, Review.

-- =============================================================================
-- 1. USERS: Add phone UNIQUE, rename password -> password_hash (keep full_name, is_verified, otp fields)
-- =============================================================================
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'users' AND column_name = 'password') THEN
    ALTER TABLE users RENAME COLUMN password TO password_hash;
  END IF;
EXCEPTION WHEN OTHERS THEN NULL;
END $$;

-- Email unique is typically already from Sequelize
DO $$ BEGIN IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'users_email_key') THEN ALTER TABLE users ADD CONSTRAINT users_email_key UNIQUE (email); END IF; END $$;
-- Phone unique (multiple NULLs allowed)
CREATE UNIQUE INDEX IF NOT EXISTS users_phone_key ON users (phone) WHERE phone IS NOT NULL;

-- =============================================================================
-- 2. CUSTOMER_PROFILES: 1:1 with User
-- =============================================================================
CREATE TABLE IF NOT EXISTS customer_profiles (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL UNIQUE REFERENCES users(id) ON DELETE RESTRICT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_customer_profiles_user_id ON customer_profiles(user_id);

-- =============================================================================
-- 3. VENDOR_PROFILES: Add TIN (UNIQUE)
-- =============================================================================
ALTER TABLE vendor_profiles ADD COLUMN IF NOT EXISTS tin VARCHAR(50);
CREATE UNIQUE INDEX IF NOT EXISTS vendor_profiles_tin_key ON vendor_profiles(tin) WHERE tin IS NOT NULL;
-- Ensure user_id FK exists (already in Sequelize)
-- ON DELETE: keep CASCADE for vendor_profile when user is deleted, or RESTRICT per spec; spec says "transaction-related" RESTRICT, so User delete can CASCADE vendor_profile

-- =============================================================================
-- 4. LOCATIONS: Standalone, multiple per vendor
-- =============================================================================
CREATE TABLE IF NOT EXISTS locations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  vendor_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  lat DECIMAL(10, 8),
  long DECIMAL(11, 8),
  address VARCHAR(500),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_locations_vendor_id ON locations(vendor_id);

-- =============================================================================
-- 5. DEALS: Link to Vendor + Location; add total_quantity, start_time; rename columns and add CHECKs
-- =============================================================================
-- Add new columns if not present
ALTER TABLE deals ADD COLUMN IF NOT EXISTS location_id UUID REFERENCES locations(id) ON DELETE SET NULL;
ALTER TABLE deals ADD COLUMN IF NOT EXISTS total_quantity INTEGER;
ALTER TABLE deals ADD COLUMN IF NOT EXISTS start_time TIMESTAMPTZ;
ALTER TABLE deals ADD COLUMN IF NOT EXISTS discount_price DECIMAL(10,2);
ALTER TABLE deals ADD COLUMN IF NOT EXISTS available_quantity INTEGER;
ALTER TABLE deals ADD COLUMN IF NOT EXISTS expiry_time TIMESTAMPTZ;

-- Backfill from existing column names (run once)
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'deals' AND column_name = 'discounted_price') THEN
    UPDATE deals SET discount_price = discounted_price WHERE discount_price IS NULL;
  END IF;
  IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'deals' AND column_name = 'quantity_available') THEN
    UPDATE deals SET available_quantity = quantity_available WHERE available_quantity IS NULL;
    UPDATE deals SET total_quantity = COALESCE(total_quantity, quantity_available) WHERE total_quantity IS NULL;
  END IF;
  IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'deals' AND column_name = 'expiry_date') THEN
    UPDATE deals SET expiry_time = expiry_date WHERE expiry_time IS NULL;
  END IF;
  IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'deals' AND column_name = 'created_at') THEN
    UPDATE deals SET start_time = created_at WHERE start_time IS NULL;
  END IF;
END $$;

-- Drop old columns only after backfill (optional; comment out to keep both during transition)
-- ALTER TABLE deals DROP COLUMN IF EXISTS discounted_price;
-- ALTER TABLE deals DROP COLUMN IF EXISTS quantity_available;
-- ALTER TABLE deals DROP COLUMN IF EXISTS expiry_date;

-- Ensure NOT NULL and defaults for new schema
ALTER TABLE deals ALTER COLUMN total_quantity SET DEFAULT 0;
ALTER TABLE deals ALTER COLUMN available_quantity SET DEFAULT 0;
UPDATE deals SET total_quantity = COALESCE(total_quantity, 0), available_quantity = COALESCE(available_quantity, 0), discount_price = COALESCE(discount_price, discounted_price, 0), expiry_time = COALESCE(expiry_time, expiry_date, created_at), start_time = COALESCE(start_time, created_at) WHERE total_quantity IS NULL OR available_quantity IS NULL OR discount_price IS NULL OR expiry_time IS NULL OR start_time IS NULL;

-- CHECK constraints (after backfill, discount_price is set)
ALTER TABLE deals DROP CONSTRAINT IF EXISTS chk_discount_lt_original;
ALTER TABLE deals ADD CONSTRAINT chk_discount_lt_original CHECK (
  (COALESCE(discount_price, discounted_price) < original_price)
);

ALTER TABLE deals DROP CONSTRAINT IF EXISTS chk_available_lte_total;
ALTER TABLE deals ADD CONSTRAINT chk_available_lte_total CHECK (total_quantity IS NULL OR available_quantity IS NULL OR (available_quantity <= total_quantity));

ALTER TABLE deals DROP CONSTRAINT IF EXISTS chk_expiry_after_start;
ALTER TABLE deals ADD CONSTRAINT chk_expiry_after_start CHECK (start_time IS NULL OR expiry_time IS NULL OR (expiry_time > start_time));

CREATE INDEX IF NOT EXISTS idx_deals_location_id ON deals(location_id);
CREATE INDEX IF NOT EXISTS idx_deals_vendor_id ON deals(vendor_id);

-- =============================================================================
-- 6. ORDERS: Add unique claim_code; RESTRICT on FKs for safety
-- =============================================================================
ALTER TABLE orders ADD COLUMN IF NOT EXISTS claim_code VARCHAR(64);
-- Generate unique claim_codes for existing rows (one update per row for uniqueness)
DO $$
DECLARE r RECORD; c TEXT;
BEGIN
  FOR r IN SELECT id FROM orders WHERE claim_code IS NULL OR claim_code = ''
  LOOP
    c := UPPER(SUBSTRING(MD5(RANDOM()::TEXT || r.id::TEXT || CLOCK_TIMESTAMP()::TEXT) FROM 1 FOR 12));
    UPDATE orders SET claim_code = c WHERE id = r.id;
  END LOOP;
END $$;
-- Ensure uniqueness
CREATE UNIQUE INDEX IF NOT EXISTS orders_claim_code_key ON orders(claim_code) WHERE claim_code IS NOT NULL AND claim_code != '';

-- Drop existing FKs and re-add with RESTRICT (optional; uncomment if you want RESTRICT)
-- ALTER TABLE orders DROP CONSTRAINT IF EXISTS orders_user_id_fkey;
-- ALTER TABLE orders ADD CONSTRAINT orders_user_id_fkey FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE RESTRICT;
-- ALTER TABLE orders DROP CONSTRAINT IF EXISTS orders_deal_id_fkey;
-- ALTER TABLE orders ADD CONSTRAINT orders_deal_id_fkey FOREIGN KEY (deal_id) REFERENCES deals(id) ON DELETE RESTRICT;

-- =============================================================================
-- 7. PAYMENTS: 1:1 with Order
-- =============================================================================
CREATE TABLE IF NOT EXISTS payments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  order_id UUID NOT NULL UNIQUE REFERENCES orders(id) ON DELETE RESTRICT,
  gateway_provider VARCHAR(50) NOT NULL,
  transaction_reference VARCHAR(255) NOT NULL UNIQUE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_payments_order_id ON payments(order_id);

-- =============================================================================
-- 8. REVIEWS: 1:1 with Order
-- =============================================================================
CREATE TABLE IF NOT EXISTS reviews (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  order_id UUID NOT NULL UNIQUE REFERENCES orders(id) ON DELETE RESTRICT,
  rating SMALLINT NOT NULL,
  comment TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CONSTRAINT chk_review_rating CHECK (rating BETWEEN 1 AND 5)
);

CREATE INDEX IF NOT EXISTS idx_reviews_order_id ON reviews(order_id);

-- =============================================================================
-- Optional: fix PostgreSQL syntax (IF NOT EXISTS for ADD CONSTRAINT not in all PG versions)
-- =============================================================================
-- If your PostgreSQL version does not support "ADD CONSTRAINT ... IF NOT EXISTS", run constraints manually and ignore errors for existing ones.
