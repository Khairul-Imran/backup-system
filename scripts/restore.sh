#!/bin/bash

# Load configuration
CONFIG_FILE="./configs/backup.conf"

if [ ! -f "$CONFIG_FILE" ]; then
    echo "Error: Configuration file not found at $CONFIG_FILE"
    exit 1
fi

source "$CONFIG_FILE"

# Function to log messages
log_message() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "./logs/restore.log"
    echo "$1"
}

# Function to list all available backups
list_backups() {
    log_message "Available backups:"
    echo "Available backups:"
    echo "-----------------"

    local count=1
    for backup in "${BACKUP_DIR}"/*.tar.gz; do
        if [ -f "$backup" ]; then
            local backup_date=$(echo "$backup" | grep -o "[0-9]\{8\}_[0-9]\{6\}")
            local backup_size=$(du -h "$backup" | cut -f1)
            echo "$count) $(basename "$backup")"
            echo "   Date: ${backup_date:0:8} Time: ${backup_date:9:6}"
            echo "   Size: $backup_size"
            count=$((count + 1))
        fi
    done
}

# Function to preview backup contents
preview_backup() {
    local backup_file="$1"

    if [ ! -f "$backup_file" ]; then
        log_message "Error: Backup file not found: $backup_file"
        return 1
    fi

    echo "Preview of backup contents:"
    echo "---------------------------"
    tar -tvf "$backup_file"
}

# Function to restore backup



# Main menu