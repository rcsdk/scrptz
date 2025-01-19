#!/bin/bash

echo "Initializing minimal Arch Linux setup..."

# Function to check the success of a command
check_success() {
    if [ $? -ne 0 ]; then
        echo "Error: $1 failed. Exiting."
        exit 1
    fi
}


# Add a user and set password
sudo useradd -m rc
check_success "User rc created"

echo "rc:0000" | sudo chpasswd
check_success "Password for rc set"

sudo usermod -aG wheel rc
check_success "User rc added to wheel group"

# Grant sudo privileges to the user rc
echo "rc ALL=(ALL) NOPASSWD:ALL" | sudo tee /etc/sudoers.d/rc
su - rc
check_success "User rc granted sudo privileges"

# Change ownership of the home directory to user rc
sudo chown -R rc:rc /home/rc
check_success "Ownership of /home/rc changed to user rc"

# Give full permissions to the home directory
sudo chmod -R 777 /home/rc
check_success "Full permissions given to /home/rc"


# Set Time Zone to São Paulo
sudo timedatectl set-timezone America/Sao_Paulo
check_success "Timezone set"

# Set Locale (if not set already)
sudo localectl set-locale LANG=en_US.UTF-8
check_success "Locale set"

# Initialize Pacman keyring and populate with Arch Linux keys
sudo pacman-key --init
check_success "Pacman keyring initialized"

sudo pacman-key --populate archlinux
check_success "Pacman keyring populated"

# Check GPG trust database
sudo gpg --check-trustdb
check_success "GPG trustdb checked"

# Prepare Pacman and do all Downloads
sudo pacman -Syy --needed
check_success "Pacman updated"

# Remove any existing Pacman lock file
sudo rm -f /var/lib/pacman/db.lck
check_success "Pacman lock removed"

# Prepare Pacman and do all Downloads
sudo pacman -Syy --needed
check_success "Pacman updated"

sudo rm -f /var/lib/pacman/db.lck
check_success "Pacman lock removed"

pacman -Syy
pacman -S --noconfirm --needed ufw
pacman -S --noconfirm --needed apparmor
pacman -S --noconfirm --needed openvpn
pacman -S --noconfirm --needed  chromium 
pacman -S --noconfirm --needed  xorg-xinit
pacman -S --noconfirm --needed  xorg
pacman -S --noconfirm --needed  neofetch lolcat
pacman -S --noconfirm --needed  mesa
pacman -S --noconfirm --needed  intel-media-driver
pacman -S --noconfirm --needed  libva
pacman -S --noconfirm --needed  libva-intel-driver
pacman -S --noconfirm --needed  libva-utils
pacman -S --noconfirm --needed  intel-gpu-tools

check_success "Basic Packages installed"

# Enable and Monitor GPU Performance
intel_gpu_top
check_success "GPU performance monitored"


# Create minimal xorg.conf
cat <<EOF | sudo tee /etc/X11/xorg.conf
Section "Device"
    Identifier "Intel Graphics"
    Driver "intel"
EndSection

Section "Monitor"
    Identifier "eDP1"
EndSection

Section "Screen"
    Identifier "Screen0"
    Device "Intel Graphics"
    Monitor "eDP1"
EndSection

Section "ServerLayout"
    Identifier "Layout0"
    Screen "Screen0"
EndSection
EOF
check_success "xorg.conf created"

# Fix for mkinitcpio error
cat <<EOF | sudo tee /etc/mkinitcpio.d/linux.preset
ALL_config="/etc/mkinitcpio.conf"
ALL_kver="/boot/vmlinuz-linux"

PRESETS=('default')

default_image="/boot/initramfs-linux.img"
default_options=""
EOF
check_success "/etc/mkinitcpio.d/linux.preset created"

sudo mkinitcpio -p linux
check_success "mkinitcpio ran"

sudo pacman -Syu
check_success "System updated after mkinitcpio"


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
sudo pacman -R --noconfirm libfaketime
sudo killall faketime
check_success "faketime removed"


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
echo 'Defaults ti|zmestamp_timeout=5' | sudo tee -a /etc/sudoers
check_success "Sudo timeout set"

# Secure important files
sudo chmod 600 /etc/ssh/sshd_config  # Secure SSH config if using SSH
check_success "SSH config secured"

sudo chmod 600 /etc/shadow
sudo chown root:root /etc/shadow
check_success "Shadow file secured"

sudo chmod 600 /etc/gshadow
sudo chown root:root /etc/gshadow
check_success "GShadow file secured"

sudo chmod 644 /etc/passwd
sudo chown root:root /etc/passwd
check_success "Passwd file secured"

sudo chmod 644 /etc/group
sudo chown root:root /etc/group
check_success "Group file secured"

sudo chmod 700 /boot
sudo chown root:root /boot
check_success "Boot directory secured"

sudo chmod 440 /etc/sudoers
sudo chown root:root /etc/sudoers
check_success "Sudoers file secured"

sudo chmod -R 600 /var/log
sudo chown -R root:root /var/log
check_success "Log files secured"


# Clean Pacman Cache
sudo pacman -Scc --noconfirm
check_success "Pacman cache cleaned"

# Clone and bootstrap GameMode
git clone https://github.com/FeralInteractive/gamemode.git
cd gamemode
./bootstrap.sh
check_success "GameMode cloned and bootstrapped"
cd ..

# Configure Hardware Acceleration in Firefox
echo "Configuring Firefox for hardware acceleration..."
firefox -P <profile-name> about:config
# Set the following preferences
gfx.webrender.all=true
layers.acceleration.force-enabled=true
webgl.force-enabled=true
media.ffmpeg.vaapi.enabled=true

# Open Chromium in Incognito mode
chromium --new-window --incognito --no-sandbox "https://github.com/login"
check_success "Chromium launched"

echo "Minimal setup completed."
