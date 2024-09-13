#!/bin/bash
#
# Este script verifica que el directorio $AUTODELETE_PATH pese menos que
# AUTODELETE_MAX_SIZE. Si no pasa, busca el archivo mas antiguo y 
# lo borra iterativamente hasta que SIZE sea menor a AUTODELETE_MAX_SIZE
#

source "/home/pi/scripts/config/global.config"

# Registro de fecha y hora
date "+%Y/%m/%d   %H:%M:%S" 1>> "$LOG_AUTODELETE"
echo 1>> "$LOG_AUTODELETE"

# Tamano de la carpeta (en MB)
SIZE=$( du -s -B 1M $AUTODELETE_PATH | cut -f1 )

echo "Current size: $SIZE Max size: $AUTODELETE_MAX_SIZE" >> "$LOG_AUTODELETE"

while [ $SIZE -gt $AUTODELETE_MAX_SIZE ] 
do	
	# Se genera un listado de todos los archivos, los ordena y obtiene el primero de la lista (mas antiguo)
	OLDEST_FILE=$( find $AUTODELETE_PATH -type f -printf '%T+ %p\n' | sort | awk 'NR==1{print $2}' )
	
	# Eliminacion del archivo mas antiguo
	echo "Deleting $OLDEST_FILE" >> "$LOG_AUTODELETE"
	rm "$OLDEST_FILE"
	
	# Actualizacion del tamano (en MB)
	SIZE=$( du -s -B 1M $AUTODELETE_PATH | cut -f1 )
done
echo 1>> "$LOG_AUTODELETE"
