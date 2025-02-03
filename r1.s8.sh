#!/bin/bash

# Constants and Configurations
readonly SCRIPT_NAME="Comprehensive System Hardening and Backup Script"
readonly LOG_FILE="/var/log/hardening.log"
readonly BACKUP_DIR="/mnt/usb_stick/secure_backup"
readonly CHECKSUM_FILE="$BACKUP_DIR/checksums.txt"
readonly REPORT_FILE="$BACKUP_DIR/verification_report.txt"
readonly TIMESTAMP="$(date '+%Y%m%d_%H%M%S')"
readonly MAX_RETRIES=3

# Color Codes for Enhanced Readability
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Logging Functions
init_logging() {
    mkdir -p "$(dirname "$LOG_FILE")"
    touch "$LOG_FILE"
    chmod 600 "$LOG_FILE"
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

# Preflight Check
preflight_check() {
    if [[ $EUID -ne 0 ]]; then
        error "This script must be run as root. Use sudo."
        return 1
    fi

    if [[ ! -w "$BACKUP_DIR" ]]; then
        error "Backup directory '$BACKUP_DIR' is not writable. Check permissions and mount point."
        return 1
    fi

    if [[ ! -f /etc/arch-release ]]; then
        error "This script is designed for Arch Linux systems only."
        return 1
    fi

    if ! ping -c 4 archlinux.org > /dev/null 2>&1; then
        error "No network connectivity. Cannot proceed."
        return 1
    fi

    if [[ $(uname -m) != "x86_64" ]]; then
        error "This script is designed for x86_64 architecture only."
        return 1
    fi

    if [[ $(df / --output=avail | tail -n 1) -lt 5242880 ]]; then
        error "Not enough disk space available. Cannot proceed."
        return 1
    fi
}

# Backup Functions
backup_file() {
    local source_file="$1"
    local target_file="$2"
    log "Backing up $source_file..."
    mkdir -p "$(dirname "$target_file")" || error "Failed to create directory"
    cp "$source_file" "$target_file" || error "Failed to copy $source_file"
    chattr +i "$target_file" || warn "Failed to make $target_file immutable"
}

backup_dir() {
    local source_dir="$1"
    local target_dir="$2"
    log "Backing up $source_dir..."
    mkdir -p "$target_dir" || error "Failed to create directory"
    cp -r "$source_dir" "$target_dir" || error "Failed to copy $source_dir"
    find "$target_dir" -type f -exec chattr +i {} \; || warn "Failed to make files immutable"
    find "$target_dir" -type d -exec chattr +i {} \; || warn "Failed to make directories immutable"
}

download_package() {
    local pkg_name="$1"
    log "Downloading $pkg_name and dependencies..."

    local temp_dir=$(mktemp -d) || error "Failed to create temporary directory"
    local pkg_dir="$temp_dir/pkg"
    mkdir -p "$pkg_dir" || error "Failed to create package directory"

    if ! pacman -Sw --noconfirm "$pkg_name" --cachedir "$pkg_dir"; then
        error "Failed to download $pkg_name. Check the package name and your internet connection."
        return 1
    fi

    find "$pkg_dir" -name "*.pkg.tar.xz" -print0 | xargs -0 -I {} sh -c 'cp {} "$BACKUP_DIR/pkg/" || error "Failed to copy {}"'

    rm -rf "$temp_dir" || warn "Failed to remove temporary directory"

    log "Downloaded $pkg_name and dependencies to $BACKUP_DIR/pkg"
}

# Verification Functions
verify_file() {
    local file_path="$1"
    if [[ -f "$file_path" ]]; then
        return 0
    else
        return 1
    fi
}

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
        return 1
    fi
}

# System Hardening Functions
set_dns() {
    log "Setting DNS..."
    echo "nameserver 1.1.1.1" | sudo tee /etc/resolv.conf
    echo "nameserver 9.9.9.9" | sudo tee -a /etc/resolv.conf
    sudo chattr +i /etc/resolv.conf
}

harden_kernel() {
    log "Hardening kernel..."
    cat << EOF | sudo tee /etc/sysctl.d/99-security.conf
kernel.kptr_restrict=2
kernel.dmesg_restrict=1
kernel.unprivileged_bpf_disabled=1
net.core.bpf_jit_harden=2
EOF
    sudo sysctl -p /etc/sysctl.d/99-security.conf
}

deactivate_ipv6() {
    log "Deactivating IPv6..."
    echo "net.ipv6.conf.all.disable_ipv6 = 1" | sudo tee -a /etc/sysctl.conf
    echo "net.ipv6.conf.default.disable_ipv6 = 1" | sudo tee -a /etc/sysctl.conf
    echo "net.ipv6.conf.lo.disable_ipv6 = 1" | sudo tee -a /etc/sysctl.conf
    sudo sysctl -p
}

secure_boot_config() {
    log "Securing boot configuration..."
    sudo pacman -S grub &&
    sudo grub-mkpasswd-pbkdf2 | sudo tee /etc/grub.d/01_password &&
    sudo chmod 600 /etc/grub.d/01_password &&
    sudo sed -i 's/GRUB_CMDLINE_LINUX_DEFAULT=\"quiet\"/GRUB_CMDLINE_LINUX_DEFAULT=\"quiet lsm=lockdown,yama,apparmor,bpf\"/' /etc/default/grub &&
    sudo grub-mkconfig -o /boot/grub/grub.cfg
}

setup_apparmor() {
    log "Setting up AppArmor..."
    sudo pacman -S apparmor &&
    sudo systemctl enable apparmor &&
    sudo systemctl start apparmor
}

set_secure_umask() {
    log "Setting secure umask..."
    echo 'umask 027' >> /etc/profile &&
    echo 'session optional pam_umask.so' >> /etc/pam.d/system-login
}

disable_core_dumps() {
    log "Disabling core dumps..."
    echo '* hard core 0' >> /etc/security/limits.conf &&
    echo 'fs.suid_dumpable=0' >> /etc/sysctl.d/99-security.conf &&
    sudo sysctl -p /etc/sysctl.d/99-security.conf
}

secure_shared_memory() {
    log "Securing shared memory..."
    echo 'tmpfs /dev/shm tmpfs defaults,noexec,nosuid,nodev 0 0' >> /etc/fstab &&
    sudo mount -o remount /dev/shm
}

enable_process_accounting() {
    log "Enabling process accounting..."
    sudo pacman -S acct &&
    sudo systemctl enable acct &&
    sudo systemctl start acct
}

setup_fail2ban() {
    log "Setting up fail2ban..."
    sudo pacman -S fail2ban &&
    sudo cp /etc/fail2ban/jail.conf /etc/fail2ban/jail.local &&
    sudo systemctl enable fail2ban &&
    sudo systemctl start fail2ban
}

secure_tty() {
    log "Securing TTY..."
    echo 'tty1' > /etc/securetty
}

# Main Execution
main() {
    clear
    log "Starting Comprehensive System Hardening and Backup Script..."

    init_logging
    preflight_check || return 1

    # Package Download
    log "Downloading packages and dependencies..."
    packages=(
        ufw clamav rkhunter chkrootkit fail2ban aide cronie rsync selinux ossec-hids snort linux linux-firmware pacman
        coreutils systemd grub apparmor acct
    )
    mkdir -p "$BACKUP_DIR/pkg" || return 1
    for pkg in "${packages[@]}"; do
        download_package "$pkg" || warn "Failed to download package: $pkg"
    done

    # Configuration Backup
    log "Backing up configuration files..."
    config_files=(
        /etc/resolv.conf /etc/hosts /etc/fstab /etc/pacman.conf /etc/sysctl.d/99-security.conf
        /etc/nftables.conf /etc/selinux/config /etc/passwd /etc/group /etc/shadow
        /boot/grub/grub.cfg
    )
    config_dirs=(
        /etc/clamav /etc/rkhunter.conf.d /etc/chkrootkit.conf /etc/systemd /etc/default /etc/security
        /etc/selinux /var/lib/ossec /etc/snort /lib/modules/$(uname -r)
        /var/lib/aide
    )
    mkdir -p "$BACKUP_DIR/etc" "$BACKUP_DIR/boot" "$BACKUP_DIR/var/lib" || return 1
    for config in "${config_files[@]}"; do
        backup_file "$config" "$BACKUP_DIR/$config" || warn "Failed to backup file: $config"
    done
    for dir in "${config_dirs[@]}"; do
        backup_dir "$dir" "$BACKUP_DIR/$dir" || warn "Failed to backup directory: $dir"
    done

    # Checksum Verification
    log "Creating checksum file..."
    find "$BACKUP_DIR" -type f -print0 | xargs -0 sha256sum > "$CHECKSUM_FILE" || warn "Failed to create checksum file"

    # Verification Report
    log "Generating verification report..."
    > "$REPORT_FILE"
    for file in "${config_files[@]}"; do
        if ! verify_file "$BACKUP_DIR/$file"; then
            echo "[FAIL] $file is missing!" >> "$REPORT_FILE"
            warn "$file is missing!"
        else
            echo "[PASS] $file is present." >> "$REPORT_FILE"
        fi
    done
    for dir in "${config_dirs[@]}"; do
        if ! verify_file "$BACKUP_DIR/$dir"; then
            echo "[FAIL] $dir is missing!" >> "$REPORT_FILE"
            warn "$dir is missing!"
        else
            echo "[PASS] $dir is present." >> "$REPORT_FILE"
        fi
    done
    if [[ -f "$CHECKSUM_FILE" ]]; then
        diff -u "$CHECKSUM_FILE" <(find "$BACKUP_DIR" -type f -print0 | xargs -0 sha256sum | sort) >> "$REPORT_FILE"
        if grep -q '^+' "$REPORT_FILE"; then
            warn "Checksum mismatches found. Check $REPORT_FILE"
        else
            log "Checksums match."
        fi
    fi
    log "Verification Report: $REPORT_FILE"
    cat "$REPORT_FILE"

    # System Hardening
    log "Starting system hardening..."
    set_dns
    harden_kernel
    deactivate_ipv6
    secure_boot_config
    setup_apparmor
    set_secure_umask
    disable_core_dumps
    secure_shared_memory
    enable_process_accounting
    setup_fail2ban
    secure_tty

    # Verify Configurations
    log "Verifying configurations..."
    verify_configurations || return 1

    log "All configurations verified successfully"
}

main
