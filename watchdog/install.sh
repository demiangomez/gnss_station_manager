#!/bin/bash
## This is a shell script to install the Watchdog Timer Updater on all Raspberry Pis post Pi2B
## Nicholas McCatherine, Sept. 2, 2024, Ohio State Univeristy, EarthSci UnderGrad Research


##### Make sure to set execution permissions using 'sudo chmod +x watchdog.sh'

W="\033[1;37m" # White
R="\033[1;31m" # Red

echo -e "\nInstalling WatchdogUpdater..."

DIR_="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
echo -e "\nDirectory set as $DIR_..."

WDTfile="$DIR_/watchdog.sh"
KERfile="$DIR_/testpanic.sh"
DELfile="$DIR_/delTest.sh"
acct=$USER
echo -e "\nAccount is $acct..."

# Check if files exist before moving them, exit disabled for debugging purposes
if [[ ! -f "$WDTfile" ]]; then
    echo -e "${R}Error: ${W}File '$WDTfile' not found."
fi
if [[ ! -f "$KERfile" ]]; then
    echo -e "${R}Error: ${W}File '$KERfile' not found."
fi
if [[ ! -f "$DELfile" ]]; then
    echo -e "${R}Error: ${W}File '$DELfile' not found."
fi

### Now, run the following as sudo
sudo bash <<EOF

# Set file permissions
    echo -e '\n${B}Setting file permissions as root user...'
    sudo chmod 755 "$WDTfile"
    sudo chmod 755 "$KERfile"
    sudo chmod 755 "$DELfile"

    # Lets transfer our files as root
    echo -e '\nTransfering files as the root user...'
    sudo mv -u "$WDTfile" "/usr/local/bin/watchdog"
    sudo mv -u "$KERfile" "/home/$acct/Desktop/testpanic"
    sudo mv -u "$DELfile" "/home/$acct/Desktop/DeleteTestPanic"
    # Install the "load based" watchdog
    echo -e '\nInstalling the "Load Based" watchdog software package...'
    sudo apt-get update || { echo 'apt update failed'; }
    sleep 1
    sudo apt-get upgrade -y || { echo 'apt upgrade failed'; }
    sleep 1
    sudo apt-get install -y watchdog || { echo 'Failed to install watchdog'; }
EOF

cd ~/
## Ask user if they want to remove the download directory and contents
echo -e "\n${W}Do you want to remove the download directory and remaining contents? \nY/N?"
read -r CONFIRM

## Validate input and confirmation
if [[ "$CONFIRM" = "Y" || "$CONFIRM" = "y" ]];
then
    rm -rf "$DIR_" # Removes directory, comment this out for testing
    echo -e "\nCleaning up install files..."
fi

# Remove installation directory and files, cleanup
echo -e "${R}**IMPORTANT** ${W}Use ${R}'shred -u /home/$acct/Desktop/testpanic' 
${W}after testing the Watchdog, or use the 'DeleteTestPanic' script on the desktop 
that was installed with the panic script."

# Now, return to the terminal
countdown="10"
while [ $countdown -gt 0 ]; do
    # -ne clears the terminal line when the cursor is \r returned to the beginning of the line
    echo -ne "${W}Script will return to terminal in ${R}$countdown \r"
    
    # Decrement the countdown
    ((countdown--))
    
    # Wait for 1 second
    sleep 1
done
echo -e "\n"

exit 0