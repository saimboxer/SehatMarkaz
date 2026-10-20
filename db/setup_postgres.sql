\set ON_ERROR_STOP on

-- SehatMarkaz PostgreSQL infrastructure setup (psql script, not plain SQL).
-- Run as an existing PostgreSQL administrator:
--   psql -U postgres -d postgres -f setup_postgres.sql
-- Database: sehatmarkaz | Schema: sm | Database owner: superuser | Schema owner: dev
-- Does not create tables, change existing passwords, or modify other projects.
-- If a new login role is created, set its password securely outside this script.

-- Create roles only if missing. Never reset passwords of existing roles.
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'superuser') THEN
        CREATE ROLE superuser WITH LOGIN SUPERUSER;
        RAISE NOTICE 'Created superuser role without password; set a secure password separately';
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'dev') THEN
        CREATE ROLE dev WITH LOGIN NOSUPERUSER NOCREATEDB NOCREATEROLE NOREPLICATION NOBYPASSRLS;
        RAISE NOTICE 'Created dev role without password; set a secure password separately';
    END IF;
END
$$;

-- Stop if existing roles do not match the intended security policy.
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'superuser' AND rolsuper) THEN
        RAISE EXCEPTION 'Role superuser exists but is not a superuser; review manually';
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'dev'
                   AND rolcanlogin AND NOT rolsuper AND NOT rolcreatedb
                   AND NOT rolcreaterole AND NOT rolbypassrls) THEN
        RAISE EXCEPTION 'Role dev does not match the restricted development-role policy; review manually';
    END IF;
END
$$;

-- CREATE DATABASE cannot be run inside a transaction.
SELECT 'CREATE DATABASE sehatmarkaz OWNER superuser'
WHERE NOT EXISTS (SELECT 1 FROM pg_database WHERE datname = 'sehatmarkaz')
\gexec

ALTER DATABASE sehatmarkaz OWNER TO superuser;
REVOKE ALL ON DATABASE sehatmarkaz FROM PUBLIC;
REVOKE ALL ON DATABASE sehatmarkaz FROM dev;
GRANT CONNECT ON DATABASE sehatmarkaz TO dev;

-- Connect to the project database before managing schemas.
\connect sehatmarkaz

CREATE SCHEMA IF NOT EXISTS sm AUTHORIZATION dev;
ALTER SCHEMA sm OWNER TO dev;
REVOKE ALL ON SCHEMA sm FROM PUBLIC;
GRANT USAGE, CREATE ON SCHEMA sm TO dev;

-- Prevent the public role from creating/using objects in the public schema.
REVOKE ALL ON SCHEMA public FROM PUBLIC;

-- Objects created by the database administrator in sm can be used by dev.
-- Objects created by dev are already owned by dev, so no redundant grants needed.
ALTER DEFAULT PRIVILEGES FOR ROLE superuser IN SCHEMA sm
    GRANT ALL ON TABLES TO dev;
ALTER DEFAULT PRIVILEGES FOR ROLE superuser IN SCHEMA sm
    GRANT ALL ON SEQUENCES TO dev;
ALTER DEFAULT PRIVILEGES FOR ROLE superuser IN SCHEMA sm
    GRANT ALL ON FUNCTIONS TO dev;

-- For existing administrator-created objects, grant privileges too.
GRANT ALL ON ALL TABLES IN SCHEMA sm TO dev;
GRANT ALL ON ALL SEQUENCES IN SCHEMA sm TO dev;
GRANT ALL ON ALL FUNCTIONS IN SCHEMA sm TO dev;

-- dev can query sm tables without a schema prefix, e.g. SELECT * FROM abc;
ALTER ROLE dev IN DATABASE sehatmarkaz SET search_path = sm, pg_catalog;

\echo 'SehatMarkaz setup complete: database=sehatmarkaz, schema=sm, schema_owner=dev.'
\echo 'Reconnect as dev to activate the search_path setting.'
