#!/bin/bash


ALLOWLIST="/etc/usb_allowlist.txt"                  # File containing allowed USB VID:PID 
LOG_FILE="/var/log/usb_blocker.log"                 # Log file for USB access attempts
DATE=$(date '+%Y-%m-%d %H:%M:%S')                   # Timestamp for logging

# verify the allow list
if [ ! -f "$ALLOWLIST" ]; then
    echo "$DATE - ERROR: Allowlist file not found: $ALLOWLIST" >> "$LOG_FILE"
    echo "Allowlist file missing!" | mail -s "USB Blocker Error" sanayrinku@gmail.com
    exit 1
fi

# Detect USB connected
USB_DEVICES=$(lsblk -S | grep -i usb | awk '{print $1}')

if [ -z "$USB_DEVICES" ]; then
    echo "$DATE - INFO: No USB devices currently connected." >> "$LOG_FILE"
    exit 0
fi

# process each device
for dev in $USB_DEVICES; do
    DEV_PATH="/dev/$dev"

# get device ID
    VID=$(udevadm info --query=all --name="$DEV_PATH" | grep -i ID_VENDOR_ID | cut -d= -f2)
    PID=$(udevadm info --query=all --name="$DEV_PATH" | grep -i ID_MODEL_ID | cut -d= -f2)

    if [[ -z "$VID" || -z "$PID" ]]; then
        echo "$DATE - WARNING: Could not retrieve VID:PID for $DEV_PATH" >> "$LOG_FILE"
        continue
    fi

    VID_PID="${VID}:${PID}"

    # checking allow list 
    if grep -q "$VID_PID" "$ALLOWLIST"; then
        echo "$DATE - ALLOWED: USB device $VID_PID connected at $DEV_PATH" >> "$LOG_FILE"
    else
        # unauthorized detected
        MOUNT_POINTS=$(lsblk -ln -o MOUNTPOINT "$DEV_PATH" | grep '^/')

        if [ -n "$MOUNT_POINTS" ]; then
            for mount in $MOUNT_POINTS; do
                umount "$mount" 2>> "$LOG_FILE"
                if [ $? -eq 0 ]; then
                    echo "$DATE - BLOCKED: Unauthorized USB ($VID_PID) unmounted from $mount" >> "$LOG_FILE"
                else
                    echo "$DATE - ERROR: Failed to unmount unauthorized USB ($VID_PID) at $mount" >> "$LOG_FILE"
                fi
            done
        else
            echo "$DATE - BLOCKED: Unauthorized USB device $VID_PID detected (not mounted), no unmount needed." >> "$LOG_FILE"
        fi

        # send alert email to admin
        echo "Unauthorized USB device detected: $VID_PID at $DEV_PATH" | mail -s "🚨 USB Security Alert" sanayrinku@gmail.com
    fi
done
