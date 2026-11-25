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

# SCRIPTS_BASE_PATH is the one setting already known at this point, so it is filled in
# here. An existing /etc/global.config is never overwritten: it holds the station's
# credentials and re-running the installer must not wipe them.
if [ -e /etc/global.config ]; then
    echo "/etc/global.config already exists, left untouched"
    if ! grep -qF "SCRIPTS_BASE_PATH=\"${folder}\"" /etc/global.config; then
        echo "WARNING: it has `grep '^SCRIPTS_BASE_PATH=' /etc/global.config`, but this installation is in ${folder}"
    fi
else
    # Written through a temporary file to land it root-owned and group-readable in one
    # step: it carries the FTP and NTRIP passwords, and only the station user reads it
    tmp_config=`mktemp`
    sed "s|^SCRIPTS_BASE_PATH=.*|SCRIPTS_BASE_PATH=\"${folder}\"|" ${folder}/config/global.config.new > "$tmp_config"
    if sudo install -m 0640 -o root -g `id -gn` "$tmp_config" /etc/global.config; then
        echo "Created /etc/global.config with SCRIPTS_BASE_PATH=\"${folder}\""
    else
        echo "ERROR: could not create /etc/global.config" >&2
    fi
    rm -f "$tmp_config"
fi

echo ""
echo "Settings you still have to fill in by hand in /etc/global.config:"
grep -n "<[A-Z_]*>" /etc/global.config | sed 's/^/    /'
echo ""

# The crontab is built in a variable and written once, adding only the jobs that are
# missing: re-running install.sh on an installed station would otherwise schedule every
# job a second time, which starts two of each @reboot process and makes internet_check.sh
# count failures twice per interval
current_cron=`crontab -l 2>/dev/null`
new_cron="$current_cron"

add_cron_job() {
    # $1: script path, matched against the existing crontab; $2: line to add if missing
    if grep -qF "$1" <<< "$new_cron"; then
        echo "crontab already runs $1, left untouched"
    else
        new_cron=`printf '%s\n%s' "$new_cron" "$2"`
    fi
}

grep -qF "dom mon dow" <<< "$new_cron" || new_cron=`printf '%s\n%s' "$new_cron" "# m h  dom mon dow   command"`
add_cron_job "config/initialize.sh"             "@reboot         ${folder}/config/initialize.sh"
add_cron_job "config/update.sh"                 "@daily          ${folder}/config/update.sh ${folder}"
add_cron_job "autodelete/autodelete.sh"         "@daily          ${folder}/autodelete/autodelete.sh"
add_cron_job "FTP/ftp_push.sh"                  "@hourly         ${folder}/FTP/ftp_push.sh"
add_cron_job "FTP/ftp_pull.sh"                  "0 1-23/2 * * *  ${folder}/FTP/ftp_pull.sh"
add_cron_job "log/log_daily.sh"                 "59 23 * * *     ${folder}/log/log_daily.sh"
add_cron_job "status/status_update.sh"          "*/10 * * * *    ${folder}/status/status_update.sh"
add_cron_job "internet_check/internet_check.sh" "*/5 * * * *     ${folder}/internet_check/internet_check.sh"

if [ "$new_cron" != "$current_cron" ]; then
    printf '%s\n' "$new_cron" | crontab -
fi

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
