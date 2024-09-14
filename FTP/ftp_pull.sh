#!/bin/bash
#
# This script performs an FTP Pull of the files located at 
# $FTP_RECEIVER_IP to the folder $FTP_LOCAL_PATH using the lftp program.
# It allows up to 3 parallel downloads (receiver's limitation).
# For more information on the settings: https://lftp.yar.ru/lftp-man.html
#

source "/home/pi/scripts/config/global.config"

date "+%Y/%m/%d   %H:%M:%S  PID:$$" 1>> "$LOG_FTP_DOWNLOAD"

if [ -f "$FTP_LOCAL_LIST" ]; then
	# I create a list of already downloaded files to avoid downloading the same files again
	# DDG: also, include the files that were deleted so we don't download them again
	cat ${SCRIPTS_BASE_PATH}/FTP/list_deleted >  ${SCRIPTS_BASE_PATH}/FTP/exclude.txt
	awk '{print $1}' ${FTP_LOCAL_LIST}        >> ${SCRIPTS_BASE_PATH}/FTP/exclude.txt
else
	echo "" > ${SCRIPTS_BASE_PATH}/FTP/exclude.txt
fi

lftp -u "$FTP_RECEIVER_USER","$FTP_RECEIVER_PASS" "$FTP_RECEIVER_IP" <<EOF >> "$LOG_FTP_DOWNLOAD" 2>&1
set cmd:verbose true
set ftp:use-feat off
set mirror:no-empty-dirs true
set mirror:skip-noaccess true
set mirror:set-permissions false
set mirror:parallel-transfer-count $FTP_PARALLEL_PULL
mirror --verbose=1 -I *.$FTP_RECEIVER_FILE_EXTENTION --exclude-rx-from="${SCRIPTS_BASE_PATH}/FTP/exclude.txt" $FTP_RECEIVER_PATH $FTP_LOCAL_PATH
bye
EOF

echo 1>> "$LOG_FTP_DOWNLOAD"

# Using WGET
# wget -m -nH -A ."$FTP_RECEIVER_FILE_EXTENTION" ftp://"$FTP_RECEIVER_USER":"$FTP_RECEIVER_PASS"@"$FTP_RECEIVER_IP$FTP_RECEIVER_PATH" \
# -P "$FTP_LOCAL_PATH" 1>> "$LOG_FTP_DOWNLOAD" 2>> "$LOG_FTP_DOWNLOAD"
