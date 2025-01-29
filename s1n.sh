#!/bin/bash

echo "Hardening Arch Linux environment..."

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

# Set Locale
sudo localectl set-locale LANG=en_US.UTF-8
check_success "Locale set"

# Backup existing pacman.conf
sudo cp /etc/pacman.conf /etc/pacman.conf.bak
check_success "Backup of pacman.conf"

# Replace pacman.conf
sudo tee /etc/pacman.conf <<EOF
#
# /etc/pacman.conf
#
# See the pacman.conf(5) manpage for option and repository directives
#

[options]
RootDir     = /
DBPath      = /var/lib/pacman/
CacheDir    = /var/cache/pacman/pkg/
HookDir     = /etc/pacman.d/hooks/
GPGDir      = /etc/pacman.d/gnupg/
LogFile     = /var/log/pacman.log
HoldPkg     = pacman glibc man-db bash syslog-ng systemd
IgnorePkg   =
IgnoreGroup =
NoUpgrade   =
NoExtract   =
UseSyslog
Color
ILoveCandy

Architecture = x86_64

SigLevel = Never

[core]
Include     = /etc/pacman.d/mirrorlist

[extra]
Include     = /etc/pacman.d/mirrorlist

[community]
Include     = /etc/pacman.d/mirrorlist

[multilib]
Include     = /etc/pacman.d/mirrorlist
EOF
check_success "pacman.conf replaced"

# Install Reflector
sudo pacman -S --noconfirm reflector
check_success "Reflector installed"

# Update the mirror list using Reflector
sudo reflector --verbose --latest 5 --sort rate --save /etc/pacman.d/mirrorlist
check_success "Mirror list updated"

# Synchronize the package databases
sudo pacman -Syy
check_success "Package databases synchronized"

# Remove any existing Pacman lock file
sudo rm -f /var/lib/pacman/db.lck
check_success "Pacman lock removed"

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

# Change ownership of the home directory to user rc
sudo chown -R rc:rc /home/rc
check_success "Ownership of /home/rc changed to user rc"

# Give full permissions to the home directory
sudo chmod -R 700 /home/rc
check_success "Full permissions given to /home/rc"

# Switch to rc user
su - rc

# Initialize Pacman keyring and populate with Arch Linux keys
sudo pacman-key --init
check_success "Pacman keyring initialized"

sudo pacman-key --populate archlinux
check_success "Pacman keyring populated"

# Check GPG trust database
gpg --check-trustdb
check_success "GPG trustdb checked"

# Update and install base-devel
sudo pacman -Syy
check_success "Pacman updated"

sudo pacman -S base-devel --noconfirm
check_success "Base-devel installed"

# Install xsel
sudo pacman -S --noconfirm xsel
check_success "xsel installed"

# Install a powerful terminal with AI autocomplete
sudo pacman -S --noconfirm kitty
check_success "Kitty terminal installed"

# Install a better manual with examples
sudo pacman -S --noconfirm tldr
check_success "tldr installed"

# Configure Display Brightness
xrandr --output eDP1 --brightness 0.4
check_success "Brightness adjusted"

# Remove faketime
unset FAKETIME
ps aux | grep faketime
grep faketime ~/.bashrc
grep faketime ~/.zshrc	
grep faketime ~/.profile
grep faketime /etc/profile.d/*
sudo pacman -R --noconfirm libfaketime
sudo killall faketime
check_success "faketime removed"

# Harden Kernel Parameters
cat <<EOF | sudo tee /etc/sysctl.d/99-security.conf
kernel.kptr_restrict=2
kernel.dmesg_restrict=1
kernel.printk=3 3 3 3
kernel.unprivileged_bpf_disabled=1
net.core.bpf_jit_harden=2
EOF
sudo sysctl -p /etc/sysctl.d/99-security.conf
check_success "Kernel parameters set"

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

# Set system parameters for optimization
echo 60 > /proc/sys/vm/swappiness
echo 10 > /proc/sys/vm/vfs_cache_pressure
echo 2 > /proc/sys/vm/page-cluster
echo 1000 > /proc/sys/vm/min_free_kbytes
check_success "System parameters optimized"

# Memory optimization
echo 1 > /proc/sys/vm/compact_memory
echo 3 > /proc/sys/vm/drop_caches
echo 1 > /proc/sys/vm/overcommit_memory
echo 100 > /proc/sys/vm/overcommit_ratio
echo 60 > /proc/sys/vm/swappiness
echo 10 > /proc/sys/vm/vfs_cache_pressure
check_success "Memory optimized"

# Disable unnecessary services
services=("systemd-journald" "systemd-udevd" "cups" "bluetooth" "avahi-daemon")

for service in "${services[@]}"; do
    systemctl stop "$service"
    check_success "$service stopped"

    systemctl disable "$service"
    check_success "$service disabled"

    systemctl mask "$service"
    check_success "$service masked"
done

# Set DNS to Cloudflare for privacy
echo "nameserver 1.1.1.1" | sudo tee /etc/resolv.conf
echo "nameserver 9.9.9.9" | sudo tee -a /etc/resolv.conf
sudo chattr +i /etc/resolv.conf
check_success "DNS set and locked"

# Configure Sudo timeout
echo 'Defaults timestamp_timeout=5' | sudo tee -a /etc/sudoers
check_success "Sudo timeout set"

# Secure important files
files=(
    "/etc/ssh/sshd_config"
    "/etc/shadow"
    "/etc/gshadow"
    "/etc/passwd"
    "/etc/group"
    "/boot"
    "/etc/sudoers"
    "/var/log"
)

permissions=(
    "600" "600" "600" "644" "644" "700" "440" "600"
)

owners=(
    "root:root" "root:root" "root:root" "root:root" "root:root" "root:root" "root:root" "root:root"
)

for i in "${!files[@]}"; do
    if sudo chmod "${permissions[$i]}" "${files[$i]}" && sudo chown "${owners[$i]}" "${files[$i]}"; then
        echo "${files[$i]} secured successfully"
    else
        echo "Error: Failed to secure ${files[$i]}"
        exit 1
    fi
done
check_success "Important files secured"

# Secure clipboard setup
mkdir -p /tmp/secure_work/clipboard
mount -t tmpfs -o size=64M,noexec tmpfs /tmp/secure_work/clipboard
export DISPLAY=:0
xsel -k
killall xclip 2>/dev/null

# Process monitoring
ps aux --sort=-%mem | head -n 15 > /tmp/secure_work/initial_processes.txt
lsof -i > /tmp/secure_work/initial_connections.txt
netstat -tupln > /tmp/secure_work/initial_ports.txt

# Connection Limiter (run as rc)
sudo tee /etc/security/limits.d/10-network.conf <<EOF
*               hard    nofile          65535
*               soft    nofile          65535
*               hard    nproc           65535
*               soft    nproc           65535
EOF

# Remove Pacman lock file at various stages
sudo rm -f /var/lib/pacman/db.lck
sudo rm -f /var/lib/pacman/db.lck
sudo rm -f /var/lib/pacman/db.lck
sudo rm -f /var/lib/pacman/db.lck

echo "Setup completed."
