#!/bin/bash
#
# Este script se ejecuta cada vez que se enciende el raspberry pi.
#
source "/etc/global.config"
sleep 10s

date "+%Y/%m/%d   %H:%M:%S  PID:$$" >> "$LOG_INITIALIZE"

# The first reboot of a fresh station happens before anyone fills in /etc/global.config:
# nothing below can do anything useful with <STNM> and <FTP_BASE>, so start none of it
if ! "${SCRIPTS_BASE_PATH}/config/config_ready.sh"; then
	echo "Station not configured yet: /etc/global.config still has <> placeholders, starting no processes" >> "$LOG_INITIALIZE"
	exit 0
fi

${SCRIPTS_BASE_PATH}/status/status_update.sh &

if [ "$NTRIP_RUN" = "YES" ]; then
	${SCRIPTS_BASE_PATH}/NTRIP/ntrip_server-v2_3.sh &
	${SCRIPTS_BASE_PATH}/NTRIP/ntrip_server-v3_0.sh &
fi

${SCRIPTS_BASE_PATH}/FTP/ftp_pull.sh &
${SCRIPTS_BASE_PATH}/FTP/ftp_push.sh &

if [ "$MET_RUN" = "YES" ]; then
	python ${SCRIPTS_BASE_PATH}/met/wxReceive.py --name ${STNM} --session 1440 --country ARG --dir ${FTP_LOCAL_PATH} --interval 5 --serial ${MET_SERIAL} >> ${LOG_PATH}/log_wx.txt 2>&1 &
fi

if [ "$SOLAR_RUN" = "YES" ]; then
	python ${SCRIPTS_BASE_PATH}/solar_monitor/solar_monitor.py 2>&1 &
fi
