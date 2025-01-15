#!/bin/bash
#
# This script installs the dependencies and configures the basic parameters for the package
#

sudo apt install lftp

echo "Welcome to the installation of Station Manager"
echo "=============================================="
echo ""
echo "To install the software, you must follow the next steps:"
echo "1) In the config folder, copy global.config.new to /etc/global.config and setup all the sections that are needed."
echo "2) The most important setting is SCRIPTS_BASE_PATH which should be set to the installation dir. Everything that needs a setting is between <>"

# get installation folder
folder=`pwd`

(crontab -l 2>/dev/null; echo "# m h  dom mon dow   command") | crontab -
(crontab -l 2>/dev/null; echo "@reboot         ${folder}/scripts/config/initialize.sh") | crontab -
(crontab -l 2>/dev/null; echo "@daily          ${folder}/scripts/config/update.sh ${folder}") | crontab -
(crontab -l 2>/dev/null; echo "@daily          ${folder}/scripts/autodelete/autodelete.sh") | crontab -
(crontab -l 2>/dev/null; echo "@hourly         ${folder}/scripts/FTP/ftp_push.sh") | crontab -
(crontab -l 2>/dev/null; echo "0 1-23/2 * * *  ${folder}/scripts/FTP/ftp_pull.sh") | crontab -
(crontab -l 2>/dev/null; echo "59 23 * * *     ${folder}/scripts/log/log_daily.sh") | crontab -
(crontab -l 2>/dev/null; echo "*/10 * * * *    ${folder}/scripts/status/status_update.sh") | crontab -


