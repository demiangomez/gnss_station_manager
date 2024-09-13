#!/bin/bash
#
# Este script realiza un FTP Push de los archivos que se encuentran en 
# FTP_LOCAL_PATH al servidor FTP_SERVER_IP utilizando el programa lftp
# Genera el listado de archivos a subir a partir de FTP_UPLOADED_LIST y
# FTP_LOCAL_LIST (se fija en las diferencias de peso).
#
# Las listas tienen un formato "<FILENAME> <SIZE in KB>" en cada línea
#

source "/home/pi/scripts/config/global.config"

date "+%Y/%m/%d   %H:%M:%S  PID: $$" 1>> "$LOG_FTP_UPLOAD"

# Actualizo el listado de nombres de los archivos en FTP_LOCAL_PATH
ls --size --block-size=1024 -R "$FTP_LOCAL_PATH" | awk '/'$FTP_SERVER_FILE_EXTENTION'/{ print $2 " " $1 }' > $FTP_LOCAL_LIST

# DDG: chequeo que exista $FTP_UPLOADED_LIST, sino lo creo
if [ ! -f "$FTP_UPLOADED_LIST" ]; then
	touch $FTP_UPLOADED_LIST
fi

# Listado de nombre de los archivos a subir (los que no existen o tengan distinto peso en el listado de subidos)
# Ver documentacion del programa 'comm'
ftp_upload_list=$( comm -23 <(sort $FTP_LOCAL_LIST) <(sort $FTP_UPLOADED_LIST) | awk '{print $1}' )

for filename in $ftp_upload_list
do
	# Busca el archivo y obtiene la ruta
	upload_file=$( find "$FTP_LOCAL_PATH" -name "$filename" -type f -printf '%p' )
	
	# Sube el archivo con LFTP y almacena el codigo de salida en la variable result
	echo "$filename" 1>> "$LOG_FTP_UPLOAD"
	lftp -u "$FTP_SERVER_USER","$FTP_SERVER_PASS" "$FTP_SERVER_IP" -e "set cmd:verbose true; set ftp:use-feat off; cd ${FTP_SERVER_PATH}; put ${upload_file};bye" >> "$LOG_FTP_UPLOAD" 2>&1
	result=$?
	if [ $result -eq 0 ]
	# Si el resultado es 0 (no error) agrega el nombre del archivo a la lista de subidos
	then
		ls --size --block-size=1024 "$upload_file" | awk '{ print "'$filename'" " " $1 }' >> "$FTP_UPLOADED_LIST"	
	fi
done
echo 1>> "$LOG_FTP_UPLOAD"


# Usando WPUT
#wput --reupload -t3 "$upload_file" ftp://"$FTP_SERVER_USER":"$FTP_SERVER_PASS"@"$FTP_SERVER_IP" --proxy=172.20.203.111 \ 
