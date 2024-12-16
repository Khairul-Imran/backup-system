#!/bin/bash

# Load configuration
CONFIG_FILE="./configs/backup.conf"

# Parse command line arguments
DRY_RUN=false
while [[ "$#" -gt 0 ]]; do
    case $1 in
        -d | --dry-run)
            DRY_RUN=true
            shift
            ;;
        *)
            echo "Unknown parameter: $1"
            echo "Usage: $0 [-d|--dry-run]"
            exit 1
            ;;
    esac
done

# Function to show what files would be backed up
show_backup_preview() {
    local total_size=0
    local file_count=0
    local changed_files=""

    send_notification "info" "DRY RUN - Preview of backup operation"    
    echo "Files that would be backed up:"
    echo "------------------------------"

    # Generate current checksums for comparison
    generate_checksums

    while IFS= read -r file; do
        local filepath=$(echo "$file" | awk '{print $2}')
        local size=$(du -h "$filepath" 2>/dev/null | cut -f1)
        echo "📄 $filepath ($size)"
        ((file_count++))

        # Check if file is changed or new
        if [ -f "./checksums/last_backup_checksums.txt" ]; then
            if ! grep -q "$file" "./checksums/last_backup_checksums.txt"; then
                changed_files="$changed_files\n➕ New/Changed: $filepath"
            fi
        fi
    done < "./checksums/current_checksums.txt"

    # Calculate total size
    total_size=$(du -sh "$SOURCE_DIR" | cut -f1)

    echo -e "\nSummary:"
    echo "---------"
    echo "Total files to backup: $file_count"
    echo "Total size: $total_size"

    if [ -n "$changed_files" ]; then
        echo -e "\nChanged or new files:"
        echo -e "$changed_files"
    fi

    # Show disk space information
    local available_space=$(df -h "$BACKUP_DIR" | awk 'NR==2 {print $4}')
    echo -e "\nAvailable space in backup directory: $available_space"
}


# Function to check available disk space (in KB)
check_disk_space() {
    local backup_dir_space=$(df -k "$BACKUP_DIR" | tail -1 | awk '{print $4}')
    local source_size=$(du -sk "$SOURCE_DIR" | awk '{print $1}')

    # Require 1.5 times the source size for safety margin
    local required_space=$((source_size * 15 / 10))

    if [ "$backup_dir_space" -lt "$required_space" ]; then
        log_message "Error: Insufficient disk space. Available: ${backup_dir_space}KB, Required: ${required_space}KB"
        return 1
    fi

    log_message "Sufficient disk space available: ${backup_dir_space}"
    return 0
}

# Function to verify backup integrity
verify_backup() {
    local backup_file="$1"

    log_message "Verifying backup integrity..."

    # Try to list contents of the archive
    if tar -tzf "$backup_file" >/dev/null 2>&1; then
        log_message "Backup verification successful"
        return 0
    else
        log_message "Error: Backup verification failed"
        return 1
    fi
}

# Function to send notification (prints to console and log, can be modified for other notification methods in the future)
send_notification() {
    local status="$1"
    local message="$2"

    case "$status" in
        "success")
            log_message "✅ SUCCESS: $message"
            ;;
        "warning")
            log_message "⚠️ WARNING: $message"
            ;;
        "error")
            log_message "❌ ERROR: $message"
            ;;
        *)
            log_message "ℹ️ INFO: $message"
            ;;
    esac
}


if [ ! -f "$CONFIG_FILE" ]; then
    echo "Error: Configuration file not found at $CONFIG_FILE"
    exit 1
fi

# Source the config file
source "$CONFIG_FILE"

# Verify required variables are set
if [ -z "$SOURCE_DIR" ] || [ -z "$BACKUP_DIR" ] || [ -z "$MAX_BACKUPS" ]; then
    echo "Error: Required configuration variables are missing"
    exit 1
fi

# Create directories if they don't exist
mkdir -p "$BACKUP_DIR"
mkdir -p "./checksums"

# Function to log messages
log_message() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "./logs/backup.log"
    echo "$1"
}

# Function to generate checksums for all files
generate_checksums() {
    find "$SOURCE_DIR" -type f -exec md5sum {} \; | sort > "./checksums/current_checksums.txt"
}

# Function to check if files have changed
files_have_changed() {
    generate_checksums

    if [ ! -f "./checksums/last_backup_checksums.txt" ]; then
        log_message "No previous checksum file found. First backup needed."
        return 0
    fi

    if ! diff "./checksums/last_backup_checksums.txt" "./checksums/current_checksums.txt" >/dev/null; then
        log_message "Changes detected in source files."
        return 0
    else
        log_message "No changes detected since last backup."
        return 1
    fi
}

# Function to cleanup old backups
cleanup_old_backups() {
    # List all backups sorted by date (oldest first)
    local backup_count=$(ls -1 "${BACKUP_DIR}"/*.tar.gz 2>/dev/null | wc -l)
    
    if [ "$backup_count" -gt "$MAX_BACKUPS" ]; then
        send_notification "warning" "Found $backup_count backups, cleaning up to keep only $MAX_BACKUPS"
        
        # Get list of old backups to remove
        local files_to_remove=$(ls -1t "${BACKUP_DIR}"/*.tar.gz | tail -n +$((MAX_BACKUPS + 1)))
        
        # Remove old backups
        while IFS= read -r file; do
            rm "$file"
            log_message "Removed old backup: $file"
        done <<< "$files_to_remove"
    else
        log_message "No cleanup needed. Current backup count: $backup_count"
    fi
}

# To check for dry run
if [ "$DRY_RUN" = true ]; then
    show_backup_preview
    exit 0
fi

# Start backup
# log_message "Starting backup..."
send_notification "info" "Starting backup process..."
log_message "Using source directory: $SOURCE_DIR"
log_message "Using backup directory: $BACKUP_DIR"
log_message "Checking for changes in $SOURCE_DIR"

# Check disk space fist
if ! check_disk_space; then
    send_notification "error" "Backup aborted due to insufficient disk space."
    exit 1
fi


# Only proceed with backup if files have changed
if files_have_changed; then

    # Create timestamp for backup file name
    TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
    BACKUP_NAME="backup_${TIMESTAMP}.tar.gz"
    BACKUP_PATH="${BACKUP_DIR}/${BACKUP_NAME}"

    # Calculate original size
    ORIGINAL_SIZE=$(du -sh "$SOURCE_DIR" | cut -f1)
    FILE_COUNT=$(find "$SOURCE_DIR" -type f | wc -l)
    
    # Create compressed backup
    if tar -czf "$BACKUP_PATH" -C "$SOURCE_DIR" .; then

        # Verify backup integrity
        if ! verify_backup "$BACKUP_PATH"; then
            send_notification "error" "Backup failed integrity verification."
            rm "$BACKUP_PATH" # Remove the failed backup
            exit 1
        fi

        # Calculate compressed size
        COMPRESSED_SIZE=$(du -sh "$BACKUP_PATH" | cut -f1)
        send_notification "success" "Backup created successfully at $BACKUP_PATH"
        send_notification "info" "Original size: $ORIGINAL_SIZE, Compressed size: $COMPRESSED_SIZE, Files: $FILE_COUNT"

        # Save the current checksums (that was just done) as last backup checksums
        cp "./checksums/current_checksums.txt" "./checksums/last_backup_checksums.txt"

        # Clean up old backups
        cleanup_old_backups
    else
        send_notification "error" "Backup creation failed."
        exit 1
    fi
else
    send_notification "info" "No backup needed - files unchanged since last backup."
fi

send_notification "success" "Backup process completed."


# Stuff to work on later:

# Add more configuration options:
# - Exclude specific files/directories
# - Different compression levels
# - Custom backup naming patterns
# - Different backup rotation strategies


# Add a dry-run mode:
# - Show what would be backed up
# - Show size estimates
# - Show which files changed


# Add backup reporting:
# - Generate summary reports
# - Track backup history
# - Show space usage trends
