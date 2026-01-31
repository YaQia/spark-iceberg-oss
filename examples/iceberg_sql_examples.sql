-- Spark SQL Example for Iceberg with Aliyun OSS
-- This script demonstrates common Iceberg operations using Spark SQL

-- ============================================================================
-- 1. Database Operations
-- ============================================================================

-- Create database
CREATE DATABASE IF NOT EXISTS company
COMMENT 'Company database using Iceberg and OSS storage'
LOCATION 'oss://your-bucket/warehouse/company.db';

-- Use the database
USE company;

-- Show all databases
SHOW DATABASES;

-- ============================================================================
-- 2. Table Creation
-- ============================================================================

-- Create a partitioned Iceberg table
CREATE TABLE IF NOT EXISTS employees (
    employee_id BIGINT,
    first_name STRING,
    last_name STRING,
    department STRING,
    salary DECIMAL(10,2),
    hire_date DATE,
    email STRING
) USING iceberg
PARTITIONED BY (department)
TBLPROPERTIES (
    'write.format.default' = 'parquet',
    'write.parquet.compression-codec' = 'snappy'
);

-- Create another table with bucket partitioning
CREATE TABLE IF NOT EXISTS transactions (
    transaction_id BIGINT,
    customer_id BIGINT,
    amount DECIMAL(10,2),
    transaction_date TIMESTAMP,
    status STRING
) USING iceberg
PARTITIONED BY (bucket(10, customer_id), days(transaction_date));

-- ============================================================================
-- 3. Data Insertion
-- ============================================================================

-- Insert sample employee data
INSERT INTO employees VALUES
(1, 'John', 'Doe', 'Engineering', 80000.00, CAST('2020-01-15' AS DATE), 'john.doe@company.com'),
(2, 'Jane', 'Smith', 'Engineering', 85000.00, CAST('2019-03-20' AS DATE), 'jane.smith@company.com'),
(3, 'Bob', 'Johnson', 'Sales', 70000.00, CAST('2021-06-10' AS DATE), 'bob.johnson@company.com'),
(4, 'Alice', 'Williams', 'Marketing', 75000.00, CAST('2020-09-05' AS DATE), 'alice.williams@company.com'),
(5, 'Charlie', 'Brown', 'Engineering', 90000.00, CAST('2018-11-30' AS DATE), 'charlie.brown@company.com');

-- Insert transaction data
INSERT INTO transactions VALUES
(1001, 101, 250.50, current_timestamp(), 'completed'),
(1002, 102, 1500.75, current_timestamp(), 'completed'),
(1003, 103, 99.99, current_timestamp(), 'pending'),
(1004, 101, 320.00, current_timestamp(), 'completed');

-- ============================================================================
-- 4. Query Operations
-- ============================================================================

-- Simple select
SELECT * FROM employees ORDER BY employee_id;

-- Aggregation queries
SELECT 
    department,
    COUNT(*) as employee_count,
    AVG(salary) as avg_salary,
    MAX(salary) as max_salary
FROM employees
GROUP BY department
ORDER BY avg_salary DESC;

-- Join operation
SELECT 
    e.first_name,
    e.last_name,
    e.department,
    COUNT(t.transaction_id) as transaction_count,
    SUM(t.amount) as total_amount
FROM employees e
LEFT JOIN transactions t ON e.employee_id = t.customer_id
GROUP BY e.first_name, e.last_name, e.department;

-- ============================================================================
-- 5. Update and Delete Operations
-- ============================================================================

-- Update records
UPDATE employees 
SET salary = salary * 1.1 
WHERE department = 'Engineering' AND salary < 85000;

-- Delete records
DELETE FROM transactions WHERE status = 'cancelled';

-- ============================================================================
-- 6. Merge (Upsert) Operation
-- ============================================================================

-- Create a staging table
CREATE TEMPORARY VIEW new_employees AS
SELECT * FROM VALUES
(6, 'David', 'Lee', 'Sales', 72000.00, CAST('2023-01-15' AS DATE), 'david.lee@company.com'),
(1, 'John', 'Doe', 'Engineering', 82000.00, CAST('2020-01-15' AS DATE), 'john.doe@company.com')
AS new_employees(employee_id, first_name, last_name, department, salary, hire_date, email);

-- Perform merge operation
MERGE INTO employees t
USING new_employees s
ON t.employee_id = s.employee_id
WHEN MATCHED THEN 
    UPDATE SET 
        t.first_name = s.first_name,
        t.last_name = s.last_name,
        t.department = s.department,
        t.salary = s.salary,
        t.hire_date = s.hire_date,
        t.email = s.email
WHEN NOT MATCHED THEN 
    INSERT (employee_id, first_name, last_name, department, salary, hire_date, email)
    VALUES (s.employee_id, s.first_name, s.last_name, s.department, s.salary, s.hire_date, s.email);

-- ============================================================================
-- 7. Time Travel Queries
-- ============================================================================

-- Query table as of a specific snapshot
-- SELECT * FROM employees VERSION AS OF <snapshot_id>;

-- Query table as of a specific timestamp
-- SELECT * FROM employees TIMESTAMP AS OF '2024-01-01 00:00:00';

-- View table history
SELECT * FROM iceberg_catalog.company.employees.history;

-- View table snapshots
SELECT * FROM iceberg_catalog.company.employees.snapshots;

-- View table metadata
SELECT * FROM iceberg_catalog.company.employees.files;

-- ============================================================================
-- 8. Schema Evolution
-- ============================================================================

-- Add new column
ALTER TABLE employees ADD COLUMN phone_number STRING;

-- Rename column
ALTER TABLE employees RENAME COLUMN phone_number TO contact_number;

-- Drop column
ALTER TABLE employees DROP COLUMN contact_number;

-- ============================================================================
-- 9. Table Maintenance
-- ============================================================================

-- Expire old snapshots (keep snapshots from last 7 days)
CALL iceberg_catalog.system.expire_snapshots(
    table => 'company.employees',
    older_than => TIMESTAMP '2024-01-01 00:00:00',
    retain_last => 5
);

-- Remove orphan files
CALL iceberg_catalog.system.remove_orphan_files(
    table => 'company.employees'
);

-- Rewrite data files to optimize table
CALL iceberg_catalog.system.rewrite_data_files(
    table => 'company.employees'
);

-- ============================================================================
-- 10. Table Properties
-- ============================================================================

-- Show table properties
SHOW TBLPROPERTIES employees;

-- Set table properties
ALTER TABLE employees SET TBLPROPERTIES (
    'write.parquet.compression-codec' = 'gzip',
    'commit.retry.num-retries' = '5'
);

-- ============================================================================
-- Cleanup (Optional)
-- ============================================================================

-- Drop tables
-- DROP TABLE IF EXISTS transactions;
-- DROP TABLE IF EXISTS employees;

-- Drop database
-- DROP DATABASE IF EXISTS company CASCADE;
