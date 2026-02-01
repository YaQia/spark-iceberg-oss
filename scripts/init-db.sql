-- ============================================================================
-- Iceberg JDBC Catalog Database Initialization Script
-- ============================================================================
-- This script initializes the PostgreSQL database for Iceberg JDBC Catalog
-- It is automatically executed when PostgreSQL container starts
-- ============================================================================

-- Create iceberg_schema to hold all Iceberg metadata tables
-- (PostgreSQL uses schemas like Oracle/SQL Server)
CREATE SCHEMA IF NOT EXISTS iceberg;

-- Grant permissions to iceberg_user
GRANT ALL PRIVILEGES ON SCHEMA iceberg TO iceberg_user;
ALTER DEFAULT PRIVILEGES IN SCHEMA iceberg GRANT ALL ON TABLES TO iceberg_user;
ALTER DEFAULT PRIVILEGES IN SCHEMA iceberg GRANT ALL ON SEQUENCES TO iceberg_user;

-- Enable required extensions
CREATE EXTENSION IF NOT EXISTS uuid-ossp;

-- Create catalog metadata table (required by Iceberg)
-- This table stores information about all catalogs
CREATE TABLE IF NOT EXISTS iceberg.catalog_metadata (
    catalog_name VARCHAR(255) PRIMARY KEY,
    namespace_name VARCHAR(255),
    location TEXT,
    properties JSONB,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create namespace table
CREATE TABLE IF NOT EXISTS iceberg.namespaces (
    namespace_id SERIAL PRIMARY KEY,
    namespace_name VARCHAR(255) UNIQUE NOT NULL,
    catalog_name VARCHAR(255) DEFAULT 'iceberg_catalog',
    properties JSONB,
    location TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (catalog_name) REFERENCES iceberg.catalog_metadata(catalog_name)
);

-- Create table metadata storage
CREATE TABLE IF NOT EXISTS iceberg.tables (
    table_id SERIAL PRIMARY KEY,
    namespace_id INT NOT NULL,
    table_name VARCHAR(255) NOT NULL,
    location TEXT NOT NULL,
    table_uuid UUID DEFAULT uuid_generate_v4() UNIQUE,
    current_schema_id INT,
    current_spec_id INT,
    current_sort_order_id INT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(namespace_id, table_name),
    FOREIGN KEY (namespace_id) REFERENCES iceberg.namespaces(namespace_id) ON DELETE CASCADE
);

-- Create schema versions table (for schema evolution)
CREATE TABLE IF NOT EXISTS iceberg.schemas (
    schema_id SERIAL PRIMARY KEY,
    table_id INT NOT NULL,
    schema_json TEXT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (table_id) REFERENCES iceberg.tables(table_id) ON DELETE CASCADE
);

-- Create partition specs table
CREATE TABLE IF NOT EXISTS iceberg.partition_specs (
    spec_id SERIAL PRIMARY KEY,
    table_id INT NOT NULL,
    spec_json TEXT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (table_id) REFERENCES iceberg.tables(table_id) ON DELETE CASCADE
);

-- Create sort orders table
CREATE TABLE IF NOT EXISTS iceberg.sort_orders (
    sort_order_id SERIAL PRIMARY KEY,
    table_id INT NOT NULL,
    order_json TEXT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (table_id) REFERENCES iceberg.tables(table_id) ON DELETE CASCADE
);

-- Create snapshots table (for time travel support)
CREATE TABLE IF NOT EXISTS iceberg.snapshots (
    snapshot_id BIGINT PRIMARY KEY,
    table_id INT NOT NULL,
    parent_snapshot_id BIGINT,
    schema_id INT,
    timestamp_ms BIGINT NOT NULL,
    manifest_list TEXT NOT NULL,
    summary JSONB,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (table_id) REFERENCES iceberg.tables(table_id) ON DELETE CASCADE,
    FOREIGN KEY (schema_id) REFERENCES iceberg.schemas(schema_id)
);

-- Create metadata files table
CREATE TABLE IF NOT EXISTS iceberg.metadata_files (
    file_id SERIAL PRIMARY KEY,
    table_id INT NOT NULL,
    file_path TEXT NOT NULL,
    file_format VARCHAR(50),
    file_size BIGINT,
    content_hash VARCHAR(64),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (table_id) REFERENCES iceberg.tables(table_id) ON DELETE CASCADE
);

-- Create data files table (optional, for file tracking)
CREATE TABLE IF NOT EXISTS iceberg.data_files (
    file_id SERIAL PRIMARY KEY,
    table_id INT NOT NULL,
    file_path TEXT NOT NULL,
    file_size BIGINT,
    record_count BIGINT,
    file_format VARCHAR(50),
    partition_values JSONB,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (table_id) REFERENCES iceberg.tables(table_id) ON DELETE CASCADE
);

-- Create transactions log table (for audit trail)
CREATE TABLE IF NOT EXISTS iceberg.transaction_log (
    log_id SERIAL PRIMARY KEY,
    table_id INT,
    operation VARCHAR(50) NOT NULL,
    snapshot_id BIGINT,
    user_name VARCHAR(255),
    details JSONB,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create indexes for better query performance
CREATE INDEX IF NOT EXISTS idx_tables_namespace_id ON iceberg.tables(namespace_id);
CREATE INDEX IF NOT EXISTS idx_tables_table_uuid ON iceberg.tables(table_uuid);
CREATE INDEX IF NOT EXISTS idx_schemas_table_id ON iceberg.schemas(table_id);
CREATE INDEX IF NOT EXISTS idx_snapshots_table_id ON iceberg.snapshots(table_id);
CREATE INDEX IF NOT EXISTS idx_snapshots_timestamp ON iceberg.snapshots(timestamp_ms DESC);
CREATE INDEX IF NOT EXISTS idx_metadata_files_table_id ON iceberg.metadata_files(table_id);
CREATE INDEX IF NOT EXISTS idx_data_files_table_id ON iceberg.data_files(table_id);
CREATE INDEX IF NOT EXISTS idx_transaction_log_table_id ON iceberg.transaction_log(table_id);
CREATE INDEX IF NOT EXISTS idx_transaction_log_created_at ON iceberg.transaction_log(created_at DESC);

-- Create view for easy namespace access
CREATE OR REPLACE VIEW iceberg.v_namespaces AS
SELECT 
    namespace_id,
    namespace_name,
    catalog_name,
    location,
    created_at,
    updated_at
FROM iceberg.namespaces;

-- Create view for easy table access
CREATE OR REPLACE VIEW iceberg.v_tables AS
SELECT 
    t.table_id,
    t.table_name,
    n.namespace_name,
    t.location,
    t.table_uuid,
    t.created_at,
    t.updated_at
FROM iceberg.tables t
JOIN iceberg.namespaces n ON t.namespace_id = n.namespace_id;

-- Grant permissions
GRANT USAGE ON SCHEMA iceberg TO iceberg_user;
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA iceberg TO iceberg_user;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA iceberg TO iceberg_user;

-- Insert default catalog record
INSERT INTO iceberg.catalog_metadata (catalog_name, namespace_name, properties)
VALUES ('iceberg_catalog', 'default', '{"type": "jdbc", "warehouse": "oss://warehouse"}')
ON CONFLICT (catalog_name) DO NOTHING;

-- Insert default namespace
INSERT INTO iceberg.namespaces (namespace_name, catalog_name, properties)
VALUES ('default', 'iceberg_catalog', '{"description": "Default namespace"}')
ON CONFLICT (namespace_name) DO NOTHING;

-- Set search path
ALTER ROLE iceberg_user SET search_path TO iceberg, public;

-- ============================================================================
-- End of initialization script
-- ============================================================================
