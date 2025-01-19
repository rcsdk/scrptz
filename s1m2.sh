#!/bin/bash

echo "Initializing minimal Arch Linux setup..."

# Function to check the success of a command
check_success() {
    if [ $? -ne 0 ]; then
        echo "Error: $1 failed. Exiting."
        exit 1
    fi
}

# Set Time Zone to São Paulo
sudo timedatectl set-timezone America/Sao_Paulo
check_success "Timezone set"

# Set Locale (if not set already)
sudo localectl set-locale LANG=en_US.UTF-8
check_success "Locale set"

# Pacman basics
pacman-key --init
gpg --check-trustdb
check_success "Pacman keyring initialized"

sudo pacman -Syy --needed
check_success "Pacman updated"

sudo rm -f /var/lib/pacman/db.lck
check_success "Pacman lock removed"

sudo pacman -S --noconfirm --needed ufw apparmor openvpn chromium xorg-xinit xorg mesa intel-media-driver
check_success "Basic Packages installed"

sudo mkinitcpio -p linux
check_success "mkinitcpio ran"

sudo pacman -Syu --needed
check_success "System updated after mkinitcpio"

lsmod | grep xhci_pci
lsmod | grep ast
lsmod | grep aic94xx
lsmod | grep wd719x
dmesg | grep -i firmware
check_success "System info and firmware checked"
sleep 1

sudo rm -f /var/lib/pacman/db.lck
check_success "Pacman lock removed again"

echo $FAKETIME
unset FAKETIME
ps aux | grep faketime
grep faketime ~/.bashrc ~/.zshrc ~/.profile
grep faketime /etc/profile.d/*
kill -9 9394 9400
grep faketime ~/.bashrc ~/.zshrc /etc/profile /etc/profile.d/*
sudo pacman -R libfaketime
sudo killall faketime
check_success "faketime removed"

# Add a user and set password
sudo useradd -m rc
check_success "User rc created"

echo "rc:0000" | sudo chpasswd
check_success "Password for rc set"

sudo usermod -aG wheel rc
check_success "User rc added to wheel group"

# Grant sudo privileges to the user rc
echo "rc ALL=(ALL) NOPASSWD:ALL" | sudo tee /etc/sudoers.d/rc
check_success "User rc granted sudo privileges"

# Configure Display Brightness
xrandr --output eDP1 --brightness 0.4
check_success "Brightness adjusted"

# Harden Kernel Parameters
cat <<EOF | sudo tee /etc/sysctl.d/99-custom.conf
kernel.dmesg_restrict = 1
kernel.kptr_restrict = 2
EOF
sudo sysctl --system
check_success "Kernel parameters set"

# Enable and configure UFW (Firewall)
sudo systemctl enable --now ufw
check_success "UFW enabled"

sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow ssh
sudo ufw reload
check_success "UFW rules configured"

# Disable unnecessary services (Bluetooth, Printer, etc.)
sudo systemctl disable alsa-restore.service
sudo systemctl disable getty@tty1.service
sudo systemctl disable ip6tables.service
sudo systemctl disable iptables.service
sudo systemctl disable cups
sudo systemctl disable avahi-daemon
sudo systemctl disable bluetooth
check_success "Unnecessary services disabled"

# Mask unnecessary services
sudo systemctl mask alsa-restore.service
sudo systemctl mask getty@tty1.service
sudo systemctl mask ip6tables.service
sudo systemctl mask iptables.service
sudo systemctl mask cups
sudo systemctl mask avahi-daemon
sudo systemctl mask bluetooth
check_success "Unnecessary services masked"

# Prevent overlay
sudo sed -i 's/ overlay//g' /etc/X11/xorg.conf
sudo sed -i 's/ allow-overlay//g' /etc/security/limits.conf
check_success "Overlay features disabled"

# AppArmor setup (if needed)
sudo systemctl enable apparmor
sudo systemctl start apparmor
sudo aa-enforce /etc/apparmor.d/*
check_success "Apparmor configured"

# Set DNS to Cloudflare for privacy
echo "nameserver 1.1.1.1" | sudo tee /etc/resolv.conf
echo "nameserver 9.9.9.9" | sudo tee -a /etc/resolv.conf
sudo chattr +i /etc/resolv.conf
check_success "DNS set and locked"

# Configure Sudo timeout (for better security)
echo 'Defaults timestamp_timeout=5' | sudo tee -a /etc/sudoers
check_success "Sudo timeout set"

# Secure important files
sudo chmod 600 /etc/ssh/sshd_config  # Secure SSH config if using SSH
check_success "SSH config secured"

# Clean Pacman Cache
sudo pacman -Scc --noconfirm
check_success "Pacman cache cleaned"

# Open Chromium in Incognito mode
chromium --new-window --incognito --no-sandbox "https://github.com/login"
check_success "Chromium launched"

echo "Minimal setup completed."
