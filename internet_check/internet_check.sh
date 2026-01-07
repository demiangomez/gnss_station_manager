#!/bin/bash
#
# This script checks for internet connectivity and reboots
# the system after consecutive failures.
#

source "/etc/global.config"

# Log with timestamp and PID
date "+%Y/%m/%d   %H:%M:%S  PID: $$" >> "$LOG_INTERNET_CHECK"

# State file to track consecutive failures
FAILURE_COUNT_FILE="${SCRIPTS_BASE_PATH}/internet_check/failure_count"

# Initialize failure count file if it doesn't exist
if [ ! -f "$FAILURE_COUNT_FILE" ]; then
    echo "0" > "$FAILURE_COUNT_FILE"
fi

# Read current failure count
FAILURE_COUNT=$(cat "$FAILURE_COUNT_FILE")

# Check internet by pinging hosts (returns 0 if any succeeds)
check_internet() {
    for host in $INTERNET_CHECK_HOSTS; do
        if ping -c 1 -W $INTERNET_CHECK_TIMEOUT "$host" > /dev/null 2>&1; then
            return 0
        fi
    done
    return 1
}

# Perform the check
if check_internet; then
    echo "Internet OK" >> "$LOG_INTERNET_CHECK"
    echo "0" > "$FAILURE_COUNT_FILE"
else
    FAILURE_COUNT=$((FAILURE_COUNT + 1))
    echo "$FAILURE_COUNT" > "$FAILURE_COUNT_FILE"
    echo "Internet FAILED (attempt $FAILURE_COUNT of $INTERNET_CHECK_MAX_FAILURES)" >> "$LOG_INTERNET_CHECK"

    if [ "$FAILURE_COUNT" -ge "$INTERNET_CHECK_MAX_FAILURES" ]; then
        echo "Max failures reached. Rebooting system..." >> "$LOG_INTERNET_CHECK"
        echo "0" > "$FAILURE_COUNT_FILE"
        sync
        sudo reboot
    fi
fi

echo >> "$LOG_INTERNET_CHECK"
