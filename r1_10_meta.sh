#!/bin/bash

# Constants and Configurations
readonly SCRIPT_NAME="System Hardening Script"
readonly LOG_FILE="/var/log/hardening.log"
readonly BACKUP_DIR="/root/hardening_backups"
readonly TIMESTAMP="$(date '+%Y%m%d_%H%M%S')"
readonly MAX_RETRIES=3
readonly PACKAGE_DIR="/var/cache/pacman/pkg/offline"

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
    echo -e "${timestamp} [${SCRIPT_NAME}] ${message}" >> "$LOG_FILE"
    echo -e "${YELLOW}[!] ${message}${NC}"
}

error() {
    local message="$1"
    local timestamp="$(date '+%Y-%m-%d %H:%M:%S')"
    echo -e "${timestamp} [${SCRIPT_NAME}] ${message}" >> "$LOG_FILE"
    echo -e "${RED}[ERROR] ${message}${NC}"
}

# Verification System
verify_configurations() {
    local retry_count=0
    local all_passed=false
    
    while [[ $retry_count -lt $MAX_RETRIES && $all_passed == false ]]; do
        all_passed=true
        
        # Check DNS configuration
        if ! grep -q "nameserver 1.1.1.1" /etc/resolv.conf; then
            all_passed=false
            log "DNS configuration invalid - reapplying"
            set_dns
        fi
        
        # Check kernel hardening
        if ! grep -q "kernel.kptr_restrict=2" /etc/sysctl.d/99-security.conf; then
            all_passed=false
            log "Kernel hardening invalid - reapplying"
            harden_kernel
        fi
        
        # Check IPv6 status
        if ! grep -q "net.ipv6.conf.all.disable_ipv6 = 1" /etc/sysctl.conf; then
            all_passed=false
            log "IPv6 not disabled - reapplying"
            deactivate_ipv6
        fi
        
        if [[ $all_passed == false ]]; then
            retry_count=$((retry_count + 1))
            log "Verification failed (attempt $retry_count/$MAX_RETRIES)"
        fi
    done
    
    if [[ $all_passed == false ]]; then
        error "Failed to verify configurations after $MAX_RETRIES attempts"
    fi
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
    fi
}

# Download Packages and Dependencies
download_packages() {
    log "Downloading Packages and Dependencies..."
    run_task "Update package database" "pacman -Syy --noconfirm"
    PACKAGES=(
        ufw
        clamav
        rkhunter
        chkrootkit
        fail2ban
        aide
        cronie
        rsync
        selinux
        ossec-hids
        snort
        linux
        linux-firmware
        pacman
    )
    for package in "${PACKAGES[@]}"; do
        run_task "Download $package" "pacman -Sw --noconfirm $package"
        run_task "Install $package" "pacman -S --cachedir=$PACKAGE_DIR --noconfirm $package"
    done
    log "Packages and dependencies downloaded to $PACKAGE_DIR"
}

# Backup Configuration Files
backup_configs() {
    log "Backing up Configuration Files..."
    CONFIG_DIRS=(
        /etc/ufw
        /etc/clamav
        /etc/rkhunter.conf
        /etc/chkrootkit.conf
        /etc/fail2ban
        /etc/aide
        /etc/cronie
        /etc/rsyncd.conf
        /etc/selinux
        /etc/ossec
        /etc/snort
        /etc/default/grub
        /etc/pacman.conf
        /etc/pacman.d
    )
    mkdir -p "$BACKUP_DIR/configs"
    for dir in "${CONFIG_DIRS[@]}"; do
        if [[ -d "$dir" ]]; then
            run_task "Backup $dir" "cp -r $
