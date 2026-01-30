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
    
    echo "Backing up metadata from OSS..."
    docker exec spark-iceberg-master \
        hadoop fs -get "oss://${OSS_BUCKET}/warehouse/${db_name}.db" "${backup_path}" 2>/dev/null
    
    if [ $? -eq 0 ]; then
        echo "✅ Backup completed: ${backup_path}"
    else
        echo "❌ Backup failed"
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
    local latest_backup=$(ls -t "${BACKUP_DIR}/${db_name}_"* 2>/dev/null | head -1)
    
    if [ -z "$latest_backup" ]; then
        echo "❌ Error: No backup found for database: ${db_name}"
        exit 1
    fi
    
    echo "Restoring from: ${latest_backup}"
    
    docker exec spark-iceberg-master \
        hadoop fs -put -f "${latest_backup}" "oss://${OSS_BUCKET}/warehouse/${db_name}.db" 2>/dev/null
    
    if [ $? -eq 0 ]; then
        echo "✅ Restore completed"
    else
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
        exit 0
    fi
    
    ls -lh "${BACKUP_DIR}" | tail -n +2
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
