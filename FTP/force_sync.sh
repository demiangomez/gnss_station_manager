#!/bin/bash
#
# This script forces the system to sync FTP_UPLOADED_LIST with FTP_LOCAL_LIST
# without uploading files to the FTP. The goal is when a system is initialized on
# an existing system
#
# The lists have a format "<FILENAME> <SIZE in KB>" on each line.
#

source "/etc/global.config"

date "+%Y/%m/%d   %H:%M:%S  PID: $$" 1>> "$LOG_FTP_UPLOAD"

# create the station directory if it does not exist
if [ ! -d "$FTP_LOCAL_PATH" ]; then
  mkdir -p "$FTP_LOCAL_PATH"
fi

# I update the list of filenames in FTP_LOCAL_PATH
# DDG: there is a conflict with file deletion: the autodelete process deletes files when we hit a limit determined by AUTODELETE_MAX_SIZE.
#      The local list is regenerated with the files in the directory, which are still in the receiver, so the pull process downloads them again
#      Now the pull process checks files that were deleted so as to not download them again
ls --size --block-size=1024 -R "$FTP_LOCAL_PATH" | awk '/'$FTP_SERVER_FILE_EXTENTION'/{ print $2 " " $1 }' > $FTP_LOCAL_LIST

# DDG: check if $FTP_UPLOADED_LIST exists, if not, create it
if [ ! -f "$FTP_UPLOADED_LIST" ]; then
	touch "$FTP_UPLOADED_LIST"
fi

# List of filenames to upload (those that don't exist or have a different size in the uploaded list)
# See documentation for the 'comm' program
ftp_upload_list=$( comm -23 <(sort $FTP_LOCAL_LIST) <(sort $FTP_UPLOADED_LIST) | awk '{print $1}' )

for filename in $ftp_upload_list
do
	# Searches for the file and retrieves the path
	upload_file=$( find "$FTP_LOCAL_PATH" -name "$filename" -type f -printf '%p' )
	
	# Uploads the file with LFTP and stores the exit code in the variable 'result'
	echo "syncing $filename" 1>> "$LOG_FTP_UPLOAD"
    ls --size --block-size=1024 "$upload_file" | awk '{ print "'$filename'" " " $1 }' >> "$FTP_UPLOADED_LIST"	

done
echo 1>> "$LOG_FTP_UPLOAD"


# Using WPUT
#wput --reupload -t3 "$upload_file" ftp://"$FTP_SERVER_USER":"$FTP_SERVER_PASS"@"$FTP_SERVER_IP" --proxy=172.20.203.111 \ 
