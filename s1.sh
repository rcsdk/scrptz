#!/bin/bash

# Disable laptop trackpad
xinput --disable $(xinput --list | grep -i "touchpad" | cut -d "=" -f2)

# Remove pacman database file to prevent repeated annoyances
sudo rm -f /var/lib/pacman/db.lck

# Customize terminal to use Ctrl+C, Ctrl+V, and Ctrl+Z
echo "bind \"^C\": copy" >> ~/.inputrc
echo "bind \"^V\": paste" >> ~/.inputrc
echo "bind \"^Z\": suspend" >> ~/.inputrc

# Open terminal
xfce4-terminal &

# Update the package list
sudo pacman -Syy --noconfirm

# Disable unnecessary services
sudo systemctl disable alsa-restore.service
sudo systemctl disable getty@tty1.service
sudo systemctl disable ip6tables.service
sudo systemctl disable iptables.service
sudo systemctl disable cups
sudo systemctl disable avahi-daemon
sudo systemctl disable bluetooth
sudo systemctl mask alsa-restore.service
sudo systemctl mask getty@tty1.service
sudo systemctl mask ip6tables.service
sudo systemctl mask iptables.service
sudo systemctl mask cups
sudo systemctl mask avahi-daemon
sudo systemctl mask bluetooth

# Optimize boot time
sudo systemd-analyze blame

# Configure DNS settings
sudo echo "nameserver 8.8.8.8" | sudo tee /etc/resolv.conf

# Disable unnecessary overlay features
sudo sed -i 's/ overlay//g' /etc/X11/xorg.conf

# Use a secure overlay network
sudo pacman -S --noconfirm openvpn
sudo systemctl enable openvpn

# Implement overlay-specific security measures
sudo sed -i 's/ allow-overlay//g' /etc/security/limits.conf

# Install basic security tools
sudo pacman -S --noconfirm ufw apparmor

# Set up a firewall
sudo ufw enable
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow ssh
sudo ufw allow http
sudo ufw allow https
sudo ufw reload

# Enable AppArmor
sudo systemctl enable apparmor
sudo systemctl start apparmor
sudo aa-enforce /etc/apparmor.d/*
