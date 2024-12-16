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
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "./logs/report.log"
    echo "$1"
}

# Function to generate summary of latest backup


