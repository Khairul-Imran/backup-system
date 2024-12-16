#!/bin/bash

# Load configuration
CONFIG_FILE="./configs/backup.conf"

if [ ! -f "$CONFIG_FILE" ]; then
    echo "Error: Configuration file not found at $CONFIG_FILE"
    exit 1
fi

source "$CONFIG_FILE"

# Create the directory if they don't exist yet
mkdir -p "$REPORT_DIR"

# Verify required variables are set
if [ -z "$SOURCE_DIR" ] || [ -z "$BACKUP_DIR" ] || [ -z "$MAX_BACKUPS" ] || [ -z "$REPORT_DIR" ]; then
    echo "Error: Required configuration variables are missing"
    exit 1
fi

# Function to log messages
log_message() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "./logs/report.log"
    echo "$1"
}

# Function to generate summary of latest backup
generate_latest_summary() {
    echo "Latest Backup Summary"
    echo "---------------------"

    # Get latest backup file
    latest_backup=$(ls -t "${BACKUP_DIR}"/*.tar.gz 2>/dev/null | head -n1)

    if [ -z "$latest_backup" ]; then
        echo "No backups found"
        return 1
    fi

    local backup_date=$(echo "$latest_backup" | grep -o "[0-9]\{8\}_[0-9]\{6\}")
    local backup_size=$(du -h "$latest_backup" | cut -f1) 
    local file_count=$(tar -tvf "$latest_backup" | wc -l)

    echo "Date: ${backup_date:0:8} Time: ${backup_date:9:6}"
    echo "Size: $backup_size"
    echo "Files: $file_count"
}

# Function to show backup history
show_backup_history() {
    echo "Backup History"
    echo "--------------"

    echo "Date       Time     Size    Files    Status"
    echo "----------------------------------------"

    # Parse backup log for history
    awk '
        /✅ SUCCESS: Backup created successfully/ {
            date=$1 " " $2
            gsub(/[\[\]]/, "", date)  # Remove brackets from date
            backup_date = date
        }
        /ℹ️ INFO: Original size:/ {
            # Split the line on commas and extract values
            split($0, parts, ",")
            # Extract size from "Compressed size: 4.0K"
            compressed_size = parts[2]
            sub(".*: ", "", compressed_size)
            # Extract files from "Files:        4"
            files = parts[3]
            sub(".*: ", "", files)
            # Print the complete record
            printf "%-10s %-8s %-8s %-8s %-s\n", 
                substr(backup_date,1,10), 
                substr(backup_date,12,8), 
                compressed_size, 
                files, 
                "Success"
        }
    ' ./logs/backup.log
}

# Function to analyze space usage trends
analyze_space_trends() {
    echo "Space Usage Trends"
    echo "------------------"

    echo "Month      Total Size       Avg Backup Size   Number of Backups"
    echo "--------------------------------------------------------"

    for backup in "${BACKUP_DIR}"/*.tar.gz; do
        if [ -f "$backup" ]; then
            # Extract YYYYMM from filename
            month=$(basename "$backup" | grep -o "[0-9]\{8\}" | cut -c1-6)
            # Get size in MB
            size=$(du -m "$backup" | cut -f1)
            echo "$month $size"
        fi
    done | 
    awk '
    {
        month[$1] += $2;  # Sum up the sizes
        count[$1]++;      # Count backups per month
    }
    END {
        format = "%-10s %-16s %-17s %-d\n"
        
        for (m in month) {
            total = sprintf("%.2fMB", month[m]);
            avg = sprintf("%.2fMB", (month[m]/count[m]));
            
            printf format, 
                substr(m,1,4) "-" substr(m,5,2),
                total,
                avg,
                count[m]
        }
    }' | sort
}

# Main menu
while true; do
    echo
    echo "Backup Reporting Utility"
    echo "----------------------"
    echo "1. Show latest backup summary"
    echo "2. View backup history"
    echo "3. Show space usage trends"
    echo "4. Generate full report"
    echo "5. Exit"
    echo
    read -p "Select an option (1-5): " choice

    case $choice in
        1)
            generate_latest_summary
            ;;
        2)
            show_backup_history
            ;;
        3)
            analyze_space_trends
            ;;
        4)
            TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
            REPORT_PATH="$REPORT_DIR/backup_report_${TIMESTAMP}.txt"

            echo "Full Backup Report" > "$REPORT_PATH"
            echo "=================" >> "$REPORT_PATH"
            echo >> "$REPORT_PATH"
            generate_latest_summary >> "$REPORT_PATH"
            echo >> "$REPORT_PATH"
            show_backup_history >> "$REPORT_PATH"
            echo >> "$REPORT_PATH"
            analyze_space_trends >> "$REPORT_PATH"
            echo "Report generated: $REPORT_PATH"
            ;;
        5)
            echo "Exiting..."
            exit 0
            ;;
        *)
            echo "Invalid option"
            ;;
    esac
done
