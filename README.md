# GNSS station manager
## A package of scripts to run on a Raspberry Pi for managing remote GNSS stations

*By Demián Gómez and Nick McCatherine, Ohio State University,
September 13st, 2024.*

### Downloading:
Execute the following in your Raspberry Pi terminal[^1] (ideally from /home/pi):
```
sudo apt update
sudo apt install git
git clone https://github.com/demiangomez/gnss_station_manager
```

### Installation:
To install the GNSS station manager, cd into the folder where you cloned the repo and run:
```
./install.sh
```
The installer creates `/etc/global.config` from `config/global.config.new` with `SCRIPTS_BASE_PATH` already set to the installation folder, and then lists the settings that still have to be filled in by hand — station name, FTP and NTRIP details. An existing `/etc/global.config` is never overwritten, so re-running the installer can't wipe a configured station; it warns instead if that file points at a different installation folder. Until you fill in the remaining `<>` settings, the jobs that depend on them check `config/config_ready.sh` and skip, each logging `Station not configured yet` in its own logfile — otherwise the first reboot would create a literal `<FTP_BASE>/<STNM>` directory and report station `<STNM>` to the IGN status server every ten minutes. Only `STNM` and `FTP_LOCAL_PATH` are checked, so a station that never fills in the NTRIP or MET placeholders is not affected. `update.sh` and `internet_check.sh` deliberately keep running, so an unconfigured station can still pick up fixes and recover its link.

Run it as the station user, not with `sudo`: the cron jobs go into the crontab of whoever runs it. The user does need to be able to use `sudo`, and the first thing the install does is give that user passwordless sudo through `/etc/sudoers.d/010_<user>-nopasswd`. The unattended jobs depend on it, because cron gives `sudo` no terminal to ask for a password on: without it `internet_check.sh` can never reboot a station whose link has gone down, and `update.sh` can't write `/etc/global.config`.

Stations installed before this change may be missing that rule. To check one, run `sudo -n true` as the station user; if it prints an error, run `config/enable_nopasswd_sudo.sh` from the installation folder (it asks for the password once and does nothing if the rule is already there). `update.sh` also logs a warning to the status log on every station that is missing it.

The install script also enables the Raspberry Pi's hardware watchdog: if the system freezes for 15 seconds, the board reboots itself. The setting lives in `/etc/systemd/system.conf.d/gnss-station-watchdog.conf`; delete that file and reboot to turn it off. The systemd on the oldest stations (215, on Raspbian jessie) ignores that directory, so there the script falls back to setting `RuntimeWatchdogSec=15` in `/etc/systemd/system.conf` itself — on those, comment that line out instead.

Stations installed before this change don't get the watchdog automatically. To enable it on one, run `config/enable_watchdog.sh` from the installation folder. It also switches off the watchdog daemon installed by the old separate watchdog installer, if present.

Afterwards the script checks the kernel's own view — that `RuntimeWatchdogSec` is 15s *and* that PID 1 holds `/dev/watchdog` open — and exits non-zero saying the station is unprotected if either is false. It does not read the journal: systemd logs the hardware watchdog when it opens the device at boot, so re-arming it through `systemctl daemon-reexec` can succeed without printing anything.

To test the watchdog on a bench Pi (never on a deployed station), force a kernel crash:
```
sudo sh -c 'echo c > /proc/sysrq-trigger'
```
The Pi should reboot on its own about 15 seconds later.

