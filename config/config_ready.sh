#!/bin/bash
#
# Exits 0 when /etc/global.config has been filled in, and 1 while it still holds
# the <PLACEHOLDER> values that come with the template.
#
# install.sh writes the config and schedules the cron jobs in the same run, so on
# a fresh station the jobs start before anyone edits it: at the first reboot the
# FTP scripts would mkdir a literal "<FTP_BASE>/<STNM>" tree and status_update.sh
# would report station <STNM> to the IGN server. Callers run this and log the skip
# in their own logfile.
#
# Only the settings every station needs are checked. The NTRIP and MET placeholders
# are left alone on purpose: a station that runs neither never fills them in.
#

source "/etc/global.config" 2>/dev/null

for value in "$STNM" "$FTP_LOCAL_PATH"; do
    case "$value" in
        *"<"*">"*) exit 1 ;;
    esac
done
