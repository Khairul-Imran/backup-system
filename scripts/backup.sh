#!/bin/bash

# Define source and destination directories
SOURCE_DIR="./test-data"
BACKUP_DIR="./backups"

# Create timestamp for backup file name
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
BACKUP_NAME="backup_${TIMESTAMP}.tar.gz"
BACKUP_PATH="${BACKUP_DIR}/${BACKUP_NAME}"

# Create backup directory if it doesn't exist
mkdir -p "$BACKUP_DIR"

# Function to log messages
log_message() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "./logs/backup.log"
    echo "$1"
}

# Start backup
log_message "Starting backup..."

# Calculate original size
ORIGINAL_SIZE=$(du -sh "$SOURCE_DIR" | cut -f1)

# Create compressed backup
if tar -czf "$BACKUP_PATH" -C "$SOURCE_DIR" .; then
    # Calculate compressed size
    COMPRESSED_SIZE=$(du -sh "$BACKUP_PATH" | cut -f1)
    log_message "Backup created successfully at $BACKUP_PATH"
    log_message "Original size: $ORIGINAL_SIZE"
    log_message "Compressed size: $COMPRESSED_SIZE"
else
    log_message "Error: Backup failed"
    exit 1
fi

# Count files backed up
FILE_COUNT=$(find "$BACKUP_PATH" -type f | wc -l)
log_message "Files backed up: $FILE_COUNT"