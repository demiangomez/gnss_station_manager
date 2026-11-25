#!/bin/bash
#
# Enables the Raspberry Pi's hardware watchdog through systemd: if the system
# freezes for 15s (the BCM2835 maximum), the board resets itself.
# Run by install.sh; safe to run by hand on existing stations and to re-run.
#

WATCHDOG_SYS=/sys/class/watchdog/watchdog0

if [ ! -e /dev/watchdog ]; then
    echo "WARNING: no hardware watchdog device (/dev/watchdog) found, freeze recovery is NOT active" >&2
    exit 1
fi

# The drop-in is written first: if a later step fails, the station is left configured
# rather than with the old daemon stopped and nothing holding the device.
# A drop-in also overrides any RuntimeWatchdogSec the old installer left in /etc/systemd/system.conf
if ! sudo mkdir -p /etc/systemd/system.conf.d ||
   ! printf '[Manager]\nRuntimeWatchdogSec=15\n' | sudo tee /etc/systemd/system.conf.d/gnss-station-watchdog.conf > /dev/null; then
    echo "ERROR: could not write /etc/systemd/system.conf.d/gnss-station-watchdog.conf, watchdog NOT enabled" >&2
    exit 1
fi

# The old watchdog/ installer set up the watchdog daemon, which holds /dev/watchdog and
# competes with systemd for it. Stopped before the re-exec, so the device is free by then.
for unit in watchdog.service wd_keepalive.service; do
    if [ -n "$(systemctl list-unit-files --no-legend "$unit")" ]; then
        echo "Disabling $unit so systemd can own the watchdog"
        sudo systemctl disable --now "$unit"
    fi
done

sudo systemctl daemon-reexec

# Checked against the kernel, not the journal: systemd logs the hardware watchdog when it
# opens the device at boot, so a re-exec can arm it without printing anything to the journal
CONFIGURED=$(systemctl show -p RuntimeWatchdogUSec --value 2>/dev/null)
HELD_BY_INIT=$(sudo ls -l /proc/1/fd 2>/dev/null | grep -c "/dev/watchdog")
STATE=$(cat ${WATCHDOG_SYS}/state 2>/dev/null)
TIMEOUT=$(cat ${WATCHDOG_SYS}/timeout 2>/dev/null)

echo "systemd RuntimeWatchdogUSec: ${CONFIGURED:-unknown}"
echo "Device ${WATCHDOG_SYS}: state=${STATE:-unknown}, timeout=${TIMEOUT:-unknown}"

if [ "$CONFIGURED" != "15s" ] || [ "${HELD_BY_INIT:-0}" -eq 0 ]; then
    echo "ERROR: the watchdog is NOT armed: systemd reports a ${CONFIGURED:-unknown} timeout and PID 1 does not hold /dev/watchdog." >&2
    echo "       The station will not recover on its own from a freeze. Check 'systemctl show -p RuntimeWatchdogUSec' and 'sudo ls -l /proc/1/fd'." >&2
    exit 1
fi

echo "Watchdog armed: PID 1 holds /dev/watchdog with a 15s timeout, the board resets itself if the system freezes."
echo ""
echo "To test it on a bench Pi (NEVER on a deployed station), force a kernel freeze:"
echo "    sudo sh -c 'echo c > /proc/sysrq-trigger'"
echo "The Pi should reset itself about 15 seconds later."
