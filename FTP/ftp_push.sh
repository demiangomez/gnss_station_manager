#!/bin/bash
#
# This script performs an FTP Push of the files located in 
# FTP_LOCAL_PATH to the FTP_SERVER_IP server using the lftp program.
# It generates the list of files to upload based on FTP_UPLOADED_LIST and 
# FTP_LOCAL_LIST (it checks for size differences).
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
# DDG: added sort | uniq to upload repeated files only once. The issue is that, when reprogramming a GNSS receiver
#      the directory structure might change leading to two files with the same name. sort | uniq prevents conflicts between 
#      files with same names in different directories
ftp_upload_list=$( comm -23 <(sort $FTP_LOCAL_LIST) <(sort $FTP_UPLOADED_LIST) | sort | uniq | awk '{print $1}' )

echo "List of files to upload:" >> "$LOG_FTP_UPLOAD"
echo $ftp_upload_list | tr ' ' '\n' >> "$LOG_FTP_UPLOAD"

for file_list in $ftp_upload_list
do
	# Searches for the file and retrieves the path
	# this search might lead to a single file or multiple files, depending on the dir structure
	upload_list=$( find "$FTP_LOCAL_PATH" -name "$file_list" -type f)
	
	for filename in $upload_list
    do
	    # Uploads the file with LFTP and stores the exit code in the variable 'result'
	    echo "-----------------------------------------" 1>> "$LOG_FTP_UPLOAD"
	    echo "about to upload $filename" 1>> "$LOG_FTP_UPLOAD"
	    
	    lftp -u "$FTP_SERVER_USER","$FTP_SERVER_PASS" "$FTP_SERVER_IP" <<EOF >> "$LOG_FTP_UPLOAD" 2>&1
        set cmd:verbose true
        set ftp:use-feat off
        cd ${FTP_SERVER_PATH}
        put ${filename}
        bye
EOF
	    result=$?
	    if [ $result -eq 0 ]
	    # If the result is 0 (no error), adds the filename to the uploaded list
	    then
		    ls --size --block-size=1024 "$filename" | awk '{ print "'$file_list'" " " $1 }' >> "$FTP_UPLOADED_LIST"	
	    fi
    done
done
echo 1>> "$LOG_FTP_UPLOAD"


# Using WPUT
#wput --reupload -t3 "$upload_file" ftp://"$FTP_SERVER_USER":"$FTP_SERVER_PASS"@"$FTP_SERVER_IP" --proxy=172.20.203.111 \ 
