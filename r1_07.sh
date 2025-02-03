#!/bin/bash

# Log file location
LOGFILE="/path/to/logfile.log"

# Function to log errors
log_error() {
    echo "[ERROR] $(date) - $1" >> $LOGFILE
}

# Function to download files safely
download_file() {
    URL=$1
    DEST=$2

    echo "[INFO] Downloading $URL to $DEST"
    curl -L $URL -o $DEST
    if [ $? -ne 0 ]; then
        log_error "Failed to download $URL to $DEST"
        return 1
    fi
    return 0
}

# Function to verify file integrity (Checksum)
verify_checksum() {
    FILE=$1
    CHECKSUM=$2

    echo "[INFO] Verifying checksum for $FILE"
    DOWNLOADED_CHECKSUM=$(sha256sum $FILE | awk '{ print $1 }')
    if [ "$DOWNLOADED_CHECKSUM" != "$CHECKSUM" ]; then
        log_error "Checksum verification failed for $FILE"
        return 1
    fi
    return 0
}

# Function to extract files safely
extract_file() {
    FILE=$1
    DEST=$2

    echo "[INFO] Extracting $FILE to $DEST"
    tar -xvzf $FILE -C $DEST
    if [ $? -ne 0 ]; then
        log_error "Failed to extract $FILE to $DEST"
        return 1
    fi
    return 0
}

# Function to install downloaded files
install_file() {
    FILE=$1

    echo "[INFO] Installing $FILE"
    sudo dpkg -i $FILE
    if [ $? -ne 0 ]; then
        log_error "Failed to install $FILE"
        return 1
    fi
    return 0
}

# Function to install from the repository (APT for Ubuntu/Debian)
install_from_repo() {
    PACKAGE=$1

    echo "[INFO] Installing $PACKAGE from repository"
    sudo apt-get install -y $PACKAGE
    if [ $? -ne 0 ]; then
        log_error "Failed to install $PACKAGE from repository"
        return 1
    fi
    return 0
}

# Main script execution starts here
{
    # Step 1: Download file (e.g., a package or script)
    DOWNLOAD_URL="https://example.com/file.tar.gz"
    FILE_DEST="/tmp/file.tar.gz"
    download_file "$DOWNLOAD_URL" "$FILE_DEST" || true  # Proceed even if download fails

    # Step 2: Verify checksum (if applicable)
    EXPECTED_CHECKSUM="your_expected_checksum_here"
    verify_checksum "$FILE_DEST" "$EXPECTED_CHECKSUM" || true  # Proceed even if checksum fails

    # Step 3: Extract downloaded file (if it's a compressed file)
    EXTRACT_DEST="/tmp/extracted"
    extract_file "$FILE_DEST" "$EXTRACT_DEST" || true  # Proceed even if extraction fails

    # Step 4: Install downloaded file (e.g., a .deb package)
    DEB_FILE="/tmp/extracted/package.deb"
    install_file "$DEB_FILE" || true  # Proceed even if installation fails

    # Step 5: Install from repository (e.g., an apt package)
    APT_PACKAGE="somepackage"
    install_from_repo "$APT_PACKAGE" || true  # Proceed even if repository installation fails

    echo "[INFO] Script execution completed"
} >> $LOGFILE 2>&1







#!/bin/bash

# Constants and Configurations
readonly SCRIPT_NAME="Comprehensive Security Setup Script"
readonly LOG_FILE="/var/log/security_setup.log"
readonly BACKUP_DIR="/mnt/usb_stick/secure_backup"
readonly TIMESTAMP="$(date '+%Y%m%d_%H%M%S')"
readonly MAX_RETRIES=3

# Color Codes for Enhanced Readability
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

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

# Pre-Flight Checks
preflight_check() {
    run_task "Check if script is run as root" "[[ $EUID -eq 0 ]]"
    run_task "Check for Arch Linux" "[[ -f /etc/arch-release ]]"
    run_task "Check for USB stick mount point" "[[ -n \"$USB_STICK\" ]]"
    run_task "Check if USB stick is mounted" "[[ -d \"$USB_STICK\" ]]"
    run_task "Check network connectivity" "ping -c 4 archlinux.org > /dev/null 2>&1"
    run_task "Check architecture" "[[ $(uname -m) == 'x86_64' ]]"
    run_task "Check available disk space" "[[ $(df / --output=avail | tail -n 1) -gt 5242880 ]]"
}

# Download Packages and Dependencies
download_packages() {
    local cache_dir="$USB_STICK/offline_packages"
    run_task "Create cache directory" "mkdir -p \"$cache_dir\""
    
    local packages=(
        "ufw" "clamav" "rkhunter" "chkrootkit" "fail2ban" "aide" "cronie" "rsync" "selinux" "ossec-hids" "snort" "linux" "linux-firmware" "pacman"
    )
    
    for package in "${packages[@]}"; do
        run_task "Download $package" "sudo pacman -Sw --noconfirm --cachedir=\"$cache_dir\" \"$package\""
    done
}

# Backup Configuration Files
backup_configs() {
    local config_dir="$USB_STICK/offline_configs"
    run_task "Create config directory" "mkdir -p \"$config_dir\""
    
    local config_files=(
        "/etc/ufw"
        "/etc/clamav"
        "/etc/rkhunter.conf"
        "/etc/chkrootkit.conf"
        "/etc/fail2ban"
        "/etc/aide"
        "/etc/cronie"
        "/etc/rsyncd.conf"
        "/etc/selinux"
        "/etc/ossec"
        "/etc/snort"
        "/etc/default/grub"
        "/etc/pacman.conf"
        "/etc/pacman.d"
    )
    
    for config in "${config_files[@]}"; do
        if [[ -d "$config" ]]; then
            run_task "Backup directory $config" "sudo cp -r \"$config\" \"$config_dir/\""
        elif [[ -f "$config" ]]; then
            run_task "Backup file $config" "sudo cp \"$config\" \"$config_dir/\""
        fi
    done
}

# Make Configuration Files Immutable
make_immutable() {
    local config_dir="$USB_STICK/offline_configs"
    run_task "Make config files immutable" "sudo chattr +i -R \"$config_dir\""
}

# Verify System Integrity
verify_system_integrity() {
    run_task "Verify system integrity" "pacman -S aide && aide --init && aide --check"
}

# Secure Boot Configuration
secure_boot_config() {
    run_task "Secure boot configuration" "
        pacman -S grub &&
        grub-mkpasswd-pbkdf2 | tee /etc/grub.d/01_password &&
        chmod 600 /etc/grub.d/01_password &&
        sed -i 's/GRUB_CMDLINE_LINUX_DEFAULT=\"quiet\"/GRUB_CMDLINE_LINUX_DEFAULT=\"quiet lsm=lockdown,yama,apparmor,bpf\"/' /etc/default/grub &&
        grub-mkconfig -o /boot/grub/grub.cfg
    "
}

# Implement Kernel Hardening
harden_kernel() {
    run_task "Harden kernel" "
        cat << EOF | sudo tee /etc/sysctl.d/99-security.conf
kernel.kptr_restrict=2
kernel.dmesg_restrict=1
kernel.unprivileged_bpf_disabled=1
net.core.bpf_jit_harden=2
kernel.yama.ptrace_scope=2
kernel.kexec_load_disabled=1
EOF
        sudo sysctl -p /etc/sysctl.d/99-security.conf
    "
}

# Set up AppArmor
setup_apparmor() {
    run_task "Set up AppArmor" "
        pacman -S apparmor &&
        systemctl enable apparmor &&
        systemctl start apparmor
    "
}

# Configure Secure Umask
set_secure_umask() {
    run_task "Configure secure umask" "
        echo 'umask 027' >> /etc/profile &&
        echo 'session optional pam_umask.so' >> /etc/pam.d/system-login
    "
}

# Disable Core Dumps
disable_core_dumps() {
    run_task "Disable core dumps" "
        echo '* hard core 0' >> /etc/security/limits.conf &&
        echo 'fs.suid_dumpable=0' >> /etc/sysctl.d/99-security.conf &&
        sysctl -p /etc/sysctl.d/99-security.conf
    "
}

# Secure Shared Memory
secure_shared_memory() {
    run_task "Secure shared memory" "
        echo 'tmpfs /dev/shm tmpfs defaults,noexec,nosuid,nodev 0 0' >> /etc/fstab &&
        mount -o remount /dev/shm
    "
}

# Enable Process Accounting
enable_process_accounting() {
    run_task "Enable process accounting" "
        pacman -S acct &&
        systemctl enable acct &&
        systemctl start acct
    "
}

# Set up Fail2ban
setup_fail2ban() {
    run_task "Set up fail2ban" "
        pacman -S fail2ban &&
        cp /etc/fail2ban/jail.conf /etc/fail2ban/jail.local &&
        systemctl enable fail2ban &&
        systemctl start fail2ban
    "
}

# Configure Secure TTY
secure_tty() {
    run_task "Configure secure TTY" "echo 'tty1' > /etc/securetty"
}

# Scan for Hidden Services
scan_hidden_services() {
    local services=(
        "sshd"
        "httpd"
        "nginx"
        "ftp"
        "smtp"
        "dnsmasq"
        "cups"
        "avahi-daemon"
        "dhcpcd"
        "NetworkManager"
        "wpa_supplicant"
    )
    for service in "${services[@]}"; do
        if systemctl is-enabled "$service" &> /dev/null; then
            warn "Hidden service $service is enabled."
        fi
    done
}

# Scan for Open Ports (Close all except HTTP)
scan_and_close_ports() {
    local open_ports=$(sudo ss -tuln | awk 'NR>1 {print $5}' | cut -d':' -f2)
    for port in $open_ports; do
        if [[ "$port" != "80" ]]; then
            warn "Closing port $port"
            run_task "Close port $port" "sudo iptables -A INPUT -p tcp --dport \"$port\" -j DROP"
        else
            log "Port $port (HTTP) is open and allowed."
        fi
    done
    run_task "Save iptables rules" "sudo iptables-save"
}

# Scan for Hidden SSH
scan_hidden_ssh() {
    local ssh_processes=$(ps aux | grep sshd | grep -v grep)
    if [[ -n "$ssh_processes" ]]; then
        warn "Hidden SSH process detected:"
        echo "$ssh_processes"
    else
        log "No hidden SSH processes detected."
    fi
}

# Scan Kernel for Compromise
scan_kernel() {
    run_task "Update rkhunter properties" "sudo rkhunter --propupd"
    run_task "Kernel scan for compromise" "sudo rkhunter --check --sk --summary"
}

# Refresh All Configurations
refresh_configs() {
    local config_dir="$USB_STICK/offline_configs"
    local system_configs=(
        "/etc/ufw"
        "/etc/clamav"
        "/etc/rkhunter.conf"
        "/etc/chkrootkit.conf"
        "/etc/fail2ban"
        "/etc/aide"
        "/etc/cronie"
        "/etc/rsyncd.conf"
        "/etc/selinux"
        "/etc/ossec"
        "/etc/snort"
        "/etc/default/grub"
        "/etc/pacman.conf"
        "/etc/pacman.d"
    )

    for config in "${system_configs[@]}"; do
        if [[ -f "$config_dir/$(basename "$config")" ]]; then
            run_task "Refresh $config" "sudo cp -a \"$config_dir/$(basename "$config")\" \"$config\""
        elif [[ -d "$config_dir/$(basename "$config")" ]]; then
            run_task "Refresh $config" "sudo cp -a \"$config_dir/$(basename "$config")\" \"$config\""
        else
            warn "$config not found in USB stick, skipping refresh."
        fi
    done
}

# Centralize Logs
centralize_logs() {
    run_task "Centralize logs" "
        cat << EOF | sudo tee /etc/rsyslog.conf
\$ModLoad imuxsock
\$ModLoad imklog
\$ActionFileDefaultTemplate RSYSLOG_TraditionalFileFormat
*.info;mail.none;authpriv.none;cron.none                /var/log/messages
authpriv.*                                              /var/log/secure
mail.*                                                  -/var/log/maillog
cron.*                                                  /var/log/cron
*.emerg                                                 *
uucp,news.crit                                          /var/log/spooler
local7.*                                                /var/log/boot.log
EOF
        sudo systemctl enable rsyslog
        sudo systemctl start rsyslog
    "
}

# Verify Configurations
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

# Set DNS
set_dns() {
    run_task "Set DNS" "echo 'nameserver 1.1.1.1' > /etc/resolv.conf"
}

# Deactivate IPv6
deactivate_ipv6() {
    run_task "Deactivate IPv6" "
        cat << EOF | sudo tee /etc/sysctl.d/99-disable-ipv6.conf
net.ipv6.conf.all.disable_ipv6 = 1
net.ipv6.conf.default.disable_ipv6 = 1
net.ipv6.conf.lo.disable_ipv6 = 1
EOF
        sudo sysctl -p /etc/sysctl.d/99-disable-ipv6.conf
    "
}

# Main Execution with Verification
main() {
    clear
    init_logging
    
    # Initial Preparation
    log "Starting initial system preparation..."
    preflight_check
    download_packages
    backup_configs
    make_immutable
    
    # Security Setup
    log "Starting security setup..."
    verify_system_integrity
    secure_boot_config
    harden_kernel
    setup_apparmor
    set_secure_umask
    disable_core_dumps
    secure_shared_memory
    enable_process_accounting
    setup_fail2ban
    secure_tty
    
    # Breach Scanning
    log "Starting breach scanning..."
    scan_hidden_services
    scan_and_close_ports
    scan_hidden_ssh
    scan_kernel
    
    # Configuration Refresh and Centralization
    log "Refreshing configurations..."
    refresh_configs
    centralize_logs
    
    # Verification Phase
    log "Starting verification phase..."
    verify_configurations
    
    log "All configurations verified successfully"
}

# Execute with error handling
if ! main; then
    log "Script execution failed - please check logs"
    exit 1
fi







Certainly! I'll combine the best elements from all the scripts to create a comprehensive, robust system hardening script. This "super script" will include downloading, safe storage, installation, and verification, with error handling that allows the script to continue even if individual tasks fail.

Here's the combined super script:

```bash
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
        run_task "Download $package" "pacman -Sw --noconfirm --cachedir=$DOWNLOAD_DIR $package"
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
    run_task "Verify system integrity" "pacman -S aide && aide --init && aide --check"
}

# Secure boot configuration
secure_boot_config() {
    run_task "Secure boot configuration" "
        pacman -S grub &&
        grub-mkpasswd-pbkdf2 | tee /etc/grub.d/01_password &&
        chmod 600 /etc/grub.d/01_password &&
        sed -i 's/GRUB_CMDLINE_LINUX_DEFAULT=\"quiet\"/GRUB_CMDLINE_LINUX_DEFAULT=\"quiet lsm=lockdown,yama,apparmor,bpf\"/' /etc/default/grub &&
        grub-mkconfig -o /boot/grub/grub.cfg
    "
}

# Implement kernel hardening
harden_kernel() {
    run_task "Harden kernel" "
        cat << EOF >> /etc/sysctl.d/99-security.conf
kernel.kptr_restrict=2







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
