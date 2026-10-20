\set ON_ERROR_STOP on

-- SehatMarkaz seed and insert data
-- Run after db/sehatmarkaz_schema.sql:
--   psql -U dev -d sehatmarkaz
--   \i db/sehatmarkaz_inserts.sql
--
-- Add data under the matching table heading. Keep sections in this order so
-- all referenced parent records exist before dependent records are inserted.

BEGIN;

-- ================================================================
-- 1. user_types
-- ================================================================
INSERT INTO user_types (name, description)
VALUES
    ('admin', 'Full system and listing management access.'),
    ('moderator', 'Can review and manage directory listings.')
ON CONFLICT (name) DO UPDATE
SET description = EXCLUDED.description;

-- ================================================================
-- 2. users
-- Add internal users here before inserting pharmacies or suppliers.
-- Replace the blank password hash before using this account for real login.
INSERT INTO users (
    user_type_id, full_name, email, password_hash, is_active
)
SELECT
    id, 'Saim Ahmed', 'saim.ahmed92@hotmail.com', '', TRUE
FROM user_types
WHERE name = 'admin'
ON CONFLICT (email) DO NOTHING;
-- ================================================================

-- ================================================================
-- 3. cities
-- ================================================================
INSERT INTO cities (name, slug)
VALUES ('Karachi', 'karachi')
ON CONFLICT (slug) DO UPDATE
SET name = EXCLUDED.name,
    is_active = TRUE;

-- ================================================================
-- 4. areas
-- Karachi launch areas
-- ================================================================
INSERT INTO areas (city_id, name, slug)
SELECT city.id, area.name, area.slug
FROM cities AS city
CROSS JOIN (
    VALUES
        ('North Karachi', 'north-karachi'),
        ('New Karachi', 'new-karachi'),
        ('Surjani Town', 'surjani-town'),
        ('North Nazimabad', 'north-nazimabad'),
        ('Nazimabad', 'nazimabad'),
        ('Buffer Zone', 'buffer-zone'),
        ('Federal B Area', 'federal-b-area'),
        ('Water Pump', 'water-pump'),
        ('Karimabad', 'karimabad'),
        ('Gulshan-e-Iqbal', 'gulshan-e-iqbal'),
        ('Gulistan-e-Johar', 'gulistan-e-johar'),
        ('DHA', 'dha'),
        ('Clifton', 'clifton'),
        ('Saddar', 'saddar'),
        ('M.A. Jinnah Road', 'ma-jinnah-road'),
        ('Garden', 'garden'),
        ('Bahadurabad', 'bahadurabad'),
        ('PECHS', 'pechs'),
        ('Malir', 'malir'),
        ('Model Colony', 'model-colony'),
        ('Shah Faisal Colony', 'shah-faisal-colony'),
        ('Korangi', 'korangi'),
        ('Landhi', 'landhi'),
        ('Orangi Town', 'orangi-town'),
        ('Baldia Town', 'baldia-town'),
        ('Lyari', 'lyari'),
        ('Keamari', 'keamari'),
        ('SITE', 'site'),
        ('Safoora', 'safoora'),
        ('Scheme 33', 'scheme-33')
) AS area(name, slug)
WHERE city.slug = 'karachi'
ON CONFLICT (city_id, slug) DO UPDATE
SET name = EXCLUDED.name,
    is_active = TRUE;

-- ================================================================
-- 5. pharmacies
-- Test data only. Replace with verified real business information later.
-- ================================================================
INSERT INTO pharmacies (
    area_id, name, slug, address, home_delivery_status, description,
    maps_url, is_featured, is_published, created_by_user_id
)
SELECT
    area.id,
    'Demo Pharmacy - Gulistan-e-Johar',
    'demo-pharmacy-gulistan-e-johar',
    'Test Address, Gulistan-e-Johar, Karachi',
    'unknown',
    'Test pharmacy record for development only.',
    NULL,
    TRUE,
    TRUE,
    app_user.id
FROM areas AS area
JOIN cities AS city ON city.id = area.city_id
JOIN users AS app_user ON app_user.email = 'saim.ahmed92@hotmail.com'
WHERE city.slug = 'karachi'
  AND area.slug = 'gulistan-e-johar'
ON CONFLICT (slug) DO UPDATE
SET name = EXCLUDED.name,
    address = EXCLUDED.address,
    home_delivery_status = EXCLUDED.home_delivery_status,
    description = EXCLUDED.description,
    is_featured = EXCLUDED.is_featured,
    is_published = EXCLUDED.is_published,
    updated_at = CURRENT_TIMESTAMP;

-- ================================================================
-- 6. equipment_suppliers
-- Test data only. Replace with verified real business information later.
-- ================================================================
INSERT INTO equipment_suppliers (
    area_id, name, slug, address, equipment_summary, description,
    maps_url, is_featured, is_published, created_by_user_id
)
SELECT
    area.id,
    'Demo Medical Equipment Rentals',
    'demo-medical-equipment-rentals',
    'Test Address, DHA, Karachi',
    'Test hospital beds and wheelchairs.',
    'Test equipment-supplier record for development only.',
    NULL,
    TRUE,
    TRUE,
    app_user.id
FROM areas AS area
JOIN cities AS city ON city.id = area.city_id
JOIN users AS app_user ON app_user.email = 'saim.ahmed92@hotmail.com'
WHERE city.slug = 'karachi'
  AND area.slug = 'dha'
ON CONFLICT (slug) DO UPDATE
SET name = EXCLUDED.name,
    address = EXCLUDED.address,
    equipment_summary = EXCLUDED.equipment_summary,
    description = EXCLUDED.description,
    is_featured = EXCLUDED.is_featured,
    is_published = EXCLUDED.is_published,
    updated_at = CURRENT_TIMESTAMP;

-- ================================================================
-- 7. contacts
-- Test contacts for the demo pharmacy only.
-- ================================================================
INSERT INTO contacts (
    business_id, contact_type, contact_value, is_verified, is_primary
)
SELECT
    pharmacy.id, 'phone', '+920000000001', TRUE, TRUE
FROM pharmacies AS pharmacy
WHERE pharmacy.slug = 'demo-pharmacy-gulistan-e-johar'
  AND NOT EXISTS (
      SELECT 1 FROM contacts
      WHERE business_id = pharmacy.id
        AND contact_type = 'phone'
        AND contact_value = '+920000000001'
  );

INSERT INTO contacts (
    business_id, contact_type, contact_value, is_verified, is_primary
)
SELECT
    pharmacy.id, 'whatsapp', '+920000000002', TRUE, TRUE
FROM pharmacies AS pharmacy
WHERE pharmacy.slug = 'demo-pharmacy-gulistan-e-johar'
  AND NOT EXISTS (
      SELECT 1 FROM contacts
      WHERE business_id = pharmacy.id
        AND contact_type = 'whatsapp'
        AND contact_value = '+920000000002'
  );

COMMIT;
