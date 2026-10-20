\set ON_ERROR_STOP on

-- SehatMarkaz application schema
-- Version: 0.2
-- Run after db/setup_postgres.sql:
--   psql -U dev -d sehatmarkaz
--   \i db/sehatmarkaz_schema.sql

BEGIN;

CREATE TABLE user_types (
    id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name VARCHAR(50) NOT NULL UNIQUE,
    description VARCHAR(255),
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE users (
    id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    user_type_id INTEGER NOT NULL REFERENCES user_types(id),
    full_name VARCHAR(120) NOT NULL,
    email VARCHAR(255) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    last_login_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE cities (
    id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    slug VARCHAR(120) NOT NULL UNIQUE,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE areas (
    id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    city_id INTEGER NOT NULL REFERENCES cities(id),
    name VARCHAR(120) NOT NULL,
    slug VARCHAR(140) NOT NULL,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_areas_city_slug UNIQUE (city_id, slug)
);

CREATE TABLE pharmacies (
    id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    area_id INTEGER NOT NULL REFERENCES areas(id),
    name VARCHAR(160) NOT NULL,
    slug VARCHAR(180) NOT NULL UNIQUE,
    address TEXT NOT NULL,
    home_delivery_status VARCHAR(20) NOT NULL DEFAULT 'unknown',
    description TEXT,
    maps_url TEXT,
    is_featured BOOLEAN NOT NULL DEFAULT FALSE,
    is_published BOOLEAN NOT NULL DEFAULT FALSE,
    last_verified_at TIMESTAMPTZ,
    created_by_user_id INTEGER NOT NULL REFERENCES users(id),
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT chk_pharmacy_delivery_status
        CHECK (home_delivery_status IN ('yes', 'no', 'unknown'))
);

CREATE TABLE equipment_suppliers (
    id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    area_id INTEGER NOT NULL REFERENCES areas(id),
    name VARCHAR(160) NOT NULL,
    slug VARCHAR(180) NOT NULL UNIQUE,
    address TEXT NOT NULL,
    equipment_summary TEXT,
    description TEXT,
    maps_url TEXT,
    is_featured BOOLEAN NOT NULL DEFAULT FALSE,
    is_published BOOLEAN NOT NULL DEFAULT FALSE,
    last_verified_at TIMESTAMPTZ,
    created_by_user_id INTEGER NOT NULL REFERENCES users(id),
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- business_id contains the id of either a pharmacy or an equipment supplier.
-- The requested simple structure has no business_type column and no common
-- parent table, so PostgreSQL cannot enforce this as a foreign key.
CREATE TABLE contacts (
    id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    business_id INTEGER NOT NULL,
    contact_type VARCHAR(20) NOT NULL,
    contact_value VARCHAR(255) NOT NULL,
    is_verified BOOLEAN NOT NULL DEFAULT FALSE,
    is_primary BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT chk_contact_type
        CHECK (contact_type IN ('phone', 'whatsapp', 'email'))
);

CREATE INDEX idx_pharmacies_area_published_featured
    ON pharmacies (area_id, is_published, is_featured);

CREATE INDEX idx_equipment_suppliers_area_published_featured
    ON equipment_suppliers (area_id, is_published, is_featured);

CREATE INDEX idx_contacts_business_contact_type
    ON contacts (business_id, contact_type);

COMMIT;
