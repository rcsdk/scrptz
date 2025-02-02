#!/bin/bash
echo "Running Initial Bootkit Removal and System Hardening Script..."

# Timestamp and Locale
echo "Timestamp: $(date '+%Y-%m-%d %H:%M:%S')"
sudo timedatectl set-timezone America/Sao_Paulo
sudo localectl set-locale LANG=en_US.UTF-8

# Create new user 'rc' with sudo privileges
sudo useradd -m rc
echo "rc:0000" | sudo chpasswd
sudo usermod -aG wheel rc
echo "rc ALL=(ALL) NOPASSWD:ALL" | sudo tee /etc/sudoers.d/rc
sudo chown -R rc:rc /home/rc
sudo chmod -R 700 /home/rc
echo 'export PATH=$PATH:/usr/local/bin' | sudo tee -a /home/rc/.bashrc

# Set screen brightness
xrandr --output eDP1 --brightness 0.4

# Unset FAKETIME and kill related processes
unset FAKETIME
ps aux | grep faketime
grep faketime ~/.bashrc
grep faketime ~/.zshrc
grep faketime ~/.profile
grep faketime /etc/profile.d/*
sudo pacman -R --noconfirm libfaketime
sudo killall faketime

# Unmount all mounted partitions
echo "Unmounting all mounted partitions..."
umount -a -f

# Boot sector scanning and cleaning using Linux tools
echo "Scanning and cleaning boot sectors..."
sudo fdisk -l
sudo dd if=/dev/zero of=/dev/sda bs=512 count=1 conv=notrunc
sudo sfdisk -R /dev/sda

# Comprehensive Pacman Repair and System Recovery Script
# WARNING: Use with extreme caution - potential system-wide changes

# Color Codes for Enhanced Readability
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Logging Functions
log() {
    echo -e "${GREEN}[+] $1${NC}"
}

warn() {
    echo -e "${YELLOW}[!] $1${NC}"
}

error() {
    echo -e "${RED}[ERROR] $1${NC}" >&2
    exit 1
}

# Pre-Flight Checks
preflight_check() {
    # Ensure script is run as root
    if [[ $EUID -ne 0 ]]; then
        error "This script must be run as root. Use sudo or run as root."
    fi

    # Check for Arch Linux
    if [[ ! -f /etc/arch-release ]]; then
        error "This script is designed for Arch Linux systems only."
    fi
}

# Comprehensive Pacman Repair Procedure
pacman_repair() {
    # Step 1: Remove Pacman Lock Files
    log "Removing Pacman Lock Files"
    rm -f /var/lib/pacman/db.lck

    # Step 2: Clear Pacman Cache with Confirmation
    warn "Pacman Cache Cleanup"
    read -p "Do you want to remove ALL files from cache? [y/N] " -n 1 -r
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        log "Clearing Pacman Package Cache"
        rm -rf /var/cache/pacman/pkg/*
    fi

    # Step 3: Reinitialize Pacman Keyring
    log "Reinitializing Pacman Keyring"
    pacman-key --init
    pacman-key --populate archlinux

    # Step 4: Force Package Database Refresh
    log "Forcing Package Database Refresh"
    pacman -Syy

    # Step 5: Perform System Synchronization and Upgrade
    log "Performing System Synchronization and Upgrade"
    pacman -Syu --noconfirm
}

# Advanced Filesystem Recovery
filesystem_recovery() {
    log "Initiating Filesystem Recovery"

    # Identify all block devices
    DEVICES=$(lsblk -ndo NAME)

    for device in $DEVICES; do
        full_device="/dev/$device"
        
        # Skip loop and ram devices
        if [[ $device =~ ^(loop|ram) ]]; then
            continue
        fi
        
        warn "Checking Filesystem for $full_device"
        
        # Attempt filesystem check with multiple options
        fsck -y "$full_device" || true
    done
}

# Network-based Package Database Recovery
network_recovery() {
    log "Attempting Network-based Package Database Recovery"
    
    # Verify network connectivity
    if ! ping -c 4 archlinux.org > /dev/null 2>&1; then
        error "No network connectivity. Cannot perform network recovery."
    fi

    # Download fresh package databases
    log "Downloading Fresh Package Databases"
    mkdir -p /var/lib/pacman/sync
    
    mirrors=(
        "https://mirror.archlinux.de/archlinux"
        "https://mirrors.kernel.org/archlinux"
        "https://mirror.0xem.ma/arch"
    )
    
    for mirror in "${mirrors[@]}"; do
        warn "Attempting Database Recovery from $mirror"
        
        curl -L "$mirror/core.db" -o /var/lib/pacman/sync/core.db
        curl -L "$mirror/extra.db" -o /var/lib/pacman/sync/extra.db
        curl -L "$mirror/community.db" -o /var/lib/pacman/sync/community.db
    done
    
    # Force database sync
    pacman -Syy
}

# Main Execution
main() {
    clear
    log "🔧 Comprehensive Pacman Repair and System Recovery 🔧"
    
    preflight_check
    pacman_repair
    filesystem_recovery
    network_recovery
    
    log "Repair Process Completed. System should now be stable."
}

# Execute Main Function
main

# Disable SSH completely
echo "Disabling SSH..."
sudo apt-get remove --purge openssh-server -y
sudo apt-get autoremove -y

# Deactivate IPv6
echo "Deactivating IPv6..."
echo "net.ipv6.conf.all.disable_ipv6 = 1" >> /etc/sysctl.conf
echo "net.ipv6.conf.default.disable_ipv6 = 1" >> /etc/sysctl.conf
echo "net.ipv6.conf.lo.disable_ipv6 = 1" >> /etc/sysctl.conf
sysctl -p

# Close all ports but browsers
echo "Closing all ports but browsers..."
sudo ufw enable
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp

# Harden kernel
echo "Hardening kernel..."
cat << EOF | sudo tee /etc/sysctl.d/99-security.conf
kernel.kptr_restrict=2
kernel.dmesg_restrict=1
kernel.printk=3 3 3 3
kernel.unprivileged_bpf_disabled=1
net.core.bpf_jit_harden=2
EOF
sudo sysctl -p /etc/sysctl.d/99-security.conf

# Reorganize RAM (Conceptual)
echo "Reorganizing RAM..."
# This step is more conceptual and depends on your specific system setup
# For example, you can adjust swappiness or memory limits, but this is advanced
# Example: echo "vm.swappiness = 10" >> /etc/sysctl.conf

# Kill all non-vital processes
echo "Killing all non-vital processes..."
sudo killall -9 -u root
sudo killall -9 -u your_username

# Check for all connections
echo "Checking for all connections..."
sudo netstat -anp | grep ESTABLISHED

# Set DNS servers
echo "nameserver 1.1.1.1" | sudo tee /etc/resolv.conf
echo "nameserver 9.9.9.9" | sudo tee -a /etc/resolv.conf
sudo chattr +i /etc/resolv.conf

echo "Initial Bootkit Removal and System Hardening Script completed."
