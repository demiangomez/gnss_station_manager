#!/bin/bash
#
# Update the scripts using git
#
source "/etc/global.config"

date "+%Y/%m/%d   %H:%M:%S  PID:$$" >> "$LOG_STATUS"

cd $1
echo "Running gnss_station_manager update on `pwd`"
git reset --hard
git pull origin >> "$LOG_STATUS"

