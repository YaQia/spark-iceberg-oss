# Spark + Iceberg + Aliyun OSS

[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](https://opensource.org/licenses/Apache-2.0)
[![Spark](https://img.shields.io/badge/Spark-3.5.5-orange.svg)](https://spark.apache.org/)
[![Iceberg](https://img.shields.io/badge/Iceberg-1.8.1-blue.svg)](https://iceberg.apache.org/)

A production-ready Docker image integrating Apache Spark with Apache Iceberg and Alibaba Cloud OSS (Object Storage Service) support. This project provides a complete solution for running Spark workloads with Iceberg table format on Aliyun OSS.

📖 **[简体中文](README_CN.md)** | **[FAQ](FAQ.md)** | **[Contributing](CONTRIBUTING.md)** | **[Versions](VERSIONS.md)**

## 🌟 Features

- **Official Apache Spark 3.5.5** base image with Scala 2.12, Java 11, and Python 3
- **Latest Apache Iceberg 1.8.1** runtime for modern table format capabilities
- **Full Aliyun OSS Integration** with hadoop-aliyun and aliyun-sdk-oss
- **Docker Compose** setup for easy local development and testing
- **Comprehensive Examples** in both PySpark and Spark SQL
- **Production-Ready Configuration** with best practices

## 📋 Prerequisites

- Docker (20.10+)
- Docker Compose (1.29+)
- Aliyun OSS Account with Access Key and Secret

## 🚀 Quick Start

### Option 1: Automated Setup (Recommended)

```bash
# Clone and run the quick start script
git clone https://github.com/YaQia/spark-iceberg-oss.git
cd spark-iceberg-oss
./quick-start.sh
```

The script will guide you through the setup process.

### Option 2: Manual Setup

### 1. Clone the Repository

```bash
git clone https://github.com/YaQia/spark-iceberg-oss.git
cd spark-iceberg-oss
```

### 2. Configure OSS Credentials

Create a `.env` file in the project root:

```bash
cat > .env << EOF
OSS_ACCESS_KEY_ID=your_access_key_id
OSS_ACCESS_KEY_SECRET=your_access_key_secret
OSS_ENDPOINT=oss-cn-hangzhou.aliyuncs.com
OSS_BUCKET=your-bucket-name
EOF
```

**Important:** Make sure to update `conf/spark-defaults.conf` with your OSS credentials and bucket information.

### 3. Build and Start

```bash
# Using Make (recommended)
make build
make up

# Or using Docker Compose directly
docker build -t spark-iceberg-oss:latest .
docker-compose up -d
```

This will start:
- Spark Master (Web UI: http://localhost:8080)
- Spark Worker (Web UI: http://localhost:8081)

### 4. Test OSS Connectivity

```bash
./scripts/test-oss.sh
```

### 5. Run Examples

#### PySpark Example

```bash
# Using Make
make example

# Or directly
docker exec -it spark-iceberg-master \
    spark-submit \
    --master spark://spark-master:7077 \
    /opt/spark/examples/iceberg_oss_example.py
```

#### Spark SQL Example

```bash
# Start Spark SQL shell
docker exec -it spark-iceberg-master \
    spark-sql \
    --master spark://spark-master:7077
```

Then paste SQL commands from `examples/iceberg_sql_examples.sql`.

## 📚 Architecture

### Components

```
┌─────────────────────────────────────────────────────────────┐
│                     Apache Spark 3.5.5                      │
│  ┌───────────────────────────────────────────────────────┐  │
│  │           Apache Iceberg 1.8.1 Runtime                │  │
│  │  ┌─────────────────────────────────────────────────┐  │  │
│  │  │         Hadoop Aliyun OSS Connector            │  │  │
│  │  │  ┌───────────────────────────────────────────┐  │  │  │
│  │  │  │      Aliyun OSS SDK 3.18.5                │  │  │  │
│  │  │  └───────────────────────────────────────────┘  │  │  │
│  │  └─────────────────────────────────────────────────┘  │  │
│  └───────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
                            │
                            ▼
                ┌───────────────────────┐
                │   Aliyun OSS Storage  │
                │   oss://bucket/path   │
                └───────────────────────┘
```

### Dependencies

| Component | Version | Purpose |
|-----------|---------|---------|
| Apache Spark | 3.5.5 | Distributed computing engine |
| Apache Iceberg | 1.8.1 | Table format for huge analytic datasets |
| Hadoop Aliyun | 3.3.4 | OSS FileSystem implementation |
| Aliyun SDK OSS | 3.18.5 | Aliyun OSS client library |
| JDOM2 | 2.0.6.1 | XML processing (OSS dependency) |

## 🔧 Configuration

### Spark Configuration (`conf/spark-defaults.conf`)

Key configurations for Iceberg and OSS:

```properties
# Iceberg Catalog
spark.sql.catalog.iceberg_catalog=org.apache.iceberg.spark.SparkCatalog
spark.sql.catalog.iceberg_catalog.type=hadoop
spark.sql.catalog.iceberg_catalog.warehouse=oss://your-bucket/warehouse

# OSS Access
spark.hadoop.fs.oss.endpoint=oss-cn-hangzhou.aliyuncs.com
spark.hadoop.fs.oss.accessKeyId=YOUR_ACCESS_KEY_ID
spark.hadoop.fs.oss.accessKeySecret=YOUR_ACCESS_KEY_SECRET
spark.hadoop.fs.oss.impl=org.apache.hadoop.fs.aliyun.oss.AliyunOSSFileSystem

# Iceberg Extensions
spark.sql.extensions=org.apache.iceberg.spark.extensions.IcebergSparkSessionExtensions
```

### Environment Variables

You can override configuration using environment variables:

- `OSS_ENDPOINT`: OSS endpoint URL (default: oss-cn-hangzhou.aliyuncs.com)
- `OSS_ACCESS_KEY_ID`: Your Aliyun Access Key ID
- `OSS_ACCESS_KEY_SECRET`: Your Aliyun Access Key Secret
- `OSS_BUCKET`: OSS bucket name for data storage

## 📖 Usage Examples

### Creating an Iceberg Table

```python
from pyspark.sql import SparkSession

spark = SparkSession.builder \
    .appName("IcebergExample") \
    .getOrCreate()

# Create database
spark.sql("CREATE DATABASE IF NOT EXISTS mydb")

# Create partitioned table
spark.sql("""
    CREATE TABLE mydb.users (
        id BIGINT,
        name STRING,
        age INT,
        created_at TIMESTAMP
    ) USING iceberg
    PARTITIONED BY (days(created_at))
""")

# Insert data
spark.sql("""
    INSERT INTO mydb.users VALUES
    (1, 'Alice', 30, current_timestamp()),
    (2, 'Bob', 25, current_timestamp())
""")

# Query data
spark.sql("SELECT * FROM mydb.users").show()
```

### Time Travel

```sql
-- Query historical data
SELECT * FROM mydb.users TIMESTAMP AS OF '2024-01-01 00:00:00';

-- Query by snapshot ID
SELECT * FROM mydb.users VERSION AS OF 1234567890;

-- View table history
SELECT * FROM mydb.users.history;
```

### Schema Evolution

```sql
-- Add column
ALTER TABLE mydb.users ADD COLUMN email STRING;

-- Rename column
ALTER TABLE mydb.users RENAME COLUMN email TO contact_email;

-- Drop column
ALTER TABLE mydb.users DROP COLUMN contact_email;
```

### MERGE (Upsert) Operations

```sql
MERGE INTO target_table t
USING source_table s
ON t.id = s.id
WHEN MATCHED THEN UPDATE SET *
WHEN NOT MATCHED THEN INSERT *;
```

## 🛠️ Advanced Usage

### Custom Spark Submit

```bash
spark-submit \
    --master spark://spark-master:7077 \
    --conf spark.sql.catalog.iceberg_catalog=org.apache.iceberg.spark.SparkCatalog \
    --conf spark.sql.catalog.iceberg_catalog.warehouse=oss://your-bucket/warehouse \
    --conf spark.hadoop.fs.oss.endpoint=oss-cn-hangzhou.aliyuncs.com \
    --conf spark.hadoop.fs.oss.accessKeyId=YOUR_KEY \
    --conf spark.hadoop.fs.oss.accessKeySecret=YOUR_SECRET \
    your_application.py
```

### Table Maintenance

```sql
-- Expire old snapshots
CALL iceberg_catalog.system.expire_snapshots(
    table => 'mydb.users',
    older_than => TIMESTAMP '2024-01-01 00:00:00',
    retain_last => 5
);

-- Remove orphan files
CALL iceberg_catalog.system.remove_orphan_files(
    table => 'mydb.users'
);

-- Rewrite data files for optimization
CALL iceberg_catalog.system.rewrite_data_files(
    table => 'mydb.users'
);
```

### Using in Kubernetes

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: spark-driver
spec:
  containers:
  - name: spark
    image: spark-iceberg-oss:latest
    env:
    - name: OSS_ACCESS_KEY_ID
      valueFrom:
        secretKeyRef:
          name: oss-credentials
          key: access-key-id
    - name: OSS_ACCESS_KEY_SECRET
      valueFrom:
        secretKeyRef:
          name: oss-credentials
          key: access-key-secret
```

## 🔍 Troubleshooting

### OSS Connection Issues

1. Verify OSS endpoint is correct for your region
2. Check Access Key ID and Secret are valid
3. Ensure bucket exists and you have permissions
4. Test connectivity: `hadoop fs -ls oss://your-bucket/`

### Iceberg Table Issues

1. Check catalog configuration in spark-defaults.conf
2. Verify warehouse path is accessible in OSS
3. Review Spark logs for detailed error messages

### Performance Optimization

- Use appropriate partitioning strategy
- Enable data file compression (Parquet with Snappy/GZIP)
- Regular table maintenance (expire snapshots, compact files)
- Tune Spark memory and executor settings

For more troubleshooting help, see [FAQ.md](FAQ.md).

## 🛠️ Utility Scripts

The project includes several utility scripts in the `scripts/` directory:

### Test OSS Connectivity

```bash
./scripts/test-oss.sh
```

Tests OSS connection and verifies configuration.

### Monitor Cluster

```bash
./scripts/monitor.sh
```

Displays cluster status, resource usage, and recent logs.

### Backup/Restore Metadata

```bash
# Backup a database
./scripts/backup.sh backup mydb

# Restore a database
./scripts/backup.sh restore mydb

# List available backups
./scripts/backup.sh list
```

### Make Commands

Use the Makefile for convenient operations:

```bash
make help      # Show all available commands
make build     # Build Docker image
make up        # Start cluster
make down      # Stop cluster
make logs      # View logs
make shell     # Open bash shell
make sql       # Start Spark SQL
make pyspark   # Start PySpark
make example   # Run example
make clean     # Clean up
```

## 📦 What's Included

```
spark-iceberg-oss/
├── Dockerfile                          # Main Docker image definition
├── docker-compose.yml                  # Multi-container setup
├── Makefile                           # Convenient command shortcuts
├── quick-start.sh                     # Automated setup script
├── .env.template                      # Environment variables template
├── conf/
│   └── spark-defaults.conf            # Spark configuration
├── examples/
│   ├── iceberg_oss_example.py         # PySpark example
│   ├── iceberg_sql_examples.sql       # SQL examples
│   └── run_example.sh                 # Example execution script
├── scripts/
│   ├── test-oss.sh                    # OSS connectivity test
│   ├── monitor.sh                     # Cluster monitoring
│   └── backup.sh                      # Backup/restore utility
├── docs/
│   ├── README_CN.md                   # Chinese documentation
│   ├── FAQ.md                         # Frequently asked questions
│   ├── CONTRIBUTING.md                # Contribution guidelines
│   └── VERSIONS.md                    # Component versions
├── .gitignore                         # Git ignore rules
├── LICENSE                            # Apache 2.0 License
└── README.md                          # This file
```

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## 📝 License

This project is licensed under the Apache License 2.0 - see the [LICENSE](LICENSE) file for details.

## 🔗 References

- [Apache Spark Documentation](https://spark.apache.org/docs/latest/)
- [Apache Iceberg Documentation](https://iceberg.apache.org/docs/latest/)
- [Aliyun OSS Documentation](https://www.alibabacloud.com/help/en/oss/)
- [Hadoop Aliyun Module](https://hadoop.apache.org/docs/stable/hadoop-aliyun/tools/hadoop-aliyun/index.html)

## 📧 Support

For issues and questions:
- Open an issue on GitHub
- Check existing issues and documentation

## ⭐ Star History

If you find this project useful, please consider giving it a star!

---

**Built with ❤️ for the Apache Spark and Iceberg community**
