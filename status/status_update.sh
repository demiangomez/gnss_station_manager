#!/bin/bash
#
# Este script consulta el estado de los servidores HTTP y FTP de los servidores
# y a partir de los resultados, envia un mensaje de estado al servidor del IGN
# cada 10 minutos.
# Utiliza el programa "netcat" (nc) para la verificacion y "curl" para el envio
# Para generar el mensaje de estado se utilizan operadores de bit
# 	STATUS = |0|0|0|0|NTRIP_3_0_BIT|NTRIP_2_3_BIT|FTP_BIT|HTTP_BIT| + 1
# 		0 = OK
# 		1 = Error
#

#	STATUS CODE 
#
#	0)  Prohibido
#	1)  OK
#	2)  HTTP 								unavailable
#	3) 		FTP							unavailable
#	4)  HTTP	FTP							unavailables
#	5) 				NTRIPv2-3				unavailable 
#	6)  HTTP			NTRIPv2-3 				unavailables
#	7) 		FTP		NTRIPv2-3				unavailables
#	8)  HTTP	FTP		NTRIPv2-3				unavailables
#	9) 						NTRIPv3-0 		unavailable
#	10) HTTP					NTRIPv3-0		unavailables
#	11) 		FTP				NTRIPv3-0		unavailables
#	12) HTTP	FTP				NTRIPv3-0		unavailables
#	13) 				NTRIPv2-3	NTRIPv3-0		unavailables
#	14) HTTP			NTRIPv2-3	NTRIPv3-0		unavailables
#	15) 		FTP		NTRIPv2-3	NTRIPv3-0		unavailables
#	16) HTTP	FTP		NTRIPv2-3	NTRIPv3-0		unavailables


source "/home/pi/scripts/config/global.config"

echo "PID: $$" >> "$LOG_STATUS"

STATUS=0

# Registro de fecha y hora y temperatura del raspberry pi
date "+%Y/%m/%d   %H:%M:%S  raspberry $( vcgencmd measure_temp )" >> "$LOG_STATUS"

# netcat -z: 	Zero-I/O mode [used for scanning]
# 				Devuelve "0" en caso de exito o "1" en caso de error
#				Los valores de salida se obtienen con "$?"
nc -z "$STATUS_RECEIVER_IP" "$STATUS_RECEIVER_HTTP_PORT"
HTTP=$?
nc -z "$STATUS_RECEIVER_IP" "$STATUS_RECEIVER_FTP_PORT"
FTP=$?
#nc -z "$STATUS_RECEIVER_IP" "$STATUS_RECEIVER_NTRIP_2_3_PORT"
#NTRIP_2_3=$?
#nc -z "$STATUS_RECEIVER_IP" "$STATUS_RECEIVER_NTRIP_3_0_PORT"
#NTRIP_3_0=$?

# Generacion del mensaje de estado
(( STATUS|=(HTTP<<$STATUS_RECEIVER_HTTP_SHIFT) ))
(( STATUS|=(FTP<<$STATUS_RECEIVER_FTP_SHIFT) ))
#(( STATUS|=(NTRIP_2_3<<$STATUS_RECEIVER_NTRIP_2_3_SHIFT) ))
#(( STATUS|=(NTRIP_3_0<<$STATUS_RECEIVER_NTRIP_3_0_SHIFT) ))
(( STATUS+=1 ))

# Envio de mensaje segun estado
echo "Sending status code $STATUS - ${STATUS_MSG[$STATUS]}" >> "$LOG_STATUS"
curl "$STATUS_SERVER"="$STATUS"
echo >> "$LOG_STATUS"

# sleep $STATUS_UPDATE_RATE

# seccion para actualizacion remota de los programas
# autodelete/autodelete
# config/initialize.sh
# FTP/ftp_push.sh
# FTP/ftp_pull.sh
# log/log_daily.sh
# met/wxAlign.py.py
# met/wxReceive.py
# status/status.sh

