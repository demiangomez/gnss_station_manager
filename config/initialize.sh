#!/bin/bash
#
# Este script se ejecuta cada vez que se enciende el raspberry pi.
#
source "/home/pi/scripts/config/global.config"
sleep 10s

date "+%Y/%m/%d   %H:%M:%S  PID:$$" >> "$LOG_INITIALIZE"

${SCRIPTS_BASE_PATH}/status/status_update.sh &
#${SCRIPTS_BASE_PATH}/NTRIP/ntrip_server-v2_3.sh &
#${SCRIPTS_BASE_PATH}/NTRIP/ntrip_server-v3_0.sh &
${SCRIPTS_BASE_PATH}/FTP/ftp_pull.sh &
${SCRIPTS_BASE_PATH}/FTP/ftp_push.sh &
python ${SCRIPTS_BASE_PATH}/met/wxReceive.py --name ${STNM} --session 1440 --country ARG --dir ${FTP_LOCAL_PATH} --interval 5 --serial ${MET_SERIAL} >> ${LOG_PATH}/log_wx.txt 2>&1 &

