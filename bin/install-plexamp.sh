#!/usr/bin/env bash

set -eufo pipefail

# Script: PlexAmp-install for Pi
# Purpose: Install PlexAmp on a Raspberry Pi.
# Make sure you have a 64-bit capable Raspberry Pi and Pi OS is 64-bit.
# Script will install node.v12 and set it on hold.
# Needs to be run as the root user.
#
# How to enable SSH on Raspberry Pi OS:
# For security reasons, as of the November 2016 release, Raspbian has the SSH server disabled by default.
# After burning the image to your Micro-SD-card (with etcher), you need to enable.
#
# To enable:
# 1. Mount your SD card on your computer.
# 2. Create or copy an empty file called ssh in /boot.
# on MacOS you can do: touch /Volumes/boot/ssh
#
#
# SSH access on "Raspberry Pi OS": (2022-04-04) To set up a user on first boot on headless, create a file called userconf or userconf.txt in
# the boot partition of the SD card. This file should contain a single line of text, consisting of username:encrypted-password –
# so your desired username, followed immediately by a colon, followed immediately by an encrypted representation of the password you want to use.
#
# To generate the encrypted password, the easiest way is to use OpenSSL on a Raspberry Pi that is already running (or most any linux you have running)
# – open a terminal window and enter: echo ‘mypassword’ | openssl passwd -6 -stdin
#
# This will produce what looks like a string of random characters, which is actually an encrypted version of the supplied password.
#
# Then SSH to raspbian with user/pass: pi/raspberry
#
# Now change to root user with command "sudo -i".
# Copy over this script to the root folder and make executable, i.e. chmod +x setup-pi_Plexamp.sh
# Run with ./install_configure_Plexamp_pi.sh
#
# Revision update: 2020-12-06 ODIN - Initial version.
# Revision update: 2020-12-16 ODIN - Added MacOS information for Plexamp V1.x.x and workarounds for DietPi.
# Revision update: 2022-05-04 ODIN - Changed to new version of Pi OS (64-bit), Plexamp V4.2.2. Not tested on DietPi.
# Revision update: 2022-05-07 ODIN - Fixed systemd user instance terminating at logout of user.
# Revision update: 2022-05-08 ODIN - Updated to using "Plexamp-Linux-arm64-v4.2.2-beta.3" and corrected service-file.
# Revision update: 2022-05-09 ODIN - Updated to using "Plexamp-Linux-arm64-v4.2.2-beta.5" and added update-function. Version still hardcoded.
# Revision update: 2022-05-09 ODIN - Updated to using "Plexamp-Linux-arm64-v4.2.2-beta.7". Version still hardcoded.
# Revision update: 2022-06-03 ODIN - Updated to using "Plexamp-Linux-arm64-v4.2.2". No more beta. Version still hardcoded.
# Revision update: 2022-08-01 ODIN - Added option for HifiBerry Digi2 Pro. Submitted by Andreas Diel (https://github.com/Dieler).
# Revision update: 2022-08-02 ODIN - Updated to using "Plexamp-Linux-headless-v4.3.0". No more beta. Version still hardcoded.
# Revision update: 2022-08-14 ODIN - Added workarounds for DietPi.
#
#
#

#####
# Variable(s), update if needed before execution of script.
#####

PLEXAMPV="Plexamp-Linux-headless-v4.3.0" # Default Plexamp-version
PLEXAMP_USER=plexamp # user that will run the plexamp service

echo "--== Verify dependencies installed ==--"
sudo apt-get -y install alsa-utils ifupdown
echo " "

if ! id "$PLEXAMP_USER" &>/dev/null ; then
  echo " "
  echo "--== Creating user $PLEXAMP_USER and adding to audio group ==--"
  sudo useradd -m "$PLEXAMP_USER"
  sudo adduser $PLEXAMP_USER audio
  echo "--== Adding current user to the group of the new [$PLEXAMP_USER] ==--"
  sudo adduser $USER $PLEXAMP_USER
  sudo chmod g+w /home/$PLEXAMP_USER

  echo ""
  echo "Now log out and log in again"
  exit 0
fi

echo " "
echo "--== Install or upgrade ==--"
# echo -n "Do you want to install and configure Node.v12 [y/N]: "
# read answer
# answer=$(echo "$answer" | tr '[:upper:]' '[:lower:]')
# if [ "$answer" = "y" ]; then
#   echo " "
#   if [ ! -f /etc/apt/sources.list.d/nodesource.list ]; then
#     echo "--== Install node.v12 ==--"
#     sudo apt-mark unhold nodejs
#     sudo apt-get purge -y nodejs
#     curl -sL https://deb.nodesource.com/setup_12.x | sudo -E bash -
#     sudo apt-get install -y nodejs=12.22.*-1nodesource1
#     sudo apt-mark hold nodejs
#   fi
# fi
# echo " "
# echo "--== Verify that node.v12 is set to hold ==--"
# apt-mark showhold
# echo " "
# echo "--== Verify node.v12 and npm versions, should be v12.22.* and 6.14.16 ==--"
# node -v
# npm -v
# echo " "

# assumption: current user can do this
cd /home/$PLEXAMP_USER
umask 002 # let the group do stuff
NODE_BINARY="/home/$PLEXAMP_USER/node-12/bin/node"

if [ ! -d "/home/$PLEXAMP_USER/node-12" ]; then
  echo "--== Installing Node 12 ==--"
  NODE_VERSION="v12.22.12"
  wget "https://nodejs.org/dist/latest-v12.x/node-$NODE_VERSION-linux-arm64.tar.gz"
  tar xf "node-$NODE_VERSION-linux-arm64.tar.gz"
  mv "node-$NODE_VERSION-linux-arm64" "node-12"
  sudo chown -R "$PLEXAMP_USER":"$PLEXAMP_USER" "/home/$PLEXAMP_USER/node-12/"
  echo "node version is: $($NODE_BINARY --version)"
fi

if [ ! -f "/home/$PLEXAMP_USER/$PLEXAMPV.tar.bz2" ]; then
  echo "--== Fetch $PLEXAMPV ==--"
  wget "https://plexamp.plex.tv/headless/$PLEXAMPV.tar.bz2"
fi

if [ ! -f /home/"$PLEXAMP_USER"/plexamp/plexamp.service ]; then
  echo "--== Unpack and install $PLEXAMPV ==--"
  tar -xf "$PLEXAMPV.tar.bz2"
  sudo chown -R "$PLEXAMP_USER":"$PLEXAMP_USER" /home/"$PLEXAMP_USER"/plexamp/
fi

echo "--== Fix plexamp.service ==--"
SERVICE_DEFINITION_FILE="/home/$PLEXAMP_USER/.config/systemd/user/plexamp.service"
if [ ! -f "$SERVICE_DEFINITION_FILE" ]; then
  mkdir -p /home/"$PLEXAMP_USER"/.config/systemd/user/
  cp /home/$PLEXAMP_USER/plexamp/plexamp.service /home/"$PLEXAMP_USER"/.config/systemd/user/
  sed -i 's#multi-user#basic#g' "$SERVICE_DEFINITION_FILE"
  sed -i '/User=pi/d' "$SERVICE_DEFINITION_FILE"
  sed -i "s#/home/pi/plexamp/js/index.js#/home/$PLEXAMP_USER/plexamp/js/index.js#g" "$SERVICE_DEFINITION_FILE"
  sed -i "s#WorkingDirectory=/home/pi/plexamp#WorkingDirectory=/home/$PLEXAMP_USER/plexamp#g" "$SERVICE_DEFINITION_FILE"
  sed -i "s#/usr/bin/node#${NODE_BINARY}#" "$SERVICE_DEFINITION_FILE"
  sudo chown -R "$PLEXAMP_USER":"$PLEXAMP_USER" /home/"$PLEXAMP_USER"/.config/
  loginctl enable-linger "$PLEXAMP_USER"
  sudo systemctl daemon-reload
fi

echo " "
echo "--== Cleanup ==--"
echo -n "Do you want to delete everything? [y/N]: "
read answer
answer=$(echo "$answer" | tr '[:upper:]' '[:lower:]')
if [ "$answer" = "y" ]; then
  ps ax | grep index.js | grep -v grep | awk '{print $1}' | xargs kill
  rm -rf /home/"$USER"/plexamp/
  rm -rf /home/"$USER"/Plexamp-Linux-*
  rm -rf /home/"$USER"/.config/systemd/user/plexamp.service
fi

echo "To do systemctl things as $PLEXAMP_USER user:"
echo
echo "sudo su - $PLEXAMP_USER"
echo "export XDG_RUNTIME_DIR=/run/user/$UID"
echo "export DBUS_SESSION_BUS_ADDRESS=unix:path=${XDG_RUNTIME_DIR}/bus"
echo "systemctl --user status"
echo

echo " "
echo -e "Configuration post-reboot:"
echo "      Note !! Only needed if fresh install, not if upgrading. Tokens are preserved during upgrade."
echo "      After reboot, as your regular user please run the command: $NODE_BINARY /home/"$PLEXAMP_USER"/plexamp/js/index.js"
echo "      now, go to the URL provided in response, and enter the claim token at prompt."
echo "      Please give the player a name at prompt (can be changed via Web-GUI later)."
echo "      At this point, Plexamp is now signed in and ready, but not running!"
echo " "
echo "      Now either start Plexamp manually using: node /home/"$PLEXAMP_USER"/plexamp/js/index.js"
echo "      or enable the service and then start the Plexamp service."
echo "      If process is running, hit ctrl+c to stop process, then enter:"
echo "      systemctl --user enable plexamp.service && systemctl --user start plexamp.service"
echo "      On DietPi: sudo systemctl enable plexamp.service && sudo systemctl start plexamp.service"
echo " "
echo "      Once done, the web-GUI should be available on the ip-of-plexamp-pi:32500 from a browser."
echo "      On that GUI you will be asked to login to your Plex-acoount for security-reasons,"
echo "      and then choose a librabry where to fetch/stream music from."
echo "      Now play some music! Or control it from any other instance of Plexamp."
echo " "
echo "      NOTE!! If you upgraded, only reboot is needed, tokens are preserved."
echo "      One can verify the service with: systemctl --user status plexamp.service"
echo "      On DietPi: sudo systemctl status plexamp.service"
echo "      All should work at this point."
echo " "
echo "      Logs are located at: ~/.cache/Plexamp/log/Plexamp.log"
echo " "
# end
