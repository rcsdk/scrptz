#!/bin/bash
echo "Running Initial Bootkit Removal and System Hardening Script..."

# Timestamp and Locale
echo "Timestamp: $(date '+%Y-%m-%d %H:%M:%S')"
sudo timedatectl set-timezone America/Sao_Paulo
sudo localectl set-locale LANG=en_US.UTF-8

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
    if [[ $EUID -ne 0 ]]; then
        error "This script must be run as root. Use sudo or run as root."
    fi

    if [[ ! -f /etc/arch-release ]]; then
        error "This script is designed for Arch Linux systems only."
    fi
}

# Comprehensive Pacman Repair Procedure
pacman_repair() {
    log "Removing Pacman Lock Files"
    rm -f /var/lib/pacman/db.lck

    warn "Pacman Cache Cleanup"
    read -p "Do you want to remove ALL files from cache? [y/N] " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        log "Clearing Pacman Package Cache"
        rm -rf /var/cache/pacman/pkg/*
    fi

    log "Reinitializing Pacman Keyring"
    pacman-key --init
    pacman-key --populate archlinux

    log "Forcing Package Database Refresh"
    pacman -Syy

    log "Performing System Synchronization and Upgrade"
    pacman -Syu --noconfirm
}

# Advanced Filesystem Recovery
filesystem_recovery() {
    log "Initiating Filesystem Recovery"
    DEVICES=$(lsblk -ndo NAME)

    for device in $DEVICES; do
        full_device="/dev/$device"
        if [[ $device =~ ^(loop|ram) ]]; then
            continue
        fi
        warn "Checking Filesystem for $full_device"
        fsck -y "$full_device" || true
    done
}

# Network-based Package Database Recovery
network_recovery() {
    log "Attempting Network-based Package Database Recovery"
    if ! ping -c 4 archlinux.org > /dev/null 2>&1; then
        error "No network connectivity. Cannot perform network recovery."
    fi

    log "Downloading Fresh Package Databases"
    mkdir -p /var/lib/pacman/sync
    mirrors=(
        "https://mirror.archlinux.de/archlinux"
        "https://mirrors.kernel.org/archlinux"
        "https://mirror.0xem.ma/arch"
    )
    for mirror in "${mirrors[@]}"; do
        warn "Attempting Database Recovery from $mirror"
        curl -L "$mirror/core/os/x86_64/core.db" -o /var/lib/pacman/sync/core.db
        curl -L "$mirror/extra/os/x86_64/extra.db" -o /var/lib/pacman/sync/extra.db
        curl -L "$mirror/community/os/x86_64/community.db" -o /var/lib/pacman/sync/community.db
    done
    pacman -Syy
}

# Harden kernel
harden_kernel() {
    log "Hardening kernel..."
    cat << EOF | sudo tee /etc/sysctl.d/99-security.conf
kernel.kptr_restrict=2
kernel.dmesg_restrict=1
kernel.printk=3 3 3 3
kernel.unprivileged_bpf_disabled=1
net.core.bpf_jit_harden=2
EOF
    sudo sysctl -p /etc/sysctl.d/99-security.conf
}

# Set robust DNS servers
set_dns() {
    log "Setting robust DNS servers..."
    echo "nameserver 1.1.1.1" | sudo tee /etc/resolv.conf
    echo "nameserver 9.9.9.9" | sudo tee -a /etc/resolv.conf
    sudo chattr +i /etc/resolv.conf
}

# Kill all non-vital processes
kill_non_vital_processes() {
    log "Killing all non-vital processes..."
    for pid in $(ps -eo pid,comm | grep -Ev "(systemd|bash|ps|grep)" | awk '{print $1}'); do
        sudo kill -9 $pid 2>/dev/null
    done
}

# Main Execution
preflight_check
pacman_repair
filesystem_recovery
network_recovery
harden_kernel
set_dns
kill_non_vital_processes
echo "System Hardening Completed."
