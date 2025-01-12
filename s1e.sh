#!/bin/bash

echo "Initializing minimal Arch Linux setup..."

# Set Time Zone to São Paulo
sudo timedatectl set-timezone America/Sao_Paulo

# Add a user and set password
sudo useradd -m rc
echo "rc:0000" | sudo chpasswd
sudo usermod -aG wheel rc

# Update system and configure mirrors
sudo pacman -Syu --noconfirm
sudo pacman -S --noconfirm reflector
sudo reflector --country 'United States' --latest 10 --sort rate --save /etc/pacman.d/mirrorlist

# Install basic tools
sudo pacman -S --noconfirm xorg xorg-xinit chromium mesa intel-media-driver ufw

# Disable Touchpad
synclient TouchpadOff=1

# Configure Display Brightness
xrandr --output eDP1 --brightness 0.4

# Harden Kernel Parameters
cat <<EOF | sudo tee /etc/sysctl.d/99-custom.conf
kernel.dmesg_restrict = 1
kernel.kptr_restrict = 2
EOF
sudo sysctl --system

# Enable and configure UFW (Firewall)
sudo systemctl enable --now ufw
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow ssh
sudo ufw reload

# Disable unnecessary services (Bluetooth, Printer, etc.)
sudo systemctl disable alsa-restore.service
sudo systemctl disable getty@tty1.service
sudo systemctl disable ip6tables.service
sudo systemctl disable iptables.service
sudo systemctl disable cups
sudo systemctl disable avahi-daemon
sudo systemctl disable bluetooth

# Mask unnecessary services
sudo systemctl mask alsa-restore.service
sudo systemctl mask getty@tty1.service
sudo systemctl mask ip6tables.service
sudo systemctl mask iptables.service
sudo systemctl mask cups
sudo systemctl mask avahi-daemon
sudo systemctl mask bluetooth

# Prevent overlay
sudo sed -i 's/ overlay//g' /etc/X11/xorg.conf
sudo sed -i 's/ allow-overlay//g' /etc/security/limits.conf

# AppArmor setup (if needed)
sudo systemctl enable apparmor
sudo systemctl start apparmor
sudo aa-enforce /etc/apparmor.d/*

# Set DNS to Cloudflare for privacy
echo "nameserver 1.1.1.1" | sudo tee /etc/resolv.conf
echo "nameserver 9.9.9.9" | sudo tee -a /etc/resolv.conf
sudo chattr +i /etc/resolv.conf

# Configure Sudo timeout (for better security)
echo 'Defaults timestamp_timeout=5' | sudo tee -a /etc/sudoers

# Secure important files
sudo chmod 600 /etc/ssh/sshd_config  # Secure SSH config if using SSH

# Clean Pacman Cache
sudo pacman -Scc --noconfirm

# Set Locale (if not set already)
sudo localectl set-locale LANG=en_US.UTF-8

# Enable automatic updates (via `pacman` or `systemd`)
echo "[Timer]" | sudo tee /etc/systemd/system/pacman-updates.timer
echo "OnBootSec=10min" | sudo tee -a /etc/systemd/system/pacman-updates.timer
echo "OnUnitActiveSec=1d" | sudo tee -a /etc/systemd/system/pacman-updates.timer
echo "[Service]" | sudo tee -a /etc/systemd/system/pacman-updates.service
echo "ExecStart=/usr/bin/pacman -Syu --noconfirm" | sudo tee -a /etc/systemd/system/pacman-updates.service
sudo systemctl enable pacman-updates.timer


chromium --new-window "https://github.com/login" & "https://venice.ai" & "https://freepik.com" & "https://figma.com" & "https://login.protonmail.com" --no-sandbox






echo "Minimal setup completed."
