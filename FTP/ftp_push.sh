#!/bin/bash
#
# This script performs an FTP Push of the files located in 
# FTP_LOCAL_PATH to the FTP_SERVER_IP server using the lftp program.
# It generates the list of files to upload based on FTP_UPLOADED_LIST and 
# FTP_LOCAL_LIST (it checks for size differences).
#
# The lists have a format "<FILENAME> <SIZE in KB>" on each line.
#

source "/home/pi/scripts/config/global.config"

date "+%Y/%m/%d   %H:%M:%S  PID: $$" 1>> "$LOG_FTP_UPLOAD"

# I update the list of filenames in FTP_LOCAL_PATH
# DDG: there is a conflict with file deletion: the autodelete process deletes files when we hit a limit determined by AUTODELETE_MAX_SIZE.
#      The local list is regenerated with the files in the directory, which are still in the receiver, so the pull process downloads them again
#      Thus, this list cannot be regenerated but rather it should  
ls --size --block-size=1024 -R "$FTP_LOCAL_PATH" | awk '/'$FTP_SERVER_FILE_EXTENTION'/{ print $2 " " $1 }' > $FTP_LOCAL_LIST

# DDG: check if $FTP_UPLOADED_LIST exists, if not, create it
if [ ! -f "$FTP_UPLOADED_LIST" ]; then
	touch $FTP_UPLOADED_LIST
fi

# List of filenames to upload (those that don't exist or have a different size in the uploaded list)
# See documentation for the 'comm' program
ftp_upload_list=$( comm -23 <(sort $FTP_LOCAL_LIST) <(sort $FTP_UPLOADED_LIST) | awk '{print $1}' )

for filename in $ftp_upload_list
do
	# Searches for the file and retrieves the path
	upload_file=$( find "$FTP_LOCAL_PATH" -name "$filename" -type f -printf '%p' )
	
	# Uploads the file with LFTP and stores the exit code in the variable 'result'
	echo "$filename" 1>> "$LOG_FTP_UPLOAD"
	lftp -u "$FTP_SERVER_USER","$FTP_SERVER_PASS" "$FTP_SERVER_IP" -e "set cmd:verbose true; set ftp:use-feat off; cd ${FTP_SERVER_PATH}; put ${upload_file};bye" >> "$LOG_FTP_UPLOAD" 2>&1
	result=$?
	if [ $result -eq 0 ]
	# If the result is 0 (no error), adds the filename to the uploaded list
	then
		ls --size --block-size=1024 "$upload_file" | awk '{ print "'$filename'" " " $1 }' >> "$FTP_UPLOADED_LIST"	
	fi
done
echo 1>> "$LOG_FTP_UPLOAD"


# Using WPUT
#wput --reupload -t3 "$upload_file" ftp://"$FTP_SERVER_USER":"$FTP_SERVER_PASS"@"$FTP_SERVER_IP" --proxy=172.20.203.111 \ 
