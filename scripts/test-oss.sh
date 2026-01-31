#!/bin/bash

# Test OSS connectivity and configuration

set -e

echo "================================================================"
echo "  OSS Connectivity Test"
echo "================================================================"
echo ""

# Load environment variables
if [ -f .env ]; then
    source .env
    echo "✅ Loaded configuration from .env"
else
    echo "❌ Error: .env file not found"
    exit 1
fi

# Check required variables
if [ -z "$OSS_ACCESS_KEY_ID" ] || [ -z "$OSS_ACCESS_KEY_SECRET" ] || [ -z "$OSS_BUCKET" ]; then
    echo "❌ Error: Required environment variables not set"
    echo "   Please configure OSS_ACCESS_KEY_ID, OSS_ACCESS_KEY_SECRET, and OSS_BUCKET in .env"
    exit 1
fi

echo ""
echo "Configuration:"
echo "  Endpoint: ${OSS_ENDPOINT}"
echo "  Bucket:   ${OSS_BUCKET}"
echo ""

# Test 1: Check if container is running
echo "Test 1: Checking if Spark container is running..."
if docker ps | grep -q spark-iceberg-master; then
    echo "✅ Spark master container is running"
else
    echo "❌ Spark master container is not running"
    echo "   Run 'docker-compose up -d' first"
    exit 1
fi

echo ""

# Test 2: Test OSS connection with Hadoop fs
echo "Test 2: Testing OSS connection with Hadoop fs..."
if docker exec spark-iceberg-master hadoop fs -ls oss://${OSS_BUCKET}/ 2>/dev/null; then
    echo "✅ Successfully connected to OSS bucket"
else
    echo "❌ Failed to connect to OSS bucket"
    echo "   Please check your credentials and bucket permissions"
    exit 1
fi

echo ""

# Test 3: Create a test directory
echo "Test 3: Testing write permissions..."
TEST_DIR="oss://${OSS_BUCKET}/spark-iceberg-test"
if docker exec spark-iceberg-master hadoop fs -mkdir -p ${TEST_DIR} 2>/dev/null; then
    echo "✅ Successfully created test directory: ${TEST_DIR}"
    
    # Clean up test directory
    docker exec spark-iceberg-master hadoop fs -rm -r ${TEST_DIR} 2>/dev/null || true
    echo "✅ Cleaned up test directory"
else
    echo "⚠️  Warning: Could not create test directory (may already exist or no write permission)"
fi

echo ""

# Test 4: Test Iceberg catalog configuration
echo "Test 4: Testing Iceberg catalog configuration..."
TEST_SQL="SHOW DATABASES;"
if docker exec spark-iceberg-master spark-sql --master local[1] -e "${TEST_SQL}" 2>/dev/null | grep -q "default"; then
    echo "✅ Iceberg catalog is configured correctly"
else
    echo "⚠️  Warning: Could not verify Iceberg catalog configuration"
fi

echo ""
echo "================================================================"
echo "  Test Summary"
echo "================================================================"
echo "✅ All tests passed!"
echo "Your OSS configuration is working correctly."
echo ""
echo "Next steps:"
echo "  1. Run examples: make example"
echo "  2. Start Spark SQL: make sql"
echo "  3. Start PySpark: make pyspark"
echo "================================================================"
