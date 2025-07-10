#!/bin/bash


BLACKLIST_URL="https://blocklist.greensnow.co/greensnow.txt"  # IP blacklist source
BLOCK_LOG="/var/log/ip_blacklist_updater.log"   # Log file for blocked IPs
DATE=$(date '+%Y-%m-%d %H:%M:%S')               # Current timestamp
TEMP_FILE="/tmp/blacklist.txt"                  # Temporary file to store fetched IPs

# fetch blacklist
curl -s "$BLACKLIST_URL" -o "$TEMP_FILE"

# Download file source IP
if [ ! -s "$TEMP_FILE" ]; then
    echo "$DATE - ERROR: Failed to download blacklist from $BLACKLIST_URL" >> "$BLOCK_LOG"
    exit 1
fi

# Going through each IP
while read -r IP; do
    # Ignore empty lines and comments
    [[ -z "$IP" || "$IP" == \#* ]] && continue

    # Check if IP is already blocked
    iptables -C INPUT -s "$IP" -j DROP 2>/dev/null
    if [ $? -ne 0 ]; then
       
        iptables -A INPUT -s "$IP" -j DROP  # Block the IP using iptables

        # Log the blocked IP with timestamp
        echo "$DATE - Blocked IP: $IP" >> "$BLOCK_LOG"
    fi
done < "$TEMP_FILE"

# clear temp file
rm -f "$TEMP_FILE"
