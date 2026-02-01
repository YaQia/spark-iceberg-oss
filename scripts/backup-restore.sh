#!/bin/bash

# ============================================================================
# Iceberg Metadata Backup and Restore Script
# ============================================================================
# This script provides backup and restore functionality for the PostgreSQL
# JDBC Catalog metadata, allowing for easy disaster recovery and migration.
# ============================================================================

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
BACKUP_DIR="${BACKUP_DIR:-.backup}"
DB_CONTAINER="${DB_CONTAINER:-iceberg-postgres}"
DB_NAME="${DB_NAME:-iceberg_catalog}"
DB_USER="${DB_USER:-iceberg_user}"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

# Functions
print_header() {
	echo -e "${BLUE}============================================================================${NC}"
	echo -e "${BLUE}$1${NC}"
	echo -e "${BLUE}============================================================================${NC}"
}

print_success() {
	echo -e "${GREEN}✓ $1${NC}"
}

print_error() {
	echo -e "${RED}✗ $1${NC}"
}

print_warning() {
	echo -e "${YELLOW}⚠ $1${NC}"
}

print_info() {
	echo -e "${BLUE}ℹ $1${NC}"
}

check_container() {
	if ! docker ps | grep -q "$DB_CONTAINER"; then
		print_error "PostgreSQL container '$DB_CONTAINER' is not running"
		echo "Please start the container with: docker-compose up -d"
		exit 1
	fi
	print_success "PostgreSQL container is running"
}

backup_database() {
	print_header "Creating Database Backup"

	check_container

	# Create backup directory
	mkdir -p "$BACKUP_DIR"

	# Backup filename
	BACKUP_FILE="$BACKUP_DIR/iceberg_${TIMESTAMP}.sql"
	BACKUP_COMPRESSED="$BACKUP_FILE.gz"

	print_info "Creating backup: $BACKUP_FILE"

	# Create dump
	docker exec "$DB_CONTAINER" \
		pg_dump -U "$DB_USER" "$DB_NAME" \
		--if-exists --clean --create >"$BACKUP_FILE"

	if [ $? -eq 0 ]; then
		print_success "Database dump created"

		# Compress backup
		print_info "Compressing backup..."
		gzip "$BACKUP_FILE"

		if [ $? -eq 0 ]; then
			print_success "Backup completed: $BACKUP_COMPRESSED"
			ls -lh "$BACKUP_COMPRESSED"

			# Keep only last 7 backups
			print_info "Cleaning old backups (keeping last 7)..."
			ls -t "$BACKUP_DIR"/iceberg_*.sql.gz 2>/dev/null | tail -n +8 | xargs -r rm
			print_success "Cleanup completed"
		else
			print_error "Failed to compress backup"
			exit 1
		fi
	else
		print_error "Failed to create database dump"
		exit 1
	fi
}

restore_database() {
	local backup_file=$1

	print_header "Restoring Database from Backup"

	if [ -z "$backup_file" ]; then
		print_error "No backup file specified"
		echo "Usage: $0 restore <backup_file>"
		exit 1
	fi

	if [ ! -f "$backup_file" ]; then
		print_error "Backup file not found: $backup_file"
		exit 1
	fi

	check_container

	# Confirm action
	print_warning "This will overwrite the current database!"
	read -p "Are you sure? (yes/no): " -r
	if [[ ! $REPLY =~ ^[Yy]$ ]]; then
		print_info "Restore cancelled"
		exit 0
	fi

	print_info "Restoring from: $backup_file"

	# Decompress if needed
	if [[ "$backup_file" == *.gz ]]; then
		print_info "Decompressing backup..."
		TEMP_FILE=$(mktemp)
		gunzip -c "$backup_file" >"$TEMP_FILE"
		backup_file="$TEMP_FILE"
	fi

	# Restore database
	print_info "Importing backup into PostgreSQL..."
	cat "$backup_file" | docker exec -i "$DB_CONTAINER" \
		psql -U "$DB_USER"

	if [ $? -eq 0 ]; then
		print_success "Database restore completed successfully"
		# Cleanup temp file
		rm -f "$TEMP_FILE"
	else
		print_error "Database restore failed"
		rm -f "$TEMP_FILE"
		exit 1
	fi
}

list_backups() {
	print_header "Available Backups"

	if [ ! -d "$BACKUP_DIR" ]; then
		print_warning "Backup directory does not exist: $BACKUP_DIR"
		return
	fi

	if [ -z "$(ls -A "$BACKUP_DIR" 2>/dev/null)" ]; then
		print_warning "No backups found in $BACKUP_DIR"
		return
	fi

	echo "Backups in $BACKUP_DIR:"
	ls -lh "$BACKUP_DIR"/iceberg_*.sql.gz 2>/dev/null | awk '{print $9, "(" $5 ")"}'

	if [ $? -ne 0 ]; then
		print_warning "No backup files found"
	fi
}

verify_backup() {
	local backup_file=$1

	print_header "Verifying Backup"

	if [ -z "$backup_file" ]; then
		print_error "No backup file specified"
		echo "Usage: $0 verify <backup_file>"
		exit 1
	fi

	if [ ! -f "$backup_file" ]; then
		print_error "Backup file not found: $backup_file"
		exit 1
	fi

	print_info "Verifying: $backup_file"

	# Check if it's a valid gzip file
	if [[ "$backup_file" == *.gz ]]; then
		if gunzip -t "$backup_file" 2>/dev/null; then
			print_success "Gzip file is valid"
		else
			print_error "Gzip file is corrupted"
			exit 1
		fi
	fi

	# Check SQL syntax (basic)
	if [[ "$backup_file" == *.gz ]]; then
		gunzip -c "$backup_file" | head -100 | grep -q "CREATE TABLE\|INSERT INTO"
	else
		head -100 "$backup_file" | grep -q "CREATE TABLE\|INSERT INTO"
	fi

	if [ $? -eq 0 ]; then
		print_success "Backup file appears to be valid"
		print_info "File size: $(ls -lh "$backup_file" | awk '{print $5}')"
	else
		print_warning "Could not verify backup contents"
	fi
}

show_help() {
	cat <<EOF
${BLUE}Iceberg Metadata Backup and Restore Script${NC}

${BLUE}Usage:${NC}
    $0 <command> [options]

${BLUE}Commands:${NC}
    backup              Create a backup of the Iceberg catalog metadata
    restore <file>      Restore database from a backup file
    list                List available backups
    verify <file>       Verify the integrity of a backup file
    help                Show this help message

${BLUE}Examples:${NC}
    # Create a new backup
    $0 backup

    # List all available backups
    $0 list

    # Verify a backup
    $0 verify .backup/iceberg_20240202_120000.sql.gz

    # Restore from a backup (interactive)
    $0 restore .backup/iceberg_20240202_120000.sql.gz

${BLUE}Environment Variables:${NC}
    BACKUP_DIR      Backup directory (default: .backup)
    DB_CONTAINER    PostgreSQL container name (default: iceberg-postgres)
    DB_NAME         Database name (default: iceberg_catalog)
    DB_USER         Database user (default: iceberg_user)

${BLUE}Notes:${NC}
    - Backups are automatically compressed with gzip
    - Only the last 7 backups are kept automatically
    - Restore requires confirmation before proceeding
    - Database must be running in a Docker container

${BLUE}Backup Retention:${NC}
    Backups older than 7 are automatically deleted.
    To keep all backups, manually move them outside the backup directory.

EOF
}

# Main script logic
main() {
	local command=${1:-help}

	case "$command" in
	backup)
		backup_database
		;;
	restore)
		restore_database "$2"
		;;
	list)
		list_backups
		;;
	verify)
		verify_backup "$2"
		;;
	help | --help | -h)
		show_help
		;;
	*)
		print_error "Unknown command: $command"
		echo ""
		show_help
		exit 1
		;;
	esac
}

# Run main function
main "$@"
