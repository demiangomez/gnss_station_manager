#!/bin/bash
#
# Este script ejecuta el programa "ntripserver". Transmite las correcciones
# RTCM v3.0 del receptor asociado al Caster NTRIP del IGN.
# Para mas informacion del setting ver archivo README
#

source "/home/pi/scripts/config/global.config"

echo "PID: $$" >> "$LOG_NTRIP_v3_0"
echo >> "$LOG_NTRIP_v3_0"

while true; do
	# Registro de fecha y hora
	date "+%Y/%m/%d   %H:%M:%S" >> "$LOG_NTRIP_v3_0"
	
	# Ejecucion del ntripserver
	"$NTRIP_PATH"/ntripserver -M "$NTRIP_SERVER_INPUT_MODE" \
	-H "$NTRIP_SOURCE_IP" -P "$NTRIP_SOURCE_PORTv3_0" -O "$NTRIP_SERVER_OUTPUT_MODE" \
	-a "$NTRIP_CASTER_IP" -p "$NTRIP_CASTER_PORT" -m "$NTRIP_CASTER_MOUNTPOINTv3_0" -c "$NTRIP_CASTER_PASS" \
	1>> "$LOG_NTRIP_v3_0" 2>> "$LOG_NTRIP_v3_0"
	
	# En caso de error, registra fecha y hora y vuelve a conectarse en 60 segundos
	date "+%Y/%m/%d   %H:%M:%S: reconnect in <60> seconds" >> "$LOG_NTRIP_v3_0"
	echo >> "$LOG_NTRIP_v3_0"
	sleep 60s
done
