#!/bin/bash

# Define source and destination directories
SOURCE_DIR="./test-data"
BACKUP_DIR="./backups"

# Create timestamp for backup folder name
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
BACKUP_PATH="${BACKUP_DIR}/backup_${TIMESTAMP}"

# Create backup directory if it doesn't exist
mkdir -p "$BACKUP_DIR"

# Function to log messages
log_message() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "./logs/backup.log"
    echo "$1"
}

# Start backup
log_message "Starting backup..."

# Create backup with timestamp
if cp -r "$SOURCE_DIR" "$BACKUP_PATH"; then
    log_message "Backup created successfully at $BACKUP_PATH"
else
    log_message "Error: Backup failed"
    exit 1
fi

# Count files backed up
FILE_COUNT=$(find "$BACKUP_PATH" -type f | wc -l)
log_message "Files backed up: $FILE_COUNT"