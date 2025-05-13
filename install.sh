#!/bin/bash
#
# This script installs the dependencies and configures the basic parameters for the package
#

sudo apt install lftp python3-matplotlib python3-pandas

echo "Welcome to the installation of Station Manager"
echo "=============================================="
echo ""
echo "To install the software, you must follow the next steps:"
echo "1) In the config folder, copy global.config.new to /etc/global.config and setup all the sections that are needed."
echo "2) The most important setting is SCRIPTS_BASE_PATH which should be set to the installation dir. Everything that needs a setting is between <>"

# get installation folder
folder=`pwd`

(crontab -l 2>/dev/null; echo "# m h  dom mon dow   command") | crontab -
(crontab -l 2>/dev/null; echo "@reboot         ${folder}/config/initialize.sh") | crontab -
(crontab -l 2>/dev/null; echo "@daily          ${folder}/config/update.sh ${folder}") | crontab -
(crontab -l 2>/dev/null; echo "@daily          ${folder}/autodelete/autodelete.sh") | crontab -
(crontab -l 2>/dev/null; echo "@hourly         ${folder}/FTP/ftp_push.sh") | crontab -
(crontab -l 2>/dev/null; echo "0 1-23/2 * * *  ${folder}/FTP/ftp_pull.sh") | crontab -
(crontab -l 2>/dev/null; echo "59 23 * * *     ${folder}/log/log_daily.sh") | crontab -
(crontab -l 2>/dev/null; echo "*/10 * * * *    ${folder}/status/status_update.sh") | crontab -

# apply permissions to files
chmod +x ${folder}/config/initialize.sh
chmod +x ${folder}/config/update.sh
chmod +x ${folder}/autodelete/autodelete.sh
chmod +x ${folder}/FTP/ftp_push.sh
chmod +x ${folder}/FTP/ftp_pull.sh
chmod +x ${folder}/NTRIP/ntrip_server-v2_3.sh
chmod +x ${folder}/NTRIP/ntrip_server-v3_0.sh
chmod +x ${folder}/NTRIP/ntripserver
chmod +x ${folder}/log/log_daily.sh
chmod +x ${folder}/status/status_update.sh

echo "INSTALLATION SUCCEEDED"
echo "======================"
