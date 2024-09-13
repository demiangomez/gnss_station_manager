#!/bin/bash
#
# Este script genera un logfile diario concatenando los log files 
# individuales (FTP download/upload, NTRIP server v2.3/v3.0, status) 
# y luego "limpia" dichos archivos.
#

source "/home/pi/scripts/config/global.config"

# Generacion del nombre del logfile diario
DATE=$( date "+%Y%m%d" ) 
LOGFILE="$LOG_PATH/log_$DATE.txt"

# Comienzo del archivo con fecha y hora
DATE=$(date "+%Y/%m/%d   %H:%M:%S") 
echo "Logging date: $DATE">> "$LOGFILE"
echo >> "$LOGFILE"

# Log: Initialize
echo "=========== Log: Initialize ===========" >> "$LOGFILE"
cat "$LOG_INITIALIZE" >> "$LOGFILE"
echo >> "$LOGFILE"

# Log: FTP Pull
echo "=========== Log: FTP Pull ===========" >> "$LOGFILE"
cat "$LOG_FTP_DOWNLOAD" >> "$LOGFILE"
echo >> "$LOGFILE"

# Log: FTP Push
echo "=========== Log: FTP Push ===========" >> "$LOGFILE"
cat "$LOG_FTP_UPLOAD" >> "$LOGFILE"
echo >> "$LOGFILE"

# Log: NTRIP Server v2.3
echo "=========== Log: NTRIP Server v2.3 ===========" >> "$LOGFILE"
cat "$LOG_NTRIP_v2_3" >> "$LOGFILE"
echo >> "$LOGFILE"

# Log: NTRIP Server v3.0
echo "=========== Log: NTRIP Server v3.0 ===========" >> "$LOGFILE"
cat "$LOG_NTRIP_v3_0" >> "$LOGFILE"
echo >> "$LOGFILE"

# Log: Status
echo "=========== Log: Status ===========" >> "$LOGFILE"
cat "$LOG_STATUS" >> "$LOGFILE"
echo >> "$LOGFILE"

# Log: Autodelete
echo "=========== Log: Autodelete ===========" >> "$LOGFILE"
cat "$LOG_AUTODELETE" >> "$LOGFILE"
echo >> "$LOGFILE"

# Finalizacion del archivo con fecha y hora
DATE=$(date "+%Y/%m/%d   %H:%M:%S")
echo "End logging date: $DATE">> "$LOGFILE"
echo >> "$LOGFILE"

# Limpio los logfiles individiales
# (se truncan los archivos a 0)
truncate -s 0 	"$LOG_INITIALIZE" \
				"$LOG_FTP_DOWNLOAD" \
				"$LOG_FTP_UPLOAD" \
				"$LOG_NTRIP_v2_3" \
				"$LOG_NTRIP_v3_0" \
				"$LOG_STATUS" \
				"$LOG_AUTODELETE"
