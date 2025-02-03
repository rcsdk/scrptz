#!/bin/bash
echo "[+] Starting initial system preparation..."

# Constants
LOG_FILE="/var/log/setup_errors.log"
USB_MOUNT_POINT="/mnt/usb_stick"
GIT_REPO="$USB_MOUNT_POINT/configs"

# Logging Function
log() {
    echo "[+] $1" | tee -a "$LOG_FILE"
}

warn() {
    echo "[!] $1" | tee -a "$LOG_FILE"
}

error() {
    echo "[ERROR] $1" | tee -a "$LOG_FILE"
}

# Preflight Checks
preflight_check() {
    log "Checking if script is run as root..."
    if [ "$EUID" -ne 0 ]; then
        error "This script must be run as root"
    else
        log "Script is run as root"
    fi

    log "Checking for Arch Linux..."
    if ! grep -qi "arch linux" /etc/os-release; then
        error "This script is designed for Arch Linux"
    else
        log "Detected Arch Linux"
    fi

    log "Checking for USB stick mount point..."
    if [ -z "$USB_MOUNT_POINT" ]; then
        error "USB stick mount point not set"
    else
        log "USB stick mount point set to $USB_MOUNT_POINT"
    fi

    log "Checking if USB stick is mounted..."
    if ! mount | grep -q "$USB_MOUNT_POINT"; then
        error "USB stick is not mounted at $USB_MOUNT_POINT"
    else
        log "USB stick is mounted at $USB_MOUNT_POINT"
    fi

    log "Checking network connectivity..."
    if ! ping -c 1 8.8.8.8 &> /dev/null; then
        error "Network connectivity check failed"
    else
        log "Network connectivity is available"
    fi

    log "Checking architecture..."
    if ! uname -m | grep -q "x86_64"; then
        error "Architecture check failed, expected x86_64"
    else
        log "Detected architecture: x86_64"
    fi

    log "Checking available disk space..."
    if ! df -h "$USB_MOUNT_POINT" | grep -q "avail"; then
        error "Disk space check failed"
    else
        log "Disk space is available"
    fi
}

# Create Directories
create_directories() {
    log "Creating cache directory..."
    mkdir -p "$USB_MOUNT_POINT/cache"
    if [ $? -ne 0 ]; then
        error "Failed to create cache directory"
    else
        log "Cache directory created"
    fi

    log "Creating config directory..."
    mkdir -p "$GIT_REPO"
    if [ $? -ne 0 ]; then
        error "Failed to create config directory"
    else
        log "Config directory created"
    fi

    log "Initializing Git repository..."
    cd "$GIT_REPO" || error "Failed to change directory to $GIT_REPO"
    git init
    if [ $? -ne 0 ]; then
        error "Failed to initialize Git repository"
    else
        log "Git repository initialized"
    fi
}

# Main Execution
main() {
    clear
    preflight_check
    create_directories
}

main

echo "[+] Preparation Offline Script completed."









#!/bin/bash
echo "[+] Starting download and breach scanning..."

# Constants
LOG_FILE="/var/log/setup_errors.log"
USB_MOUNT_POINT="/mnt/usb_stick"
GIT_REPO="$USB_MOUNT_POINT/configs"

# Logging Function
log() {
    echo "[+] $1" | tee -a "$LOG_FILE"
}

warn() {
    echo "[!] $1" | tee -a "$LOG_FILE"
}

error() {
    echo "[ERROR] $1" | tee -a "$LOG_FILE"
}

# Download Packages
download_packages() {
    log "Downloading packages and dependencies..."
    local packages=(
        "ufw" "clamav" "rkhunter" "chkrootkit" "fail2ban" "cronie" "rsync" "selinux" "ossec-hids" "snort" "linux" "linux-firmware" "pacman"
    )
    for package in "${packages[@]}"; do
        log "Downloading $package..."
        pacman -Syyu "$package" --noconfirm --cachedir="$USB_MOUNT_POINT/cache"
        if [ $? -ne 0 ]; then
            error "Failed to download $package"
        else
            log "Downloaded $package"
        fi
    done
}

# Backup Configuration Files
backup_configs() {
    log "Backing up configuration files..."
    local config_files=(
        "/etc/ufw"
        "/etc/clamav"
        "/etc/rkhunter.conf"
        "/etc/chkrootkit.conf"
        "/etc/fail2ban"
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
            log "Backing up directory $config..."
            cp -r "$config" "$GIT_REPO/"
            if [ $? -ne 0 ]; then
                error "Failed to backup directory $config"
            else
                log "Backed up directory $config"
            fi
        elif [[ -f "$config" ]]; then
            log "Backing up file $config..."
            cp "$config" "$GIT_REPO/"
            if [ $? -ne 0 ]; then
                error "Failed to backup file $config"
            else
                log "Backed up file $config"
            fi
        else
            warn "$config not found, skipping backup."
        fi
    done

    cd "$GIT_REPO" || error "Failed to change directory to $GIT_REPO"
    git add .
    if [ $? -ne 0 ]; then
        error "Failed to add files to Git"
    else
        log "Files added to Git"
    fi

    git commit -m "Backup configuration files"
    if [ $? -ne 0 ]; then
        error "Failed to commit files to Git"
    else
        log "Files committed to Git"
    fi
}

# Scan for Hidden Services
scan_hidden_services() {
    log "Scanning for hidden services..."
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
    log "Scanning and closing open ports..."
    local open_ports=$(sudo ss -tuln | awk 'NR>1 {print $5}' | cut -d':' -f2)
    for port in $open_ports; do
        if [[ "$port" != "80" ]]; then
            warn "Closing port $port"
            iptables -A INPUT -p tcp --dport "$port" -j DROP
            if [ $? -ne 0 ]; then
                error "Failed to close port $port"
            else
                log "Closed port $port"
            fi
        else
            log "Port $port (HTTP) is open and allowed."
        fi
    done
    iptables-save
    if [ $? -ne 0 ]; then
        error "Failed to save iptables rules"
    else
        log "Iptables rules saved"
    fi
}

# Scan for Hidden SSH
scan_hidden_ssh() {
    log "Scanning for hidden SSH..."
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
    log "Scanning kernel for compromise..."
    rkhunter --propupd
    if [ $? -ne 0 ]; then
        error "Failed to update rkhunter properties"
    else
        log "RKHunter properties updated"
    fi
    rkhunter --check --sk --summary
    if [ $? -ne 0 ]; then
        warn "Kernel scan found issues, check /var/log/rkhunter.log for details"
    else
        log "Kernel scan passed"
    fi
}

# Refresh All Configurations
refresh_configs() {
    log "Refreshing all configurations..."
    local config_dir="$GIT_REPO"
    local system_configs=(
        "/etc/ufw"
        "/etc/clamav"
        "/etc/rkhunter.conf"
        "/etc/chkrootkit.conf"
        "/etc/fail2ban"
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
            log "Refreshing $config..."
            cp -a "$config_dir/$(basename "$config")" "$config"
            if [ $? -ne 0 ]; then
                error "Failed to refresh $config"
            else
                log "Refreshed $config"
            fi
        elif [[ -d "$config_dir/$(basename "$config")" ]]; then
            log "Refreshing $config..."
            cp -a "$config_dir/$(basename "$config")" "$config"
            if [ $? -ne 0 ]; then
                error "Failed to refresh $config"
            else
                log "Refreshed $config"
            fi
        else
            warn "$config not found in USB stick, skipping refresh."
        fi
    done
}

# Main Execution
main() {
    clear
    download_packages
    backup_configs
    scan_hidden_services
    scan_and_close_ports
    scan_hidden_ssh
    scan_kernel
    refresh_configs
}

main

echo "[+] Download and Check for Breaches Script completed."









#!/bin/bash
echo "[+] Starting security setup..."

# Constants
LOG_FILE="/var/log/setup_errors.log"
USB_MOUNT_POINT="/mnt/usb_stick"

# Logging Function
log() {
    echo "[+] $1" | tee -a "$LOG_FILE"
}

warn() {
    echo "[!] $1" | tee -a "$LOG_FILE"
}

error() {
    echo "[ERROR] $1" | tee -a "$LOG_FILE"
}

# Secure Boot Configuration
secure_boot_config() {
    log "Securing boot configuration..."
    grub-mkconfig -o /boot/grub/grub.cfg
    if [ $? -ne 0 ]; then
        error "Failed to secure boot configuration"
    else
        log "Boot configuration secured"
    fi
}

# Harden Kernel
harden_kernel() {
    log "Hardening kernel..."
    cat << EOF | sudo tee /etc/sysctl.d/99-security.conf
kernel.kptr_restrict=2
kernel.dmesg_restrict=1
kernel.unprivileged_bpf_disabled=1
net.core.bpf_jit_harden=2
kernel.yama.ptrace_scope=2
kernel.kexec_load_disabled=1
EOF
    sysctl -p /etc/sysctl.d/99-security.conf
    if [ $? -ne 0 ]; then
        error "Failed to harden kernel"
    else
        log "Kernel hardened"
    fi
}

# Set up AppArmor
setup_apparmor() {
    log "Setting up AppArmor..."
    pacman -Syyu apparmor --noconfirm --needed
    if [ $? -ne 0 ]; then
        error "Failed to set up AppArmor"
    else
        log "AppArmor set up"
    fi
    systemctl enable apparmor
    if [ $? -ne 0 ]; then
        error "Failed to enable AppArmor"
    else
        log "AppArmor enabled"
    fi
    systemctl start apparmor
    if [ $? -ne 0 ]; then
        error "Failed to start AppArmor"
    else
        log "AppArmor started"
    fi
}

# Configure Secure Umask
set_secure_umask() {
    log "Configuring secure umask..."
    echo 'umask 027' >> /etc/profile
    if [ $? -ne 0 ]; then
        error "Failed to configure secure umask"
    else
        log "Secure umask configured"
    fi
    echo 'session optional pam_umask.so' >> /etc/pam.d/system-login
    if [ $? -ne 0 ]; then
        error "Failed to configure PAM umask"
    else
        log "PAM umask configured"
    fi
}

# Disable Core Dumps
disable_core_dumps() {
    log "Disabling core dumps..."
    echo '* hard core 0' >> /etc/security/limits.conf
    if [ $? -ne 0 ]; then
        error "Failed to disable core dumps"
    else
        log "Core dumps disabled"
    fi
    echo 'fs.suid_dumpable=0' >> /etc/sysctl.d/99-security.conf
    if [ $? -ne 0 ]; then
        error "Failed to configure sysctl for core dumps"
    else
        log "Sysctl configured for core dumps"
    fi
    sysctl -p /etc/sysctl.d/99-security.conf
    if [ $? -ne 0 ]; then
        error "Failed to apply sysctl configuration"
    else
        log "Sysctl configuration applied"
    fi
}

# Secure Shared Memory
secure_shared_memory() {
    log "Securing shared memory..."
    echo 'tmpfs /dev/shm tmpfs defaults,noexec,nosuid,nodev 0 0' >> /etc/fstab
    if [ $? -ne 0 ]; then
        error "Failed to configure shared memory"
    else
        log "Shared memory configured"
    fi
    mount -o remount /dev/shm
    if [ $? -ne 0 ]; then
        error "Failed to remount shared memory"
    else
        log "Shared memory remounted"
    fi
}

# Enable Process Accounting
enable_process_accounting() {
    log "Enabling process accounting..."
    pacman -Syyu acct --noconfirm --needed
    if [ $? -ne 0 ]; then
        error "Failed to enable process accounting"
    else
        log "Process accounting enabled"
    fi
    systemctl enable acct
    if [ $? -ne 0 ]; then
        error "Failed to enable acct service"
    else
        log "Acct service enabled"
    fi
    systemctl start acct
    if [ $? -ne 0 ]; then
        error "Failed to start acct service"
    else
        log "Acct service started"
    fi
}

# Set up Fail2ban
setup_fail2ban() {
    log "Setting up fail2ban..."
    pacman -Syyu fail2ban --noconfirm --needed
    if [ $? -ne 0 ]; then
        error "Failed to set up fail2ban"
    else
        log "Fail2ban set up"
    fi
    cp /etc/fail2ban/jail.conf /etc/fail2ban/jail.local
    if [ $? -ne 0 ]; then
        error "Failed to copy fail2ban configuration"
    else
        log "Fail2ban configuration copied"
    fi
    systemctl enable fail2ban
    if [ $? -ne 0 ]; then
        error "Failed to enable fail2ban"
    else
        log "Fail2ban enabled"
    fi
    systemctl start fail2ban
    if [ $? -ne 0 ]; then
        error "Failed to start fail2ban"
    else
        log "Fail2ban started"
    fi
}

# Configure Secure TTY
secure_tty() {
    log "Configuring secure TTY..."
    echo 'tty1' > /etc/securetty
    if [ $? -ne 0 ]; then
        error "Failed to configure secure TTY"
    else
        log "Secure TTY configured"
    fi
}

# Centralize Logs
centralize_logs() {
    log "Centralizing logs..."
    mkdir -p /var/log/centralized
    if [ $? -ne 0 ]; then
        error "Failed to create centralized log directory"
    else
        log "Centralized log directory created"
    fi
    mv /var/log/* /var/log/centralized/
    if [ $? -ne 0 ]; then
        error "Failed
        
        
        
        
        
        
        
        
        


