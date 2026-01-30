# Use official Apache Spark image as base
FROM apache/spark:3.5.5-scala2.12-java11-python3-ubuntu

# Maintainer information
LABEL maintainer="YaQia"
LABEL description="Apache Spark with Iceberg and Aliyun OSS support"

USER root

# Set environment variables
ENV ICEBERG_VERSION=1.8.1
ENV HADOOP_VERSION=3.3.4
ENV ALIYUN_SDK_OSS_VERSION=3.18.5
ENV SPARK_HOME=/opt/spark

# Download and install Iceberg runtime JAR
RUN curl -L -o ${SPARK_HOME}/jars/iceberg-spark-runtime-3.5_2.12-${ICEBERG_VERSION}.jar \
    https://repo1.maven.org/maven2/org/apache/iceberg/iceberg-spark-runtime-3.5_2.12/${ICEBERG_VERSION}/iceberg-spark-runtime-3.5_2.12-${ICEBERG_VERSION}.jar

# Download and install Aliyun OSS SDK
RUN curl -L -o ${SPARK_HOME}/jars/aliyun-sdk-oss-${ALIYUN_SDK_OSS_VERSION}.jar \
    https://repo1.maven.org/maven2/com/aliyun/oss/aliyun-sdk-oss/${ALIYUN_SDK_OSS_VERSION}/aliyun-sdk-oss-${ALIYUN_SDK_OSS_VERSION}.jar

# Download and install Hadoop Aliyun
RUN curl -L -o ${SPARK_HOME}/jars/hadoop-aliyun-${HADOOP_VERSION}.jar \
    https://repo1.maven.org/maven2/org/apache/hadoop/hadoop-aliyun/${HADOOP_VERSION}/hadoop-aliyun-${HADOOP_VERSION}.jar

# Download additional required dependencies for OSS
RUN curl -L -o ${SPARK_HOME}/jars/jdom2-2.0.6.1.jar \
    https://repo1.maven.org/maven2/org/jdom/jdom2/2.0.6.1/jdom2-2.0.6.1.jar

# Copy configuration files
COPY conf/spark-defaults.conf ${SPARK_HOME}/conf/spark-defaults.conf

# Set work directory
WORKDIR /opt/spark/work-dir

# Switch back to spark user
USER 185

# Expose Spark ports
EXPOSE 4040 7077 8080 8081

# Default command
CMD ["/opt/spark/bin/spark-shell"]
