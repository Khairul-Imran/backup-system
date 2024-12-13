#!/bin/bash

# Load configuration
CONFIG_FILE="./configs/backup.conf"

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
        log_message "Found $backup_count backups, cleaning up to keep only $MAX_BACKUPS"
        
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

# Start backup
log_message "Starting backup..."
log_message "Using source directory: $SOURCE_DIR"
log_message "Using backup directory: $BACKUP_DIR"
log_message "Checking for changes in $SOURCE_DIR"

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
        # Calculate compressed size
        COMPRESSED_SIZE=$(du -sh "$BACKUP_PATH" | cut -f1)
        log_message "Backup created successfully at $BACKUP_PATH"
        log_message "Original size: $ORIGINAL_SIZE"
        log_message "Compressed size: $COMPRESSED_SIZE"
        log_message "Files backed up: $FILE_COUNT"

        # Save the current checksums (that was just done) as last backup checksums
        cp "./checksums/current_checksums.txt" "./checksums/last_backup_checksums.txt"

        # Clean up old backups
        cleanup_old_backups
    else
        log_message "Error: Backup failed"
        exit 1
    fi
else
    log_message "No backup needed - files unchanged since last backup."
fi

log_message "Backup process completed."


# Stuff to work on later:
# Creating a restore script