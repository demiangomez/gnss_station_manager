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
The install script also enables the Raspberry Pi's hardware watchdog: if the system freezes for 15 seconds, the board reboots itself. The setting lives in `/etc/systemd/system.conf.d/gnss-station-watchdog.conf`; delete that file and reboot to turn it off.

Stations installed before this change don't get the watchdog automatically. To enable it on one, run `config/enable_watchdog.sh` from the installation folder. It also switches off the watchdog daemon installed by the old separate watchdog installer, if present.

To test the watchdog on a bench Pi (never on a deployed station), force a kernel crash:
```
sudo sh -c 'echo c > /proc/sysrq-trigger'
```
The Pi should reboot on its own about 15 seconds later.

