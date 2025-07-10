#!/bin/bash


WATCHED_FILES=(
    "/etc/passwd"
    "/etc/shadow"
    "/etc/ssh/sshd_config"
)  # List of sensitive files 

CHECKSUM_DB="/var/lib/file_integrity_db.sha256"
LOG_FILE="/var/log/file_integrity.log"
DATE=$(date '+%Y-%m-%d %H:%M:%S')

# creating DB
if [ ! -f "$CHECKSUM_DB" ]; then
    echo "$DATE - First run: generating baseline checksums..." >> "$LOG_FILE"
    for file in "${WATCHED_FILES[@]}"; do
        if [ -f "$file" ]; then
            sha256sum "$file" >> "$CHECKSUM_DB"
        fi
    done
    echo "$DATE - Baseline checksums created." >> "$LOG_FILE"
    exit 0
fi


for file in "${WATCHED_FILES[@]}"; do
    if [ -f "$file" ]; then
        CURRENT_SUM=$(sha256sum "$file")
        BASELINE_SUM=$(grep " $file\$" "$CHECKSUM_DB")

        if [[ "$CURRENT_SUM" != "$BASELINE_SUM" ]]; then
            echo "$DATE - ALERT: File modified or tampered: $file" >> "$LOG_FILE"
            echo "$file has been modified!" | mail -s "File Integrity Alert" sanayrinku@gmail.com
        fi
    else
        echo "$DATE - WARNING: File not found: $file" >> "$LOG_FILE"
    fi
done
