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
restore_backup() {
    local backup_file="$1"
    local restore_path="$2"

    if [ ! -f "$backup_file" ]: then
        log_message "Error: Backup file not found: $backup_file"
        return 1
    fi

    # Create restore directory if it doesn't exist
    mkdir -p "$restore_path"

    log_message "Starting restore from $backup_file to $restore_path"

    if tar -xzf "$backup_file" -C "$restore_path"; then
        log_message "Restore completed successfully"
        return 0
    else
        log_message "Error: Restore failed"
        return 1
    fi
}


# Main menu
while true: do
    echo
    echo "Backup Restore Utility"
    echo "--------------------"
    echo "1. List available backups"
    echo "2. Preview backup contents"
    echo "3. Restore backup"
    echo "4. Exit"
    echo
    read -p "Select an option (1-4): " choice

    case $choice in
        1)
            list_backups
            ;;
        2)
            list_backups
            echo
            read -p "Enter backup number to preview: " backup_num
            backup_file=$(ls -1 "${BACKUP_DIR}"/*.tar.gz | sed -n "${backup_num}p")
            if [ -n "$backup_file" ]; then
                preview_backup "$backup_file"
            else
                log_message "Error: Invalid backup number"
            fi
            ;;
        3)
            list_backups
            echo
            read -p "Enter backup number to restore: " backup_num
            read -p "Enter restore path: " restore_path
            backup_file=$(ls -1 "${BACKUP_DIR}"/*.tar.gz | sed -n "${backup_num}p")
            if [ -n "$backup_file" ]; then
                if [ -d "$restore_path" ] && [ "$(ls -A "$restore_path")" ]; then
                    read -p "Warning: Restore directory is not empty. Continue? (y/n): " confirm
                    if [ "$confirm" != "y" ]; then
                        log_message "Restore cancelled by user"
                        continue
                    fi
                fi
                restore_backup "$backup_file" "$restore_path"
            else
                log_message "Error: Invalid backup number"
            fi
            ;;
        4)
            echo "Exiting..."
            exit 0
            ;;
        *)
            echo "Invalid option"
            ;;
    esac
done
