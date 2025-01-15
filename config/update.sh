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

# apply permissions to files again
chomod +x ${SCRIPTS_BASE_PATH}/config/initialize.sh
chomod +x ${SCRIPTS_BASE_PATH}/config/update.sh
chomod +x ${SCRIPTS_BASE_PATH}/autodelete/autodelete.sh
chomod +x ${SCRIPTS_BASE_PATH}/FTP/ftp_push.sh
chomod +x ${SCRIPTS_BASE_PATH}/FTP/ftp_pull.sh
chomod +x ${SCRIPTS_BASE_PATH}/NTRIP/ntrip_server-v2_3.sh
chomod +x ${SCRIPTS_BASE_PATH}/NTRIP/ntrip_server-v3_0.sh
chomod +x ${SCRIPTS_BASE_PATH}/NTRIP/ntripserver
chomod +x ${SCRIPTS_BASE_PATH}/log/log_daily.sh
chomod +x ${SCRIPTS_BASE_PATH}/status/status_update.sh

