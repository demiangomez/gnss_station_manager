#!/bin/bash
#
# Este script realiza un FTP Pull de los archivos que se encuentran en 
# $FTP_RECEIVER_IP a la carpeta $FTP_LOCAL_PATH utilizando el programa lftp
# Permite hasta 3 descargas en paralelo (limitacion del receptor).
# Para mas informacion del setting: https://lftp.yar.ru/lftp-man.html
#

source "/home/pi/scripts/config/global.config"

date "+%Y/%m/%d   %H:%M:%S  PID:$$" 1>> "$LOG_FTP_DOWNLOAD"

if [ -f "$FTP_LOCAL_LIST" ]; then
	# armo una lista de archivos ya descargados para no volver a descargar lo mismo
	awk '{print $1}' ${FTP_LOCAL_LIST} > ${SCRIPTS_BASE_PATH}/FTP/exclude.txt
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


# Usando WGET
#wget -m -nH -A ."$FTP_RECEIVER_FILE_EXTENTION" ftp://"$FTP_RECEIVER_USER":"$FTP_RECEIVER_PASS"@"$FTP_RECEIVER_IP$FTP_RECEIVER_PATH" \
#-P "$FTP_LOCAL_PATH" 1>> "$LOG_FTP_DOWNLOAD" 2>> "$LOG_FTP_DOWNLOAD"
