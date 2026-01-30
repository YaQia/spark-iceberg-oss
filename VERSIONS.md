# Component Versions

This document tracks the versions of all components used in this project.

## Core Components

| Component | Version | Release Date | Notes |
|-----------|---------|--------------|-------|
| Apache Spark | 3.5.0 | 2023-09 | Base image |
| Apache Iceberg | 1.5.0 | 2024-01 | Latest stable release |
| Scala | 2.12 | - | Compatible with Spark 3.5 |
| Java | 11 | - | LTS version |
| Python | 3 | - | For PySpark |

## Storage & Connectivity

| Component | Version | Notes |
|-----------|---------|-------|
| Hadoop Aliyun | 3.3.4 | OSS FileSystem implementation |
| Aliyun SDK OSS | 3.17.4 | Latest stable OSS SDK |
| JDOM2 | 2.0.6.1 | XML processing for OSS |

## Container & Orchestration

| Component | Minimum Version | Notes |
|-----------|-----------------|-------|
| Docker | 20.10+ | Required |
| Docker Compose | 1.29+ | Required |
| Kubernetes | 1.20+ | Optional, for production |

## Compatibility Matrix

### Spark - Iceberg Compatibility

| Spark Version | Compatible Iceberg Versions |
|---------------|----------------------------|
| 3.5.x | 1.4.x, 1.5.x |
| 3.4.x | 1.3.x, 1.4.x |
| 3.3.x | 1.2.x, 1.3.x |

### Iceberg - Hadoop Compatibility

| Iceberg Version | Minimum Hadoop Version |
|-----------------|------------------------|
| 1.5.x | 3.3.0 |
| 1.4.x | 3.2.0 |

## Update History

| Date | Component | Old Version | New Version | Reason |
|------|-----------|-------------|-------------|--------|
| 2024-01 | Initial Release | - | - | Initial version |

## Upgrade Notes

### Upgrading Spark

1. Check Iceberg compatibility matrix
2. Update Dockerfile base image
3. Rebuild image
4. Test with existing tables

### Upgrading Iceberg

1. Check release notes for breaking changes
2. Update ICEBERG_VERSION in Dockerfile
3. Rebuild image
4. Run table migration if needed

### Upgrading Aliyun SDK

1. Check for API changes
2. Update ALIYUN_SDK_OSS_VERSION in Dockerfile
3. Rebuild and test OSS connectivity

## Version Selection Guidelines

### For Production

- Use LTS/stable versions only
- Test thoroughly before upgrading
- Keep versions aligned with official compatibility matrix
- Subscribe to security advisories

### For Development

- Can use latest versions
- Test new features
- Report issues to upstream projects

## Useful Links

- [Spark Releases](https://spark.apache.org/releases/)
- [Iceberg Releases](https://github.com/apache/iceberg/releases)
- [Hadoop Releases](https://hadoop.apache.org/releases.html)
- [Aliyun OSS SDK](https://github.com/aliyun/aliyun-oss-java-sdk)

## Security Updates

Always check for security updates:
- [Spark Security](https://spark.apache.org/security.html)
- [CVE Database](https://cve.mitre.org/)

---

Last updated: 2024-01
