#!/bin/bash
#
# Update the scripts using git
#
source "/etc/global.config"

date "+%Y/%m/%d   %H:%M:%S  PID:$$" >> "$LOG_STATUS"

cd $1

# get installation folder
folder=`pwd`

# Fingerprint this script before the pull: cron started the copy that was on disk, so a
# step added by the pull below would otherwise sit unused until tomorrow's run
update_before=`md5sum "${folder}/config/update.sh" 2>/dev/null`

echo "Running gnss_station_manager update on `pwd`" >> "$LOG_STATUS"
git reset --hard >> "$LOG_STATUS"
git pull origin >> "$LOG_STATUS"
echo "Done updating" >> "$LOG_STATUS"
echo 1>> "$LOG_STATUS"

# Everything below runs from the copy of this script that cron started, so when the pull
# changed it, hand over to the new version and let that one deploy the release. The second
# run pulls again, which is a no-op, and GNSS_UPDATE_REEXEC keeps it to a single handover.
update_after=`md5sum "${folder}/config/update.sh" 2>/dev/null`
if [ -z "$GNSS_UPDATE_REEXEC" ] && [ "$update_before" != "$update_after" ] && [ -x "${folder}/config/update.sh" ]; then
    echo "update.sh changed in this pull, re-running the new version" >> "$LOG_STATUS"
    export GNSS_UPDATE_REEXEC=1
    exec "${folder}/config/update.sh" "$folder"
fi

# Every sudo here is -n, so without passwordless sudo the update still succeeds but
# nothing that needs root takes effect and internet_check.sh cannot reboot the station
if ! sudo -n true 2>/dev/null; then
    echo "WARNING: `id -un` has no passwordless sudo on this station" >> "$LOG_STATUS"
    echo "         Run ${folder}/config/enable_nopasswd_sudo.sh by hand (it asks for the password once)" >> "$LOG_STATUS"
fi

# /etc/global.config is only written at install time, so older stations lack this section
if ! grep -q "^INTERNET_CHECK_HOSTS=" /etc/global.config 2>/dev/null; then
    echo "Adding INTERNET_CHECK configuration to /etc/global.config" >> "$LOG_STATUS"
    if ! {
        echo ""
        echo "#############################"
        echo "# INTERNET CHECK CONFIGURATION"
        echo "#############################"
        echo ""
        grep -E "^(INTERNET_CHECK_HOSTS|INTERNET_CHECK_TIMEOUT|INTERNET_CHECK_MAX_FAILURES|LOG_INTERNET_CHECK)=" "${folder}/config/global.config.new"
    } | sudo -n tee -a /etc/global.config > /dev/null; then
        echo "WARNING: failed to update /etc/global.config" >> "$LOG_STATUS"
    fi
fi

# apply permissions to files again
chmod +x ${folder}/config/initialize.sh
chmod +x ${folder}/config/update.sh
chmod +x ${folder}/autodelete/autodelete.sh
chmod +x ${folder}/FTP/ftp_push.sh
chmod +x ${folder}/FTP/ftp_pull.sh
chmod +x ${folder}/FTP/force_sync.sh
chmod +x ${folder}/NTRIP/ntrip_server-v2_3.sh
chmod +x ${folder}/NTRIP/ntrip_server-v3_0.sh
chmod +x ${folder}/NTRIP/ntripserver
chmod +x ${folder}/log/log_daily.sh
chmod +x ${folder}/status/status_update.sh
chmod +x ${folder}/internet_check/internet_check.sh
chmod +x ${folder}/config/enable_watchdog.sh
chmod +x ${folder}/config/enable_nopasswd_sudo.sh
chmod +x ${folder}/config/config_ready.sh

# --no-remove: apt aborts instead of uninstalling anything; long timeout since killing dpkg mid-run needs manual repair
if ! command -v nc >/dev/null 2>&1; then
    echo "netcat not found, installing netcat-openbsd" >> "$LOG_STATUS"
    if timeout 600 sudo -n env DEBIAN_FRONTEND=noninteractive apt-get install -y --no-remove netcat-openbsd >> "$LOG_STATUS" 2>&1; then
        echo "netcat-openbsd installed successfully" >> "$LOG_STATUS"
    else
        echo "WARNING: failed to install netcat-openbsd" >> "$LOG_STATUS"
    fi
fi

# Only rewrite a crontab we read successfully and that contains update.sh, so a failed read can't wipe every job
if ! grep -q "^INTERNET_CHECK_HOSTS=" /etc/global.config 2>/dev/null; then
    echo "WARNING: internet check config missing, not scheduling internet_check.sh" >> "$LOG_STATUS"
elif ! current_cron=$(crontab -l 2>/dev/null) || ! grep -qF "config/update.sh" <<< "$current_cron"; then
    echo "WARNING: could not read crontab, not scheduling internet_check.sh" >> "$LOG_STATUS"
elif ! grep -qF "internet_check/internet_check.sh" <<< "$current_cron"; then
    echo "Adding internet_check.sh to crontab" >> "$LOG_STATUS"
    printf '%s\n%s\n' "$current_cron" "*/5 * * * *     ${folder}/internet_check/internet_check.sh" | crontab -
fi

