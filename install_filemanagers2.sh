#!/bin/bash

# Script to install multiple file managers and configure right-click options for .sh and .py files.
# WARNING: This script requires root privileges (run with sudo).
# DISCLAIMER: While this script is designed to be robust, zero bugs cannot be guaranteed due to the complexity of software interaction.
#             Test in a virtual environment or non-critical system before running on your main system.

# Function to display error messages and exit
error_exit() {
  echo "ERROR: $1" >&2
  exit 1
}

# Function to install a package
install_package() {
  PACKAGE_NAME="$1"
  echo "Installing $PACKAGE_NAME..."
  sudo apt update -y  || error_exit "Failed to update apt package list."
  sudo apt install -y "$PACKAGE_NAME" || error_exit "Failed to install $PACKAGE_NAME."
  echo "$PACKAGE_NAME installed successfully."
}

# Function to configure Thunar custom actions
configure_thunar() {
  echo "Configuring Thunar..."

  # Create the Thunar custom action configuration directory if it doesn't exist.
  mkdir -p ~/.config/Thunar/uca.xml.d

  # Create a script for running in kitty terminal

  cat <<EOF > ~/.config/Thunar/uca.xml.d/run-in-kitty.xml
<action>
	<icon>terminal</icon>
	<name>Run in Kitty</name>
	<unique-id>1678807801-8836-0</unique-id>
	<command>kitty bash -c "chmod +x %f; %f"</command>
	<description>Run the selected script in the Kitty Terminal.</description>
	<patterns>*.sh;*.py;</patterns>
	<startup-notify/>
	<directories/>
	<audio-files/>
	<image-files/>
	<other-files/>
	<text-files/>
	<video-files/>
</action>
EOF

  # Create a script for running as root in terminal

  cat <<EOF > ~/.config/Thunar/uca.xml.d/run-as-root.xml
<action>
	<icon>terminal</icon>
	<name>Run as Root</name>
	<unique-id>1678807801-8836-1</unique-id>
	<command>xterm -e sudo bash -c "chmod +x %f; %f"</command>
	<description>Run the selected script as Root user.</description>
	<patterns>*.sh;*.py;</patterns>
	<startup-notify/>
	<directories/>
	<audio-files/>
	<image-files/>
	<other-files/>
	<text-files/>
	<video-files/>
</action>
EOF

  echo "Thunar configured with run in kitty and run as root action."
}

# Install file managers
install_package nemo
install_package caja
install_package dolphin
install_package spacefm
install_package pcmanfm
install_package thunar
install_package kitty
install_package xterm #for root terminal option
install_package zenity #for some visual feedback

# Configure Thunar (most reliable custom action)
configure_thunar

# Attempt to fix icon issues by updating desktop database and icon cache
echo "Updating desktop database and icon cache..."
sudo update-desktop-database || echo "Warning: Failed to update desktop database."
sudo gtk-update-icon-cache -f /usr/share/icons/hicolor || echo "Warning: Failed to update icon cache."
sudo gtk-update-icon-cache -f /usr/share/icons/Adwaita || echo "Warning: Failed to update Adwaita icon cache."

echo "All file managers and Thunar right-click actions configured."
echo "IMPORTANT: Please restart your file manager or log out/log in for changes to take effect. Do NOT try to run Dolphin as root directly."
echo "If icons are still incorrect, see manual steps in comments of the script."
echo "Run other file managers (Nemo, Caja, Dolphin, SpaceFM, PCManFM) as your normal user, NOT as root."

exit 0
