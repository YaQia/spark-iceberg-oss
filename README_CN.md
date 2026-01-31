# Spark + Iceberg + 阿里云 OSS

[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](https://opensource.org/licenses/Apache-2.0)
[![Spark](https://img.shields.io/badge/Spark-3.5.5-orange.svg)](https://spark.apache.org/)
[![Iceberg](https://img.shields.io/badge/Iceberg-1.8.1-blue.svg)](https://iceberg.apache.org/)

基于官方 Apache Spark 镜像构建的生产级 Docker 镜像，集成了 Apache Iceberg 和阿里云 OSS（对象存储服务）支持。本项目为在阿里云 OSS 上运行 Spark 工作负载和使用 Iceberg 表格式提供了完整的解决方案。

[English](README.md) | 简体中文

## 🌟 特性

- **官方 Apache Spark 3.5.5** 基础镜像，包含 Scala 2.12、Java 11 和 Python 3
- **最新 Apache Iceberg 1.8.1** 运行时，支持现代化表格式功能
- **完整的阿里云 OSS 集成**，包含 hadoop-aliyun 和 aliyun-sdk-oss
- **Docker Compose** 配置，便于本地开发和测试
- **完整示例**，包括 PySpark 和 Spark SQL 示例
- **生产就绪的配置**，遵循最佳实践

## 📋 前置要求

- Docker (20.10+)
- Docker Compose (1.29+)
- 阿里云 OSS 账户及访问密钥

## 🚀 快速开始

### 1. 克隆仓库

```bash
git clone https://github.com/YaQia/spark-iceberg-oss.git
cd spark-iceberg-oss
```

### 2. 配置 OSS 凭证

在项目根目录创建 `.env` 文件：

```bash
cat > .env << EOF
OSS_ACCESS_KEY_ID=你的访问密钥ID
OSS_ACCESS_KEY_SECRET=你的访问密钥Secret
OSS_ENDPOINT=oss-cn-hangzhou.aliyuncs.com
OSS_BUCKET=你的bucket名称
EOF
```

**重要提示：** 确保同时更新 `conf/spark-defaults.conf` 文件中的 OSS 凭证和 bucket 信息。

### 3. 构建 Docker 镜像

```bash
docker build -t spark-iceberg-oss:latest .
```

### 4. 启动集群

```bash
docker-compose up -d
```

这将启动：
- Spark Master（Web UI: http://localhost:8080）
- Spark Worker（Web UI: http://localhost:8081）

### 5. 运行示例

#### 自动快速启动

```bash
# 使用快速启动脚本
./quick-start.sh
```

#### PySpark 示例

```bash
# 在运行的容器中执行
docker exec -it spark-iceberg-master \
    spark-submit \
    --master spark://spark-master:7077 \
    /opt/spark/examples/iceberg_oss_example.py
```

#### Spark SQL 示例

```bash
# 启动 Spark SQL shell
docker exec -it spark-iceberg-master \
    spark-sql \
    --master spark://spark-master:7077
```

然后粘贴 `examples/iceberg_sql_examples.sql` 中的 SQL 命令。

## 📚 架构

### 组件

```
┌─────────────────────────────────────────────────────────────┐
│                     Apache Spark 3.5.5                      │
│  ┌───────────────────────────────────────────────────────┐  │
│  │           Apache Iceberg 1.8.1 运行时                  │  │
│  │  ┌─────────────────────────────────────────────────┐  │  │
│  │  │         Hadoop 阿里云 OSS 连接器                │  │  │
│  │  │  ┌───────────────────────────────────────────┐  │  │  │
│  │  │  │      阿里云 OSS SDK 3.18.5                │  │  │  │
│  │  │  └───────────────────────────────────────────┘  │  │  │
│  │  └─────────────────────────────────────────────────┘  │  │
│  └───────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
                            │
                            ▼
                ┌───────────────────────┐
                │   阿里云 OSS 存储      │
                │   oss://bucket/path   │
                └───────────────────────┘
```

### 依赖项

| 组件 | 版本 | 用途 |
|-----------|---------|---------|
| Apache Spark | 3.5.5 | 分布式计算引擎 |
| Apache Iceberg | 1.8.1 | 大规模分析数据集的表格式 |
| Hadoop Aliyun | 3.3.4 | OSS 文件系统实现 |
| Aliyun SDK OSS | 3.18.5 | 阿里云 OSS 客户端库 |
| JDOM2 | 2.0.6.1 | XML 处理（OSS 依赖） |

## 🔧 配置

### Spark 配置 (`conf/spark-defaults.conf`)

Iceberg 和 OSS 的关键配置：

```properties
# Iceberg 目录
spark.sql.catalog.iceberg_catalog=org.apache.iceberg.spark.SparkCatalog
spark.sql.catalog.iceberg_catalog.type=hadoop
spark.sql.catalog.iceberg_catalog.warehouse=oss://your-bucket/warehouse

# OSS 访问配置
spark.hadoop.fs.oss.endpoint=oss-cn-hangzhou.aliyuncs.com
spark.hadoop.fs.oss.accessKeyId=YOUR_ACCESS_KEY_ID
spark.hadoop.fs.oss.accessKeySecret=YOUR_ACCESS_KEY_SECRET
spark.hadoop.fs.oss.impl=org.apache.hadoop.fs.aliyun.oss.AliyunOSSFileSystem

# Iceberg 扩展
spark.sql.extensions=org.apache.iceberg.spark.extensions.IcebergSparkSessionExtensions
```

### 环境变量

可以使用环境变量覆盖配置：

- `OSS_ENDPOINT`: OSS 端点 URL（默认：oss-cn-hangzhou.aliyuncs.com）
- `OSS_ACCESS_KEY_ID`: 你的阿里云访问密钥 ID
- `OSS_ACCESS_KEY_SECRET`: 你的阿里云访问密钥 Secret
- `OSS_BUCKET`: 用于数据存储的 OSS bucket 名称

## 📖 使用示例

### 创建 Iceberg 表

```python
from pyspark.sql import SparkSession

spark = SparkSession.builder \
    .appName("IcebergExample") \
    .getOrCreate()

# 创建数据库
spark.sql("CREATE DATABASE IF NOT EXISTS mydb")

# 创建分区表
spark.sql("""
    CREATE TABLE mydb.users (
        id BIGINT,
        name STRING,
        age INT,
        created_at TIMESTAMP
    ) USING iceberg
    PARTITIONED BY (days(created_at))
""")

# 插入数据
spark.sql("""
    INSERT INTO mydb.users VALUES
    (1, 'Alice', 30, current_timestamp()),
    (2, 'Bob', 25, current_timestamp())
""")

# 查询数据
spark.sql("SELECT * FROM mydb.users").show()
```

### 时间旅行

```sql
-- 查询历史数据
SELECT * FROM mydb.users TIMESTAMP AS OF '2024-01-01 00:00:00';

-- 通过快照 ID 查询
SELECT * FROM mydb.users VERSION AS OF 1234567890;

-- 查看表历史
SELECT * FROM mydb.users.history;
```

### Schema 演化

```sql
-- 添加列
ALTER TABLE mydb.users ADD COLUMN email STRING;

-- 重命名列
ALTER TABLE mydb.users RENAME COLUMN email TO contact_email;

-- 删除列
ALTER TABLE mydb.users DROP COLUMN contact_email;
```

### MERGE（Upsert）操作

```sql
MERGE INTO target_table t
USING source_table s
ON t.id = s.id
WHEN MATCHED THEN UPDATE SET *
WHEN NOT MATCHED THEN INSERT *;
```

## 🛠️ 高级用法

### 自定义 Spark Submit

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

### 表维护

```sql
-- 过期旧快照
CALL iceberg_catalog.system.expire_snapshots(
    table => 'mydb.users',
    older_than => TIMESTAMP '2024-01-01 00:00:00',
    retain_last => 5
);

-- 删除孤立文件
CALL iceberg_catalog.system.remove_orphan_files(
    table => 'mydb.users'
);

-- 重写数据文件以优化表
CALL iceberg_catalog.system.rewrite_data_files(
    table => 'mydb.users'
);
```

### 在 Kubernetes 中使用

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

## 🔍 故障排除

### OSS 连接问题

1. 验证 OSS 端点对于你的区域是否正确
2. 检查访问密钥 ID 和 Secret 是否有效
3. 确保 bucket 存在且你有权限访问
4. 测试连接：`hadoop fs -ls oss://your-bucket/`

### Iceberg 表问题

1. 检查 spark-defaults.conf 中的目录配置
2. 验证 warehouse 路径在 OSS 中是否可访问
3. 查看 Spark 日志获取详细错误信息

### 性能优化

- 使用适当的分区策略
- 启用数据文件压缩（Parquet 配合 Snappy/GZIP）
- 定期表维护（过期快照、压缩文件）
- 调优 Spark 内存和执行器设置

## 📦 包含内容

```
spark-iceberg-oss/
├── Dockerfile                          # Docker 镜像定义
├── docker-compose.yml                  # 多容器配置
├── conf/
│   └── spark-defaults.conf            # Spark 配置文件
├── examples/
│   ├── iceberg_oss_example.py         # PySpark 示例
│   ├── iceberg_sql_examples.sql       # SQL 示例
│   └── run_example.sh                 # 示例执行脚本
├── .env.template                       # 环境变量模板
├── .gitignore                         # Git 忽略规则
├── quick-start.sh                     # 快速启动脚本
├── LICENSE                            # Apache 2.0 许可证
├── README.md                          # 英文文档
└── README_CN.md                       # 中文文档
```

## 🤝 贡献

欢迎贡献！请随时提交 Pull Request。

1. Fork 本仓库
2. 创建特性分支 (`git checkout -b feature/AmazingFeature`)
3. 提交你的修改 (`git commit -m '添加一些很棒的特性'`)
4. 推送到分支 (`git push origin feature/AmazingFeature`)
5. 开启一个 Pull Request

## 📝 许可证

本项目采用 Apache License 2.0 许可 - 详见 [LICENSE](LICENSE) 文件。

## 🔗 参考资料

- [Apache Spark 文档](https://spark.apache.org/docs/latest/)
- [Apache Iceberg 文档](https://iceberg.apache.org/docs/latest/)
- [阿里云 OSS 文档](https://help.aliyun.com/product/31815.html)
- [Hadoop Aliyun 模块](https://hadoop.apache.org/docs/stable/hadoop-aliyun/tools/hadoop-aliyun/index.html)

## 📧 支持

对于问题和疑问：
- 在 GitHub 上开启一个 issue
- 查看现有的 issues 和文档

## ⭐ Star 历史

如果你觉得这个项目有用，请考虑给它一个 star！

---

**用 ❤️ 为 Apache Spark 和 Iceberg 社区构建**
