#!/bin/bash

# Backup and restore Iceberg metadata

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP_DIR="${SCRIPT_DIR}/../backups"

# Load environment variables
if [ -f "${SCRIPT_DIR}/../.env" ]; then
    source "${SCRIPT_DIR}/../.env"
else
    echo "❌ Error: .env file not found"
    exit 1
fi

function show_usage() {
    echo "Usage: $0 <command> [options]"
    echo ""
    echo "Commands:"
    echo "  backup <database>   - Backup Iceberg database metadata"
    echo "  restore <database>  - Restore Iceberg database metadata"
    echo "  list               - List available backups"
    echo ""
    echo "Examples:"
    echo "  $0 backup mydb"
    echo "  $0 restore mydb"
    echo "  $0 list"
    echo ""
    echo "Note: Backups are stored in the backups/ directory on the host"
}

function backup_database() {
    local db_name=$1
    
    if [ -z "$db_name" ]; then
        echo "❌ Error: Database name is required"
        show_usage
        exit 1
    fi
    
    echo "================================================================"
    echo "  Backup Iceberg Database: ${db_name}"
    echo "================================================================"
    
    mkdir -p "${BACKUP_DIR}"
    
    local timestamp=$(date +%Y%m%d_%H%M%S)
    local backup_path="${BACKUP_DIR}/${db_name}_${timestamp}"
    local container_tmp="/tmp/backup_${timestamp}"
    
    echo "Creating temporary directory in container..."
    docker exec spark-iceberg-master mkdir -p "${container_tmp}"
    
    echo "Copying metadata from OSS to container..."
    docker exec spark-iceberg-master \
        hadoop fs -get "oss://${OSS_BUCKET}/warehouse/${db_name}.db" "${container_tmp}/" 2>/dev/null
    
    if [ $? -eq 0 ]; then
        echo "Copying from container to host..."
        docker cp "spark-iceberg-master:${container_tmp}/${db_name}.db" "${backup_path}"
        
        # Clean up temp directory in container
        docker exec spark-iceberg-master rm -rf "${container_tmp}"
        
        echo "✅ Backup completed: ${backup_path}"
    else
        docker exec spark-iceberg-master rm -rf "${container_tmp}" 2>/dev/null || true
        echo "❌ Backup failed - database may not exist in OSS"
        exit 1
    fi
}

function restore_database() {
    local db_name=$1
    
    if [ -z "$db_name" ]; then
        echo "❌ Error: Database name is required"
        show_usage
        exit 1
    fi
    
    echo "================================================================"
    echo "  Restore Iceberg Database: ${db_name}"
    echo "================================================================"
    
    # Find latest backup
    local latest_backup=$(ls -td "${BACKUP_DIR}/${db_name}_"* 2>/dev/null | head -1)
    
    if [ -z "$latest_backup" ]; then
        echo "❌ Error: No backup found for database: ${db_name}"
        exit 1
    fi
    
    echo "Restoring from: ${latest_backup}"
    
    local container_tmp="/tmp/restore_$(date +%s)"
    
    echo "Copying backup to container..."
    docker exec spark-iceberg-master mkdir -p "${container_tmp}"
    docker cp "${latest_backup}" "spark-iceberg-master:${container_tmp}/"
    
    echo "Uploading to OSS..."
    docker exec spark-iceberg-master \
        hadoop fs -put -f "${container_tmp}/$(basename ${latest_backup})" "oss://${OSS_BUCKET}/warehouse/${db_name}.db" 2>/dev/null
    
    if [ $? -eq 0 ]; then
        # Clean up temp directory
        docker exec spark-iceberg-master rm -rf "${container_tmp}"
        echo "✅ Restore completed"
    else
        docker exec spark-iceberg-master rm -rf "${container_tmp}" 2>/dev/null || true
        echo "❌ Restore failed"
        exit 1
    fi
}

function list_backups() {
    echo "================================================================"
    echo "  Available Backups"
    echo "================================================================"
    
    if [ ! -d "${BACKUP_DIR}" ] || [ -z "$(ls -A ${BACKUP_DIR} 2>/dev/null)" ]; then
        echo "No backups found"
        echo ""
        echo "Backups will be stored in: ${BACKUP_DIR}"
        exit 0
    fi
    
    echo ""
    ls -lh "${BACKUP_DIR}" | tail -n +2
    echo ""
    echo "Backup location: ${BACKUP_DIR}"
}

# Main
case "$1" in
    backup)
        backup_database "$2"
        ;;
    restore)
        restore_database "$2"
        ;;
    list)
        list_backups
        ;;
    *)
        show_usage
        exit 1
        ;;
esac
