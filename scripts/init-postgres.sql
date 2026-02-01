-- ============================================================
-- PostgreSQL Initialization for Iceberg JDBC Catalog
-- ============================================================
-- This script initializes the PostgreSQL database for Iceberg
-- metadata storage via direct JDBC connection.
--
-- The JDBC Catalog will automatically create and manage the
-- necessary metadata tables, so this script only needs to:
-- 1. Create the database (already done by docker-compose)
-- 2. Set up the user and permissions
-- 3. Create any application-specific schemas if needed
--

-- ============================================================
-- Permissions Setup
-- ============================================================

-- Grant permissions to iceberg user
GRANT CONNECT ON DATABASE iceberg TO iceberg;
GRANT USAGE ON SCHEMA public TO iceberg;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO iceberg;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO iceberg;
GRANT ALL PRIVILEGES ON ALL FUNCTIONS IN SCHEMA public TO iceberg;

-- Set default privileges for future objects
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO iceberg;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON SEQUENCES TO iceberg;

-- ============================================================
-- Optional: Create Additional Schemas
-- ============================================================

-- Create an application schema if desired
-- CREATE SCHEMA IF NOT EXISTS app_schema AUTHORIZATION iceberg;
-- GRANT ALL ON SCHEMA app_schema TO iceberg;

-- ============================================================
-- Notes for Users
-- ============================================================

-- The JDBC Catalog will automatically create the following tables:
-- - iceberg_namespace_properties
-- - iceberg_namespaces
-- - iceberg_table_properties
-- - iceberg_tables
-- - iceberg_view_versions
-- - iceberg_views
-- - iceberg_v2_compatible_metadata
--
-- No manual table creation is needed!
-- Simply use Spark SQL to create databases and tables:
--
-- > CREATE DATABASE my_database;
-- > USE my_database;
-- > CREATE TABLE my_table (id INT, name STRING) USING iceberg;
--
-- Metadata will be automatically stored in PostgreSQL.
