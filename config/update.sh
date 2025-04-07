#!/bin/bash
#
# Update the scripts using git
#
source "/etc/global.config"

date "+%Y/%m/%d   %H:%M:%S  PID:$$" >> "$LOG_STATUS"

cd $1

# get installation folder
folder=`pwd`

echo "Running gnss_station_manager update on `pwd`"
git reset --hard
git pull origin >> "$LOG_STATUS"

# apply permissions to files again
chmod +x ${folder}/config/initialize.sh
chmod +x ${folder}/config/update.sh
chmod +x ${folder}/autodelete/autodelete.sh
chmod +x ${folder}/FTP/ftp_push.sh
chmod +x ${folder}/FTP/ftp_pull.sh
chmod +x ${folder}/NTRIP/ntrip_server-v2_3.sh
chmod +x ${folder}/NTRIP/ntrip_server-v3_0.sh
chmod +x ${folder}/NTRIP/ntripserver
chmod +x ${folder}/log/log_daily.sh
chmod +x ${folder}/status/status_update.sh

