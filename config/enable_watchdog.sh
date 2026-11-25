#!/bin/bash
#
# Enables the Raspberry Pi's hardware watchdog through systemd: if the system
# freezes for 15s (the BCM2835 maximum), the board resets itself.
# Run by install.sh; safe to run by hand on existing stations and to re-run.
#

if [ ! -e /dev/watchdog ]; then
    echo "WARNING: no hardware watchdog device (/dev/watchdog) found, freeze recovery is NOT active"
    exit 1
fi

# The old watchdog/ installer set up the watchdog daemon, which competes with systemd for the device
for unit in watchdog.service wd_keepalive.service; do
    if [ -n "$(systemctl list-unit-files --no-legend "$unit")" ]; then
        echo "Disabling $unit so systemd can own the watchdog"
        sudo systemctl disable --now "$unit"
    fi
done

# A drop-in overrides any RuntimeWatchdogSec the old installer left in /etc/systemd/system.conf
sudo mkdir -p /etc/systemd/system.conf.d
printf '[Manager]\nRuntimeWatchdogSec=15\n' | sudo tee /etc/systemd/system.conf.d/gnss-station-watchdog.conf > /dev/null
sudo systemctl daemon-reexec

echo "Watchdog timeout set to $(systemctl show -p RuntimeWatchdogUSec --value). systemd reports:"
sudo journalctl -b _PID=1 --no-pager -o cat | grep -i watchdog | tail -n 3
