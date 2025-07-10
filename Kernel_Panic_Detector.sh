#!/bin/bash

LOG_FILES=("/var/log/syslog" "/var/log/messages" "/var/log/kern.log")  
KEYWORDS=("kernel panic" "Kernel panic" "Oops" "BUG" "stack trace")
ALERT_LOG="/var/log/kernel_panic_alerts.log"
DATE=$(date '+%Y-%m-%d %H:%M:%S')
ADMIN_EMAIL="sanayrinku@gmail.com"

# check for log file
FOUND_LOG=""
for log in "${LOG_FILES[@]}"; do
    if [ -f "$log" ]; then
        FOUND_LOG="$log"
        break
    fi
done

if [ -z "$FOUND_LOG" ]; then
    echo "$DATE - ERROR: No kernel log file found!" >> "$ALERT_LOG"
    echo "Kernel panic detector could not find any log files to scan!" | mail -s "Kernel Panic Monitor Error" "$ADMIN_EMAIL"
    exit 1
fi
# search for panic process
PANIC_FOUND=0
for keyword in "${KEYWORDS[@]}"; do
    if grep -qi "$keyword" "$FOUND_LOG"; then
        PANIC_FOUND=1
        break
    fi
done

# handle panic event
if [ $PANIC_FOUND -eq 1 ]; then
    MATCHES=$(grep -iE "kernel panic|Oops|BUG|stack trace" "$FOUND_LOG" | tail -n 20)
    echo "$DATE - ALERT: Kernel panic detected!" >> "$ALERT_LOG"
    echo "$MATCHES" >> "$ALERT_LOG"

    echo -e "ALERT: Kernel panic or crash detected on the system.\n\nDetails:\n$MATCHES" | \
        mail -s "🚨 Kernel Panic Detected on $(hostname)" "$ADMIN_EMAIL"
else
    echo "$DATE - OK: No kernel panic messages found in $FOUND_LOG" >> "$ALERT_LOG"
fi
