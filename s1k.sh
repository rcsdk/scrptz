#!/bin/bash

echo "Initializing minimal Arch Linux setup..."

# Function to check the success of a command
check_success() {
    if [ $? -ne 0 ]; then
        echo "Error: $1 failed. Exiting."
        exit 1
    fi
}

# Function for logging
LOGFILE="/var/log/arch_setup.log"
exec > >(tee -a "$LOGFILE") 2>&1

# Set Time Zone to São Paulo
sudo timedatectl set-timezone America/Sao_Paulo
check_success "Timezone set"

# Configure Display Brightness
xrandr --output eDP1 --brightness 0.4
check_success "Brightness adjusted"

# Set Locale (if not set already)
sudo localectl set-locale LANG=en_US.UTF-8
check_success "Locale set"

# Pacman basics
pacman-key --init
gpg --check-trustdb
check_success "Pacman keyring initialized"

pacman --noconfirm -Syu
check_success "Pacman updated"

sudo rm -f /var/lib/pacman/db.lck
check_success "Pacman lock removed"

# Install essential packages
sudo pacman -S --noconfirm ufw apparmor openvpn chromium xorg-xinit xorg mesa intel-media-driver zramswap thermald tlp preload
check_success "Basic Tools Installed"

# Initialize mkinitcpio
sudo mkinitcpio -p linux
check_success "mkinitcpio ran"

sudo pacman -Syu --noconfirm
check_success "System updated after mkinitcpio"

# System info and firmware check
lsmod | grep xhci_pci
lsmod | grep ast
lsmod | grep aic94xx
lsmod | grep wd719x
dmesg | grep -i firmware
check_success "System info and firmware checked"

sudo rm -f /var/lib/pacman/db.lck
check_success "Pacman lock removed again"

# Remove faketime if it exists
ps aux | grep faketime | grep -v grep | awk '{print $2}' | xargs -r sudo kill -9
sudo pacman -R --noconfirm libfaketime
sudo killall faketime 2>/dev/null
check_success "faketime removed"


# Add a user and set password
sudo useradd -m rc
check_success "User rc created"

echo "rc:0000" | sudo chpasswd
check_success "Password for rc set"

sudo usermod -aG wheel rc
check_success "User rc added to wheel group"

# Add rc to sudoers
echo "Adding rc to sudoers..."
if sudo grep -q "^rc " /etc/sudoers; then
    echo "rc is already in sudoers. Skipping."
else
    echo "rc ALL=(ALL:ALL) NOPASSWD:ALL" | sudo tee -a /etc/sudoers.d/rc >/dev/null
    sudo chmod 440 /etc/sudoers.d/rc
    check_success "User rc added to sudoers with passwordless sudo access"
fi



# Add a user and set password
#sudo useradd -m rc
#check_success "User rc created"
#
#echo "rc:0000" | sudo chpasswd
#check_success "Password for rc set"
#
#sudo usermod -aG wheel rc
#check_success "User rc added to wheel group"
#
#

Udate system and configure mirrors
sudo pacman -S --noconfirm reflector
check_success "Reflector installed"

sudo reflector --country 'United States' --latest 10 --sort rate --save /etc/pacman.d/mirrorlist
check_success "Mirrors configured"

# Disable Touchpad
synclient TouchpadOff=1
check_success "Touchpad disabled"

# Harden Kernel Parameters
cat <<EOF | sudo tee /etc/sysctl.d/99-custom.conf
kernel.dmesg_restrict = 1
kernel.kptr_restrict = 2
EOF
sudo sysctl --system
check_success "Kernel parameters set"

# Enable and configure UFW (Firewall)
sudo systemctl enable --now ufw
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow ssh
sudo ufw reload
check_success "UFW enabled"

# Enable and configure ZRAM, Thermald, and TLP
sudo systemctl enable --now zramswap.service
sudo systemctl enable --now thermald
sudo systemctl enable --now tlp
check_success "ZRAM, Thermald, and TLP enabled"

# Disable and mask unnecessary services
services=(alsa-restore.service getty@tty1.service ip6tables.service iptables.service cups avahi-daemon bluetooth)
for service in "${services[@]}"; do
    sudo systemctl disable "$service"
    sudo systemctl mask "$service"
done
check_success "Unnecessary services disabled and masked"

# Prevent overlay
sudo sed -i 's/ overlay//g' /etc/X11/xorg.conf 2>/dev/null
sudo sed -i 's/ allow-overlay//g' /etc/security/limits.conf 2>/dev/null
check_success "Overlay features disabled"

# AppArmor setup
sudo systemctl enable apparmor
sudo systemctl restart apparmor
sudo aa-enforce /etc/apparmor.d/*
check_success "AppArmor configured"

# Set DNS to Cloudflare for privacy
echo "nameserver 1.1.1.1" | sudo tee /etc/resolv.conf
echo "nameserver 9.9.9.9" | sudo tee -a /etc/resolv.conf
sudo chattr +i /etc/resolv.conf
check_success "DNS set and locked"

# Configure Sudo timeout (for better security)
echo 'Defaults timestamp_timeout=5' | sudo tee -a /etc/sudoers
check_success "Sudo timeout set"

# Secure important files
sudo chmod 600 /etc/ssh/sshd_config
check_success "SSH config secured"

# Enable automatic updates (via `pacman` or `systemd`)
cat <<EOF | sudo tee /etc/systemd/system/pacman-updates.timer
[Timer]
OnBootSec=10min
OnUnitActiveSec=1d
EOF

cat <<EOF | sudo tee /etc/systemd/system/pacman-updates.service
[Service]
ExecStart=/usr/bin/pacman -Syu --noconfirm
EOF

sudo systemctl enable pacman-updates.timer
check_success "Automatic updates configured"

# Figma hooking with local fonts
curl -L https://raw.githubusercontent.com/Figma-Linux/figma-linux-font-helper/master/res/install.sh | bash
systemctl --user restart figma-fonthelper.service
check_success "Figma font helper configured"

# Launch Chromium with GPU acceleration
chromium --incognito \
    --disable-background-networking \
    --disable-default-apps \
    --disable-sync \
    --disable-translate \
    --no-first-run \
    --no-sandbox \
    --force-device-scale-factor=1 \
    --disable-software-rasterizer \
    --enable-accelerated-video-decode \
    --enable-accelerated-mjpeg-decode \
    --use-gl=desktop \
    --use-vulkan \
    --enable-native-gpu-memory-buffers \
    --canvas-oop-rasterization \
    "https://figma.com"
check_success "Chromium launched with GPU optimizations"

# Clean Pacman Cache
sudo pacman -Scc --noconfirm
check_success "Pacman cache cleaned"

echo "Minimal setup completed successfully!"
