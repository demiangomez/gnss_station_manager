#!/bin/bash
#
# This script installs the dependencies and configures the basic parameters for the package
#

# get installation folder
folder=`pwd`

# The cron jobs are installed in the crontab of whoever runs this script, and they
# must belong to the station user: internet_check.sh calls sudo itself
if [ "$(id -u)" -eq 0 ]; then
    echo "ERROR: run install.sh as the station user, not as root and not with sudo." >&2
    exit 1
fi

# Everything that follows needs root at some point: the packages, the sudoers rule,
# the watchdog drop-in and, later on, the reboot issued by internet_check.sh
if ! sudo -n true 2>/dev/null && ! sudo -v; then
    echo "ERROR: `id -un` cannot use sudo on this machine and the installation needs it." >&2
    echo "Add the user to the sudo group (as root: adduser `id -un` sudo), log in again and re-run." >&2
    exit 1
fi

# First step, so the rest of the install and every unattended job runs without prompting
chmod +x ${folder}/config/enable_nopasswd_sudo.sh
if ! ${folder}/config/enable_nopasswd_sudo.sh; then
    echo "ERROR: could not enable passwordless sudo, aborting the installation." >&2
    echo "Without it internet_check.sh cannot reboot the station when the link goes down." >&2
    exit 1
fi

sudo apt install lftp python3-matplotlib python3-pandas netcat-openbsd

echo "Welcome to the installation of Station Manager"
echo "=============================================="
echo ""
echo "To install the software, you must follow the next steps:"
echo "1) In the config folder, copy global.config.new to /etc/global.config and setup all the sections that are needed."
echo "2) The most important setting is SCRIPTS_BASE_PATH which should be set to the installation dir. Everything that needs a setting is between <>"

(crontab -l 2>/dev/null; echo "# m h  dom mon dow   command") | crontab -
(crontab -l 2>/dev/null; echo "@reboot         ${folder}/config/initialize.sh") | crontab -
(crontab -l 2>/dev/null; echo "@daily          ${folder}/config/update.sh ${folder}") | crontab -
(crontab -l 2>/dev/null; echo "@daily          ${folder}/autodelete/autodelete.sh") | crontab -
(crontab -l 2>/dev/null; echo "@hourly         ${folder}/FTP/ftp_push.sh") | crontab -
(crontab -l 2>/dev/null; echo "0 1-23/2 * * *  ${folder}/FTP/ftp_pull.sh") | crontab -
(crontab -l 2>/dev/null; echo "59 23 * * *     ${folder}/log/log_daily.sh") | crontab -
(crontab -l 2>/dev/null; echo "*/10 * * * *    ${folder}/status/status_update.sh") | crontab -
(crontab -l 2>/dev/null; echo "*/5 * * * *     ${folder}/internet_check/internet_check.sh") | crontab -

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
chmod +x ${folder}/internet_check/internet_check.sh
chmod +x ${folder}/config/enable_watchdog.sh

# A station without a working watchdog is still usable, so this only warns
if ! ${folder}/config/enable_watchdog.sh; then
    echo "WARNING: the hardware watchdog is NOT active on this station, see the message above"
fi

echo "INSTALLATION SUCCEEDED"
echo "======================"
