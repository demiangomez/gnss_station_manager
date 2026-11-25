#!/bin/bash
#
# This script checks for internet connectivity and reboots
# the system after consecutive failures.
#

source "/etc/global.config"

# Blank hosts would fail every check and a zero/invalid threshold reboots on the first failure: treat as disabled
[[ -n "$INTERNET_CHECK_HOSTS" && "$INTERNET_CHECK_MAX_FAILURES" =~ ^[1-9][0-9]*$ ]] || exit 0

# Log with timestamp and PID
date "+%Y/%m/%d   %H:%M:%S  PID: $$" >> "$LOG_INTERNET_CHECK"

# State file to track consecutive failures
FAILURE_COUNT_FILE="${SCRIPTS_BASE_PATH}/internet_check/failure_count"
# Reboots since the internet was last up; each one doubles the failures needed before the next
REBOOT_COUNT_FILE="${SCRIPTS_BASE_PATH}/internet_check/reboot_count"
# Never wait more than one day of 5-minute checks between reboots
MAX_THRESHOLD=288

# Initialize failure count file if it doesn't exist
if [ ! -f "$FAILURE_COUNT_FILE" ]; then
    echo "0" > "$FAILURE_COUNT_FILE"
fi

# Read current failure count
FAILURE_COUNT=$(cat "$FAILURE_COUNT_FILE")

REBOOT_COUNT=$(cat "$REBOOT_COUNT_FILE" 2>/dev/null)
[[ "$REBOOT_COUNT" =~ ^[0-9]+$ ]] || REBOOT_COUNT=0

# Ping each host, falling back to TCP 443 since some links block ICMP while TCP works
check_internet() {
    for host in $INTERNET_CHECK_HOSTS; do
        if ping -c 1 -W $INTERNET_CHECK_TIMEOUT "$host" > /dev/null 2>&1; then
            return 0
        fi
        if nc -z -w 3 "$host" 443 > /dev/null 2>&1; then
            return 0
        fi
    done
    # Last resort for networks that block public DNS servers; timeout also bounds the DNS lookup, which nc -w doesn't
    if [ -n "$FTP_SERVER_IP" ] && timeout 10 nc -z -w 3 "$FTP_SERVER_IP" 21 > /dev/null 2>&1; then
        echo "Public hosts unreachable, but FTP server $FTP_SERVER_IP is reachable" >> "$LOG_INTERNET_CHECK"
        return 0
    fi
    return 1
}

# Perform the check
if check_internet; then
    echo "Internet OK" >> "$LOG_INTERNET_CHECK"
    echo "0" > "$FAILURE_COUNT_FILE"
    if [ "$REBOOT_COUNT" -ne 0 ]; then
        echo "Recovered after $REBOOT_COUNT reboot(s)" >> "$LOG_INTERNET_CHECK"
        echo "0" > "$REBOOT_COUNT_FILE"
    fi
else
    # Doubling in a loop (not a shift) so a large reboot count can't overflow
    THRESHOLD=$INTERNET_CHECK_MAX_FAILURES
    for ((i = 0; i < REBOOT_COUNT && THRESHOLD < MAX_THRESHOLD; i++)); do
        THRESHOLD=$((THRESHOLD * 2))
    done
    if [ "$THRESHOLD" -gt "$MAX_THRESHOLD" ]; then
        THRESHOLD=$MAX_THRESHOLD
    fi

    FAILURE_COUNT=$((FAILURE_COUNT + 1))
    echo "$FAILURE_COUNT" > "$FAILURE_COUNT_FILE"
    echo "Internet FAILED (attempt $FAILURE_COUNT of $THRESHOLD)" >> "$LOG_INTERNET_CHECK"

    if [ "$FAILURE_COUNT" -ge "$THRESHOLD" ]; then
        echo "Max failures reached. Rebooting system (reboot $((REBOOT_COUNT + 1)) since internet was last up)..." >> "$LOG_INTERNET_CHECK"
        echo "0" > "$FAILURE_COUNT_FILE"
        echo "$((REBOOT_COUNT + 1))" > "$REBOOT_COUNT_FILE"
        sync
        sudo reboot
    fi
fi

echo >> "$LOG_INTERNET_CHECK"
