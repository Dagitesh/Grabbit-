-- Grabbit: Admin role, dynamic categories, AppConfig, vendor approval
-- Run after 001_grabbit_schema_v2.sql. Back up DB first.

-- =============================================================================
-- 1. Ensure User role allows ADMIN (if using VARCHAR, no change; if ENUM, extend)
-- =============================================================================
-- User.role is already VARCHAR(20); ensure CHECK or leave as-is.

-- =============================================================================
-- 2. Vendor approval: vendor_profiles.is_approved already exists (default false)
-- =============================================================================
-- No change needed.

-- =============================================================================
-- 3. CATEGORIES table (dynamic explore categories)
-- =============================================================================
CREATE TABLE IF NOT EXISTS categories (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name VARCHAR(100) NOT NULL UNIQUE,
  icon VARCHAR(100) NOT NULL DEFAULT 'category',
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_categories_name ON categories(name);

-- Seed default categories (optional; idempotent by name)
INSERT INTO categories (id, name, icon, created_at, updated_at)
SELECT gen_random_uuid(), 'Bakery', 'bakery_dining', NOW(), NOW()
WHERE NOT EXISTS (SELECT 1 FROM categories WHERE name = 'Bakery');
INSERT INTO categories (id, name, icon, created_at, updated_at)
SELECT gen_random_uuid(), 'Veggies', 'eco', NOW(), NOW()
WHERE NOT EXISTS (SELECT 1 FROM categories WHERE name = 'Veggies');
INSERT INTO categories (id, name, icon, created_at, updated_at)
SELECT gen_random_uuid(), 'Meals', 'restaurant', NOW(), NOW()
WHERE NOT EXISTS (SELECT 1 FROM categories WHERE name = 'Meals');
INSERT INTO categories (id, name, icon, created_at, updated_at)
SELECT gen_random_uuid(), 'Dairy', 'egg_outlined', NOW(), NOW()
WHERE NOT EXISTS (SELECT 1 FROM categories WHERE name = 'Dairy');
INSERT INTO categories (id, name, icon, created_at, updated_at)
SELECT gen_random_uuid(), 'Meat', 'dinner_dining', NOW(), NOW()
WHERE NOT EXISTS (SELECT 1 FROM categories WHERE name = 'Meat');

-- =============================================================================
-- 4. DEALS: add category_id FK to categories
-- =============================================================================
ALTER TABLE deals ADD COLUMN IF NOT EXISTS category_id UUID REFERENCES categories(id) ON DELETE SET NULL;
CREATE INDEX IF NOT EXISTS idx_deals_category_id ON deals(category_id);

-- =============================================================================
-- 5. APP_CONFIG (single-row config: intro image, etc.)
-- =============================================================================
CREATE TABLE IF NOT EXISTS app_config (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  intro_image_url VARCHAR(500),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Single row
INSERT INTO app_config (id, intro_image_url, updated_at)
SELECT gen_random_uuid(), NULL, NOW()
WHERE NOT EXISTS (SELECT 1 FROM app_config LIMIT 1);
