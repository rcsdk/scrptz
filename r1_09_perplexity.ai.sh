#!/bin/bash -p  # Sanitizes environment for security

# Constants and Configurations
readonly SCRIPT_NAME="Super System Hardening Script"
readonly LOG_FILE="/var/log/super_hardening.log"
readonly BACKUP_DIR="/root/hardening_backups"
readonly DOWNLOAD_DIR="/var/cache/pacman/pkg/offline"
readonly TIMESTAMP="$(date '+%Y%m%d_%H%M%S')"
readonly MAX_RETRIES=3

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Enhanced Logging System
init_logging() {
    mkdir -p "$(dirname "$LOG_FILE")"
    touch "$LOG_FILE"
    chmod 600 "$LOG_FILE"  # Restrict access to owner only
}

log() {
    local message="$1"
    local timestamp="$(date '+%Y-%m-%d %H:%M:%S')"
    echo -e "${timestamp} [${SCRIPT_NAME}] ${message}" >> "$LOG_FILE"
    echo -e "${GREEN}[+] ${message}${NC}"
}

warn() {
    local message="$1"
    local timestamp="$(date '+%Y-%m-%d %H:%M:%S')"
    echo -e "${timestamp} [${SCRIPT_NAME}] WARNING: ${message}" >> "$LOG_FILE"
    echo -e "${YELLOW}[!] ${message}${NC}"
}

error() {
    local message="$1"
    local timestamp="$(date '+%Y-%m-%d %H:%M:%S')"
    echo -e "${timestamp} [${SCRIPT_NAME}] ERROR: ${message}" >> "$LOG_FILE"
    echo -e "${RED}[ERROR] ${message}${NC}" >&2
}

# Function to run a task and handle errors
run_task() {
    local task_name="$1"
    local task_command="$2"
    
    log "Starting task: $task_name"
    if eval "$task_command"; then
        log "Task completed: $task_name"
    else
        error "Task failed: $task_name"
        return 1
    fi
}

# Preflight Checks
preflight_check() {
    if [[ $EUID -ne 0 ]]; then
        error "This script must be run as root"
        exit 1
    fi

    if [[ ! -f /etc/arch-release ]]; then
        error "This script is designed for Arch Linux systems only"
        exit 1
    fi

    if ! ping -c 4 archlinux.org > /dev/null 2>&1; then
        error "No network connectivity. Cannot proceed with downloads"
        exit 1
    fi

    if [[ $(df / --output=avail | tail -n 1) -lt 5242880 ]]; then
        error "Not enough disk space available. Cannot proceed"
        exit 1
    fi
}

# Download Packages and Dependencies
download_packages() {
    log "Downloading Packages and Dependencies..."
    mkdir -p "$DOWNLOAD_DIR"

    PACKAGES=(
        ufw clamav rkhunter chkrootkit fail2ban aide cronie rsync
        selinux ossec-hids snort linux linux-firmware pacman apparmor
    )

    for package in "${PACKAGES[@]}"; do
        run_task "Download $package" "pacman -Sw --noconfirm --needed --cachedir=$DOWNLOAD_DIR $package"
    done
}

# Backup Configuration Files
backup_configs() {
    log "Backing up Configuration Files..."
    CONFIG_DIRS=(
        /etc/ufw /etc/clamav /etc/rkhunter.conf /etc/chkrootkit.conf
        /etc/fail2ban /etc/aide /etc/cronie /etc/rsyncd.conf
        /etc/selinux /etc/ossec /etc/snort /etc/default/grub
        /etc/pacman.conf /etc/pacman.d /etc/apparmor
    )

    mkdir -p "$BACKUP_DIR/configs"
    for dir in "${CONFIG_DIRS[@]}"; do
        if [[ -e "$dir" ]]; then
            run_task "Backup $dir" "cp -r $dir $BACKUP_DIR/configs/"
        else
            warn "Config not found: $dir"
        fi
    done
}

# Make Configuration Files Immutable
make_immutable() {
    log "Making Configuration Files Immutable..."
    run_task "Make configs immutable" "chattr +i -R $BACKUP_DIR/configs"
}

# Verify system integrity
verify_system_integrity() {
    run_task "Verify system integrity" "pacman -S --noconfirm --needed aide && aide --init && aide --check"
}

# Secure boot configuration
secure_boot_config() {
    run_task "Secure boot configuration" "
        pacman -S --noconfirm --needed grub &&
        grub-mkpasswd-pbkdf2 | tee /etc/grub.d/01_password &&
        chmod 600 /etc/grub.d/01_password &&
        sed -i 's/GRUB_CMDLINE_LINUX_DEFAULT=\"quiet\"/GRUB_CMDLINE_LINUX_DEFAULT=\"quiet lsm=lockdown,yama,apparmor,bpf\"/' /etc/default/grub &&
        grub-mkconfig -o /boot/grub/grub.cfg
    "
}

# Implement kernel hardening
harden_kernel() {
    run_task "Harden kernel" "
        cat << EOF >> /etc/sysctl.d/99
