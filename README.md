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
./install.sh"
```
It is recommended to also install the watchdog, which is done separately. Execute the install script in the watchdog folder and after the installation process run 
```
./watchdog"
```
and follow apply the parameters:
1. Set your preffered Watchdog timer period. ("5" recommended)
2. Set your reboot Watchdog timer period. This should be significantly longer than the Watchdog timer ("1min" recommended)
3. Set the software-based Watchdog[^2] settings. This watchdog timer is primarily concerned with the average load over a set period of time.
4. Confirm your settings
5. Done! You can check to see if it was indeed updated by opening the system.conf file in /etc/systemd/
6. Perform a test to double check the function of the timer in a safe environment.

To perform the tests, follow the directions found here: https://github.com/nick10mc/WatchdogUpdater

