# Frequently Asked Questions (FAQ)

## General Questions

### Q: What is this project?

A: This is a production-ready Docker image that integrates Apache Spark with Apache Iceberg table format and Alibaba Cloud OSS (Object Storage Service). It provides a complete solution for running distributed data processing workloads with modern table format capabilities on cloud object storage.

### Q: Why use Iceberg?

A: Apache Iceberg provides:
- ACID transactions for data lakes
- Time travel and versioning
- Schema evolution without breaking queries
- Efficient partition management
- Better performance for large-scale analytics

### Q: What are the main benefits of using OSS?

A: Aliyun OSS provides:
- Cost-effective object storage
- High durability (99.9999999999%)
- Scalability without capacity planning
- Integration with Aliyun ecosystem
- Multiple storage tiers for cost optimization

## Setup and Configuration

### Q: Which OSS endpoint should I use?

A: Choose the endpoint closest to your compute resources:
- `oss-cn-hangzhou.aliyuncs.com` - Hangzhou
- `oss-cn-shanghai.aliyuncs.com` - Shanghai
- `oss-cn-beijing.aliyuncs.com` - Beijing
- `oss-cn-shenzhen.aliyuncs.com` - Shenzhen

See [OSS Endpoints](https://www.alibabacloud.com/help/en/oss/user-guide/regions-and-endpoints) for complete list.

### Q: How do I get OSS credentials?

A: 
1. Log in to Aliyun Console
2. Go to AccessKey Management
3. Create a new AccessKey (AccessKeyId and AccessKeySecret)
4. Grant OSS permissions to the AccessKey

### Q: Can I use this without Docker?

A: Yes, but you'll need to:
1. Install Apache Spark 3.5.0
2. Download Iceberg and OSS JARs manually
3. Configure spark-defaults.conf
4. Set up SPARK_HOME and CLASSPATH

Docker simplifies this process significantly.

### Q: How do I change Spark version?

A: Edit the `FROM` line in Dockerfile:
```dockerfile
FROM apache/spark:3.4.0-scala2.12-java11-python3-ubuntu
```

You may need to adjust Iceberg version compatibility.

## Usage Questions

### Q: How do I create my first Iceberg table?

A: Use Spark SQL:
```sql
CREATE TABLE my_table (
    id BIGINT,
    name STRING,
    timestamp TIMESTAMP
) USING iceberg
PARTITIONED BY (days(timestamp));
```

### Q: Can I query existing Parquet files?

A: Yes, you can migrate existing data to Iceberg:
```sql
-- Create Iceberg table from existing Parquet
CREATE TABLE iceberg_table USING iceberg AS
SELECT * FROM parquet.`oss://bucket/path/to/parquet`;
```

### Q: How do I perform time travel queries?

A: Use VERSION AS OF or TIMESTAMP AS OF:
```sql
-- By timestamp
SELECT * FROM my_table TIMESTAMP AS OF '2024-01-01 00:00:00';

-- By snapshot ID
SELECT * FROM my_table VERSION AS OF 1234567890;
```

### Q: How often should I run table maintenance?

A: Recommended schedule:
- **Expire snapshots**: Weekly or monthly
- **Remove orphan files**: After large deletes or updates
- **Compact data files**: When you have many small files

### Q: Can I use this with other storage systems?

A: Yes, Iceberg supports multiple storage backends:
- HDFS
- AWS S3
- Azure Blob Storage
- Google Cloud Storage

You'll need to adjust dependencies and configuration accordingly.

## Performance Questions

### Q: How do I optimize query performance?

A:
1. **Partitioning**: Choose appropriate partition columns
2. **File size**: Target 512MB-1GB files
3. **Compression**: Use Snappy for general use, GZIP for cold data
4. **Metadata caching**: Enable Iceberg metadata caching
5. **Predicate pushdown**: Ensure filters on partition columns

### Q: Why are my queries slow?

A: Common issues:
- Too many small files (run `rewrite_data_files`)
- No partitioning on filter columns
- Network latency to OSS
- Insufficient Spark resources
- Not using partition filters

### Q: How do I reduce storage costs?

A:
1. Use appropriate compression
2. Expire old snapshots regularly
3. Remove orphan files
4. Use OSS lifecycle policies
5. Choose appropriate OSS storage class

## Troubleshooting

### Q: "No FileSystem for scheme: oss" error

A: Ensure:
1. hadoop-aliyun JAR is in Spark classpath
2. aliyun-sdk-oss JAR is present
3. Check `spark.hadoop.fs.oss.impl` configuration

### Q: "403 Forbidden" or authentication errors

A: Check:
1. Access Key ID and Secret are correct
2. AccessKey has OSS permissions
3. Bucket exists and you have access
4. Endpoint matches your bucket's region

### Q: "ClassNotFoundException: org.apache.iceberg..."

A: Verify:
1. Iceberg runtime JAR is in Spark jars directory
2. Check JAR version matches Spark version
3. Restart Spark cluster after adding JARs

### Q: Containers fail to start

A: Check:
1. Docker has enough resources (memory, CPU)
2. Ports 8080, 8081, 4040, 7077 are not in use
3. Review logs: `docker-compose logs`

### Q: How do I debug OSS connectivity?

A: Use the test script:
```bash
./scripts/test-oss.sh
```

Or manually test:
```bash
docker exec spark-iceberg-master hadoop fs -ls oss://your-bucket/
```

## Advanced Questions

### Q: Can I use this in production?

A: Yes, but consider:
1. Use Kubernetes for orchestration
2. Set up monitoring and alerting
3. Configure resource limits properly
4. Implement backup strategies
5. Use managed Spark services for critical workloads

### Q: How do I scale the cluster?

A: With docker-compose:
```bash
docker-compose up --scale spark-worker=3
```

For production, use Kubernetes or managed Spark services.

### Q: Can I integrate with other tools?

A: Yes, Iceberg tables can be accessed by:
- Apache Flink
- Apache Hive
- Presto/Trino
- Dremio
- AWS Athena (for S3)

### Q: How do I upgrade Iceberg version?

A: 
1. Update ICEBERG_VERSION in Dockerfile
2. Rebuild image: `make build`
3. Stop and restart cluster
4. Test with your existing tables

Note: Check Iceberg migration guide for breaking changes.

### Q: Can I use this with Spark Structured Streaming?

A: Yes, Iceberg supports streaming writes:
```python
df.writeStream \
    .format("iceberg") \
    .outputMode("append") \
    .option("path", "oss://bucket/warehouse/table") \
    .start()
```

### Q: How do I handle schema evolution?

A: Iceberg supports several schema changes:
```sql
-- Add column
ALTER TABLE my_table ADD COLUMN new_col STRING;

-- Rename column
ALTER TABLE my_table RENAME COLUMN old_name TO new_name;

-- Drop column
ALTER TABLE my_table DROP COLUMN old_col;

-- Change column type (with compatible types)
ALTER TABLE my_table ALTER COLUMN col_name TYPE BIGINT;
```

## Security Questions

### Q: How do I secure OSS credentials?

A:
1. Use environment variables (never commit credentials)
2. Use Aliyun RAM roles when running on ECS
3. Rotate credentials regularly
4. Use STS temporary credentials for short-lived access
5. Enable OSS bucket encryption

### Q: Can I use private VPC endpoints?

A: Yes, configure internal OSS endpoint:
```properties
spark.hadoop.fs.oss.endpoint=oss-cn-hangzhou-internal.aliyuncs.com
```

This provides better security and lower costs when running on ECS.

### Q: How do I enable Iceberg table encryption?

A: Configure OSS-side encryption:
```sql
ALTER TABLE my_table SET TBLPROPERTIES (
    'write.object-storage.enabled' = 'true',
    'write.encryption.enabled' = 'true'
);
```

## Cost Questions

### Q: What are the cost components?

A:
- OSS storage costs (based on data volume)
- OSS API request costs
- Data transfer costs (if accessing from outside Aliyun)
- Compute costs (if using ECS or other services)

### Q: How can I reduce costs?

A:
1. Use OSS lifecycle policies to move cold data to cheaper storage
2. Run Spark on Aliyun ECS in same region as OSS
3. Expire old snapshots regularly
4. Use appropriate compression
5. Optimize query patterns to reduce API calls

## Getting Help

### Q: Where can I get more help?

A:
- Check [Apache Spark Documentation](https://spark.apache.org/docs/latest/)
- Review [Apache Iceberg Documentation](https://iceberg.apache.org/docs/latest/)
- Read [Aliyun OSS Documentation](https://www.alibabacloud.com/help/en/oss/)
- Open an issue on GitHub
- Join Apache Spark or Iceberg community channels

### Q: How do I report a bug?

A: Open a GitHub issue with:
1. Clear description of the problem
2. Steps to reproduce
3. Expected vs actual behavior
4. Environment details
5. Relevant logs and error messages

### Q: How do I request a feature?

A: Open a GitHub issue with:
1. Description of the feature
2. Use case and benefits
3. Possible implementation approach
4. Any alternatives considered

---

**Didn't find your question?** Open an issue on GitHub!
