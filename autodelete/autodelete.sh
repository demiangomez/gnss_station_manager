#!/bin/bash
#
# This script checks that the directory $AUTODELETE_PATH is smaller than
# AUTODELETE_MAX_SIZE. If it's not, it finds the oldest file and
# deletes it iteratively until the SIZE is less than AUTODELETE_MAX_SIZE
#

source "/home/pi/scripts/config/global.config"

# Save datetime
date "+%Y/%m/%d   %H:%M:%S" 1>> "$LOG_AUTODELETE"
echo 1>> "$LOG_AUTODELETE"

# get folder size (in MB)
SIZE=$( du -s -B 1M $AUTODELETE_PATH | cut -f1 )

echo "Current size: $SIZE Max size: $AUTODELETE_MAX_SIZE" >> "$LOG_AUTODELETE"

while [ $SIZE -gt $AUTODELETE_MAX_SIZE ] 
do	
	# A list of all files is generated, sorted, and the first one in the list (oldest) is obtained
	OLDEST_FILE=$( find $AUTODELETE_PATH -type f -printf '%T+ %p\n' | sort | awk 'NR==1{print $2}' )
	
	# Delete file and save its name
	echo "Deleting $OLDEST_FILE" >> "$LOG_AUTODELETE"
	echo $(basename ${OLDEST_FILE}) >> ${SCRIPTS_BASE_PATH}/FTP/list_deleted
	rm "$OLDEST_FILE"
	
	# update size (in MB)
	SIZE=$( du -s -B 1M $AUTODELETE_PATH | cut -f1 )
done
echo 1>> "$LOG_AUTODELETE"
