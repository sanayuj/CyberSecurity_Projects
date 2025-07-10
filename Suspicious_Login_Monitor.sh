#!/bin/bash


LOG_FILE="/var/log/auth.log"                      # Log file  (if you are using Redhat OS then using this path /var/log/secure)
BLOCK_LOG="/var/log/suspicious_logins.log"        # Log of blocked IPs
THRESHOLD=5                                       # Number of failed attempts before blocking
DATE=$(date '+%Y-%m-%d %H:%M:%S')                 # Current timestamp

#Function to check if IP is already blocked 

is_blocked() {
    iptables -L INPUT -v -n | grep -q "$1"
    return $?
}

#Extract Failed SSH Login Attempts 

FAILED_IPS=$(grep "Failed password" "$LOG_FILE" | \
    awk '{for(i=1;i<=NF;i++) if ($i=="from") print $(i+1)}' | \
    sort | uniq -c)

#Process Each Offending IP 

echo "$FAILED_IPS" | while read -r COUNT IP; do
    if [ "$COUNT" -gt "$THRESHOLD" ]; then
        if ! is_blocked "$IP"; then
            #Block IP using iptables
            iptables -A INPUT -s "$IP" -j DROP

            #Log the action
            echo "$DATE - Blocked IP $IP after $COUNT failed login attempts" >> "$BLOCK_LOG"
        fi
    fi
done
