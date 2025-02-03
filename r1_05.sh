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
    # Ensure script is run as root
    if [[ $EUID -ne 0 ]]; then
        error "This script must be run as root. Use sudo or run as root."
    fi

    # Check for Arch Linux
    if [[ ! -f /etc/arch-release ]]; then
        error "This script is designed for Arch Linux systems only."
    fi

    # Check for required tools
    required_tools=("curl" "debugfs" "netstat" "xrandr" "lsof" "nmap" "iptables" "rsyslog" "logrotate" "aide" "rkhunter" "clamav" "clamav-daemon" "ss")
    for tool in "${required_tools[@]}"; do
        if ! command -v "$tool" &> /dev/null; then
            error "$tool could not be found. Please install it."
        fi
    done
}

# Comprehensive Pacman Repair Procedure
pacman_repair() {
    # Step 1: Remove Pacman Lock Files
    log "Removing Pacman Lock Files"
    rm -f /var/lib/pacman/db.lck || error "Failed to remove Pacman Lock Files"

    # Step 2: Clear Pacman Cache with Confirmation
    warn "Pacman Cache Cleanup"
    read -p "Do you want to remove ALL files from cache? [y/N] " -n 1 -r
    echo    # move to a new line
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        log "Clearing Pacman Package Cache"
        rm -rf /var/cache/pacman/pkg/* || error "Failed to clear Pacman Cache"
    fi

    # Step 3: Reinitialize Pacman Keyring
    log "Reinitializing Pacman Keyring"
    pacman-key --init || error "Failed to initialize Pacman Keyring"
    pacman-key --populate archlinux || error "Failed to populate Pacman Keyring"

    # Step 4: Force Package Database Refresh
    log "Forcing Package Database Refresh"
    pacman -Syy || error "Failed to refresh package database"

    # Step 5: Perform System Synchronization and Upgrade
    log "Performing System Synchronization and Upgrade"
    pacman -Syu --noconfirm || error "Failed to synchronize and upgrade system"
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
        curl -L "$mirror/core/os/x86_64/core.db" -o /var/lib/pacman/sync/core.db || error "Failed to download core.db"
        curl -L "$mirror/extra/os/x86_64/extra.db" -o /var/lib/pacman/sync/extra.db || error "Failed to download extra.db"
        curl -L "$mirror/community/os/x86_64/community.db" -o /var/lib/pacman/sync/community.db || error "Failed to download community.db"
    done
    pacman -Syy || error "Failed to sync package databases"
}

# Fix Inodes
fix_inodes() {
    local inode_list=$(dumpe2fs -h /dev/sda1 | grep -oP '(?<=Inode count:)\s*\K\d+')
    for inode in $(seq 1 $inode_list); do
        if ! sudo debugfs -R "stat <$inode>" /dev/sda1 > /dev/null 2>&1; then
            warn "Inode $inode does not exist. Skipping..."
            continue
        fi
        sudo debugfs -R "dump <$inode> /tmp/inode_dump_$inode" /dev/sda1 > /dev/null 2>&1
        if [[ $(file /tmp/inode_dump_$inode) =~ garbage ]]; then
            read -p "Inode $inode seems to contain garbage. Clear? [y/N] " -n 1 -r
            echo    # move to a new line
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                sudo debugfs -R "rm <$inode>" /dev/sda1 || error "Failed to clear inode $inode"
                log "Inode $inode cleared."
            else
                log "Inode $inode not cleared."
            fi
        fi
        rm -f /tmp/inode_dump_$inode

        flags=$(sudo debugfs -R "stat <$inode>" /dev/sda1 | grep "Flags:")
        if [[ $flags =~ "casefold" || $flags =~ "ea_inode" ]]; then
            read -p "Inode $inode has incorrect flags set. Clear flags? [y/N] " -n 1 -r
            echo    # move to a new line
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                sudo debugfs -R "set_inode_flag <$inode> -casefold -ea_inode" /dev/sda1 || error "Failed to clear flags on inode $inode"
                log "Inode $inode flags cleared."
            else
                log "Inode $inode flags not cleared."
            fi
        fi

        if [[ $flags =~ "inline" || $flags =~ "extent" ]]; then
            read -p "Inode $inode has inline data and extent flags set but i_block contains junk. Clear inode? [y/N] " -n 1 -r
            echo    # move to a new line
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                sudo debugfs -R "rm <$inode>" /dev/sda1 || error "Failed to clear inode $inode"
                log "Inode $inode cleared."
            else
                log "Inode $inode not cleared."
            fi
        fi

        dtime=$(sudo debugfs -R "stat <$inode>" /dev/sda1 | grep "dtime" | awk '{print $2}')
        if [[ "$dtime" -eq 0 ]]; then
            read -p "Deleted inode $inode has zero dtime. Fix? [y/N] " -n 1 -r
            echo    # move to a new line
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                sudo debugfs -R "set_inode_field <$inode> dtime $(date +%s)" /dev/sda1 || error "Failed to fix dtime on inode $inode"
                log "Inode $inode dtime fixed."
            else
                log "Inode $inode dtime not fixed."
            fi
        fi
    done
}

# Create new user 'rc' with sudo privileges
create_user() {
    log "Creating new user 'rc' with sudo privileges"
    sudo useradd -m rc || error "Failed to create user 'rc'"
    echo "rc:0000" | sudo chpasswd || error "Failed to set password for 'rc'"
    sudo usermod -aG wheel rc || error "Failed to add 'rc' to wheel group"
    echo "rc ALL=(ALL) NOPASSWD:ALL" | sudo tee /etc/sudoers.d/rc || error "Failed to add sudoers entry for 'rc'"
    sudo chown -R rc:rc /home/rc || error "Failed to set ownership for /home/rc"
    sudo chmod -R 700 /home/rc || error "Failed to set permissions for /home/rc"
    echo 'export PATH=$PATH:/usr/local/bin' | sudo tee -a /home/rc/.bashrc || error "Failed to update PATH for 'rc'"
}

# Set screen brightness
set_brightness() {
    log "Setting screen brightness"
    xrandr --output eDP1 --brightness 0.4 || error "Failed to set screen brightness"
}

# Unset FAKETIME and kill related processes
unset_faketime() {
    log "Unsetting FAKETIME and killing related processes"
    unset FAKETIME
    ps aux | grep faketime
    grep faketime ~/.bashrc
    grep faketime ~/.zshrc
    grep faketime ~/.profile
    grep faketime /etc/profile.d/*
    sudo pacman -R --noconfirm libfaketime || error "Failed to remove libfaketime"
    sudo killall faketime || true
}

# Unmount all mounted partitions
unmount_partitions() {
    log "Unmounting all mounted partitions..."
    umount -a -f || error "Failed to unmount partitions"
}

# Boot sector scanning and cleaning using Linux tools
clean_boot_sectors() {
    log "Scanning and cleaning boot sectors..."
    sudo fdisk -l || error "Failed to list block devices"
    sudo dd if=/dev/zero of=/dev/sda bs=512 count=1 conv=notrunc || error "Failed to clean boot sector"
    sudo sfdisk -R /dev/sda || error "Failed to reread partition table"
}

# Disable SSH completely
disable_ssh() {
    log "Disabling SSH..."
    sudo pacman -R --noconfirm openssh-server || error "Failed to remove openssh-server"
    sudo pacman -Rns --noconfirm openssh || error "Failed to remove openssh"
}

# Deactivate IPv6
deactivate_ipv6() {
    log "Deactivating IPv6..."
    echo "net.ipv6.conf.all.disable_ipv6 = 1" | sudo tee -a /etc/sysctl.conf || error "Failed to set IPv6 config"
    echo "net.ipv6.conf.default.disable_ipv6 = 1" | sudo tee -a /etc/sysctl.conf || error "Failed to set IPv6 config"
    echo "net.ipv6.conf.lo.disable_ipv6 = 1" | sudo tee -a /etc/sysctl.conf || error "Failed to set IPv6 config"
    sysctl -p || error "Failed to apply sysctl changes"
}

# Harden kernel
harden_kernel() {
    log "Hardening kernel..."
    cat << EOF | sudo tee /etc/sysctl.d/99-security.conf || error "Failed to create 99-security.conf"
kernel.kptr_restrict=2
kernel.dmesg_restrict=1
kernel.printk=3 3 3 3
kernel.unprivileged_bpf_disabled=1
net.core.bpf_jit_harden=2
kernel.core_pattern=|/bin/false
EOF
    sudo sysctl -p /etc/sysctl.d/99-security.conf || error "Failed to apply kernel hardening"
}

# Set robust DNS servers
set_dns() {
    log "Setting robust DNS servers..."
    echo "nameserver 1.1.1.1" | sudo tee /etc/resolv.conf || error "Failed to set DNS server"
    echo "nameserver 9.9.9.9" | sudo tee -a /etc/resolv.conf || error "Failed to set DNS server"
    sudo chattr +i /etc/resolv.conf || error "Failed to set immutable flag on /etc/resolv.conf"
}

# Remove and prevent faketime from reappearing
remove_faketime() {
    log "Removing faketime..."
    sudo pacman -R --noconfirm libfaketime || error "Failed to remove libfaketime"
    sudo killall faketime || true
    sudo find / -type f -name "*faketime*" -exec rm -f {} \; || error "Failed to remove faketime files"
    sudo sed -i '/faketime/d' ~/.bashrc ~/.zshrc ~/.profile /etc/profile.d/* || error "Failed to remove faketime entries from scripts"
}

# Kill all non-vital processes
kill_non_vital_processes() {
    log "Killing all non-vital processes..."
    sudo killall -9 -u root || error "Failed to kill root processes"
    sudo killall -9 -u your_username || error "Failed to kill user processes"
}

# Check for all connections
check_connections() {
    log "Checking for all connections..."
    sudo netstat -anp | grep ESTABLISHED || error "Failed to list connections"
}

# Set up firewall
setup_firewall() {
    log "Setting up firewall..."
    sudo iptables -F
    sudo iptables -P INPUT DROP
    sudo iptables -P FORWARD DROP
    sudo iptables -P OUTPUT ACCEPT
    sudo iptables -A INPUT -i lo -j ACCEPT
    sudo iptables -A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
    sudo iptables -A INPUT -p tcp --dport 80 -j ACCEPT
    sudo iptables-save || error "Failed to save iptables rules"
}

# Configure log rotation
configure_log_rotation() {
    log "Configuring log rotation..."
    cat << EOF | sudo tee /etc/logrotate.d/syslog
/var/log/*.log {
    daily
    missingok
    rotate 7
    compress
    delaycompress
    notifempty
    create 640 root root
    sharedscripts
    postrotate
        /usr/bin/killall -HUP syslog-ng || /bin/killall -HUP rsyslogd || :
    endscript
}
EOF
    sudo systemctl restart rsyslog || error "Failed to restart rsyslog"
}

# Install and configure AIDE
install_aide() {
    log "Installing and configuring AIDE..."
    sudo pacman -S --noconfirm aide || error "Failed to install AIDE"
    sudo aide --init || error "Failed to initialize AIDE"
    sudo cp /var/lib/aide/aide.db.new.gz /var/lib/aide/aide.db.gz || error "Failed to copy AIDE database"
    sudo systemctl enable aidecheck.timer || error "Failed to enable AIDE timer"
    sudo systemctl start aidecheck.timer || error "Failed to start AIDE timer"
}

# Install and configure rkhunter
install_rkhunter() {
    log "Installing and configuring rkhunter..."
    sudo pacman -S --noconfirm rkhunter || error "Failed to install rkhunter"
    sudo rkhunter --propupd || error "Failed to update rkhunter properties"
    sudo rkhunter --check || error "Failed to run rkhunter check"
}

# Install and configure ClamAV
install_clamav() {
    log "Installing and configuring ClamAV..."
    sudo pacman -S --noconfirm clamav clamav-daemon || error "Failed to install ClamAV"
    sudo freshclam || error "Failed to update ClamAV signatures"
    sudo systemctl enable clamav-daemon || error "Failed to enable ClamAV daemon"
    sudo systemctl start clamav-daemon || error "Failed to start ClamAV daemon"
}

# Verify all implementations
verify_implementations() {
    log "Verifying all implementations..."

    # Verify SSH is disabled
    if systemctl is-enabled sshd &> /dev/null; then
        error "SSH is still enabled."
    fi

    # Verify IPv6 is disabled
    if sysctl net.ipv6.conf.all.disable_ipv6 | grep -q "1"; then
        log "IPv6 is disabled."
    else
        error "IPv6 is not disabled."
    fi

    # Verify DNS settings
    if grep -q "nameserver 1.1.1.1" /etc/resolv.conf && grep -q "nameserver 9.9.9.9" /etc/resolv.conf; then
        log "DNS settings are correct."
    else
        error "DNS settings are incorrect."
    fi

    # Verify kernel hardening
    if grep -q "kernel.kptr_restrict=2" /etc/sysctl.d/99-security.conf && grep -q "kernel.dmesg_restrict=1" /etc/sysctl.d/99-security.conf; then
        log "Kernel hardening is applied."
    else
        error "Kernel hardening is not applied."
    fi

    # Verify user 'rc' creation
    if id rc &> /dev/null; then
        log "User 'rc' is created."
    else
        error "User 'rc' is not created."
    fi

    # Verify screen brightness
    if xrandr --output eDP1 --verbose | grep -q "Brightness: 0.4"; then
        log "Screen brightness is set correctly."
    else
        error "Screen brightness is not set correctly."
    fi

    # Verify FAKETIME removal
    if ! command -v faketime &> /dev/null; then
        log "FAKETIME is removed."
    else
        error "FAKETIME is not removed."
    fi

    # Verify connections
    if sudo netstat -anp | grep ESTABLISHED | grep -v "127.0.0.1" | grep -v "localhost"; then
        error "Non-localhost




#!/bin/bash
echo "Running Script to Download and Setup Security Packages and Configurations..."

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
    # Ensure script is run as root
    if [[ $EUID -ne 0 ]]; then
        error "This script must be run as root. Use sudo or run as root."
    fi

    # Check for Arch Linux
    if [[ ! -f /etc/arch-release ]]; then
        error "This script is designed for Arch Linux systems only."
    fi
}

# Download Packages and Dependencies
download_packages() {
    log "Downloading packages and dependencies..."
    local packages=("iptables" "rsyslog" "logrotate" "aide" "rkhunter" "clamav" "clamav-daemon" "sysctl" "pacman")
    local cache_dir="/root/offline_packages"

    sudo mkdir -p "$cache_dir"
    for package in "${packages[@]}"; do
        log "Downloading $package and its dependencies..."
        sudo pacman -Sw --downloadonly --cachedir="$cache_dir" "$package" || error "Failed to download $package"
    done
}

# Backup Configuration Files
backup_configs() {
    log "Backing up configuration files..."
    local config_dir="/root/offline_configs"
    sudo mkdir -p "$config_dir"

    # List of critical configuration files
    local config_files=(
        "/etc/iptables/iptables.rules"
        "/etc/rsyslog.conf"
        "/etc/logrotate.conf"
        "/etc/aide.conf"
        "/etc/rkhunter.conf"
        "/etc/clamav/clamd.conf"
        "/etc/clamav/freshclam.conf"
        "/etc/sysctl.conf"
        "/etc/pacman.conf"
    )

    for config in "${config_files[@]}"; do
        if [[ -f "$config" ]]; then
            sudo cp -a "$config" "$config_dir/$(basename "$config")" || error "Failed to backup $config"
            log "Backed up $config"
        else
            warn "$config not found, skipping backup."
        fi
    done
}

# Restore Packages and Configurations
restore_packages_and_configs() {
    log "Restoring packages and configurations..."
    local cache_dir="/root/offline_packages"
    local config_dir="/root/offline_configs"

    # Install packages using cached versions
    sudo pacman -U --usecacheonly --cachedir="$cache_dir" "$cache_dir"/*.pkg.tar.zst || error "Failed to install packages"

    # Restore configuration files
    for config in "$config_dir"/*; do
        sudo cp -a "$config" "/etc/$(basename "$config")" || error "Failed to restore $config"
        log "Restored $config"
    done
}

# Make Everything Immutable
make_immutable() {
    log "Making packages and configurations immutable..."
    local cache_dir="/root/offline_packages"
    local config_dir="/root/offline_configs"

    # Make package files immutable
    for pkg in "$cache_dir"/*.pkg.tar.zst; do
        sudo chattr +i "$pkg" || error "Failed to make $pkg immutable"
        log "Made $pkg immutable"
    done

    # Make configuration files immutable
    for config in "$config_dir"/*; do
        sudo chattr +i "$config" || error "Failed to make $config immutable"
        log "Made $config immutable"
    done
}

# Main Execution
main() {
    clear
    log "🔧 Downloading and Setting Up Security Packages and Configurations 🔧"
    
    preflight_check
    download_packages
    backup_configs
    restore_packages_and_configs
    make_immutable
    
    log "Script completed. All packages and configurations are now immutable."
}

# Execute Main Function
main

echo "Download and Setup Security Script completed."







#!/bin/bash
echo "Running Script to Download All Packages and Dependencies..."

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
    # Ensure script is run as root
    if [[ $EUID -ne 0 ]]; then
        error "This script must be run as root. Use sudo or run as root."
    fi

    # Check for Arch Linux
    if [[ ! -f /etc/arch-release ]]; then
        error "This script is designed for Arch Linux systems only."
    fi

    # Check for USB stick mount point
    if [[ -z "$USB_STICK" ]]; then
        error "USB_STICK environment variable must be set to the mount point of the USB stick."
    fi

    # Check if USB stick is mounted
    if [[ ! -d "$USB_STICK" ]]; then
        error "USB stick is not mounted at $USB_STICK."
    fi
}

# Download Packages and Dependencies
download_packages() {
    log "Downloading packages and dependencies..."
    local packages=("iptables" "rsyslog" "logrotate" "aide" "rkhunter" "clamav" "clamav-daemon" "sysctl" "pacman" "selinux" "apparmor" "ossec-hids" "snort")
    local cache_dir="$USB_STICK/offline_packages"

    sudo mkdir -p "$cache_dir"
    for package in "${packages[@]}"; do
        log "Downloading $package and its dependencies..."
        sudo pacman -Sw --downloadonly --cachedir="$cache_dir" "$package" || error "Failed to download $package"
    done
}

# Backup Configuration Files
backup_configs() {
    log "Backing up configuration files..."
    local config_dir="$USB_STICK/offline_configs"
    sudo mkdir -p "$config_dir"

    # List of critical configuration files
    local config_files=(
        "/etc/iptables/iptables.rules"
        "/etc/rsyslog.conf"
        "/etc/logrotate.conf"
        "/etc/aide.conf"
        "/etc/rkhunter.conf"
        "/etc/clamav/clamd.conf"
        "/etc/clamav/freshclam.conf"
        "/etc/sysctl.conf"
        "/etc/pacman.conf"
        "/etc/selinux/config"
        "/etc/apparmor.d"
        "/var/ossec/etc/ossec.conf"
        "/etc/snort/snort.conf"
    )

    for config in "${config_files[@]}"; do
        if [[ -f "$config" ]]; then
            sudo cp -a "$config" "$config_dir/$(basename "$config")" || error "Failed to backup $config"
            log "Backed up $config"
        elif [[ -d "$config" ]]; then
            sudo cp -a "$config" "$config_dir/$(basename "$config")" || error "Failed to backup $config"
            log "Backed up $config"
        else
            warn "$config not found, skipping backup."
        fi
    done
}

# Main Execution
main() {
    clear
    log "🔧 Downloading All Packages and Dependencies 🔧"
    
    preflight_check
    download_packages
    backup_configs
    
    log "Script completed. All packages and configurations are now stored on the USB stick."
}

# Execute Main Function
main

echo "Download and Setup Security Script completed."






#!/bin/bash
echo "Running Script to Install and Configure Packages..."

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
    # Ensure script is run as root
    if [[ $EUID -ne 0 ]]; then
        error "This script must be run as root. Use sudo or run as root."
    fi

    # Check for Arch Linux
    if [[ ! -f /etc/arch-release ]]; then
        error "This script is designed for Arch Linux systems only."
    fi

    # Check for USB stick mount point
    if [[ -z "$USB_STICK" ]]; then
        error "USB_STICK environment variable must be set to the mount point of the USB stick."
    fi

    # Check if USB stick is mounted
    if [[ ! -d "$USB_STICK" ]]; then
        error "USB stick is not mounted at $USB_STICK."
    fi
}

# Install Packages
install_packages() {
    log "Installing packages from USB stick..."
    local cache_dir="$USB_STICK/offline_packages"
    
    sudo pacman -U --usecacheonly --cachedir="$cache_dir" "$cache_dir"/*.pkg.tar.zst || error "Failed to install packages"
}

# Restore Configuration Files
restore_configs() {
    log "Restoring configuration files from USB stick..."
    local config_dir="$USB_STICK/offline_configs"

    for config in "$config_dir"/*; do
        sudo cp -a "$config" "/etc/$(basename "$config")" || error "Failed to restore $config"
        log "Restored $config"
    done
}

# Configure SELinux
configure_selinux() {
    log "Configuring SELinux..."
    sudo pacman -S --noconfirm selinux-policy || error "Failed to install SELinux policy"
    sudo fixfiles -F relabel || error "Failed to relabel files for SELinux"
    sudo systemctl enable selinux || error "Failed to enable SELinux"
    sudo systemctl start selinux || error "Failed to start SELinux"
}

# Configure AppArmor
configure_apparmor() {
    log "Configuring AppArmor..."
    sudo pacman -S --noconfirm apparmor || error "Failed to install AppArmor"
    sudo systemctl enable apparmor || error "Failed to enable AppArmor"
    sudo systemctl start apparmor || error "Failed to start AppArmor"
}

# Configure OSSEC
configure_ossec() {
    log "Configuring OSSEC..."
    sudo pacman -S --noconfirm ossec-hids || error "Failed to install OSSEC"
    sudo ossec-control enable || error "Failed to enable OSSEC"
    sudo ossec-control start || error "Failed to start OSSEC"
}

# Configure Snort
configure_snort() {
    log "Configuring Snort..."
    sudo pacman -S --noconfirm snort || error "Failed to install Snort"
    sudo cp /etc/snort/snort.conf.example /etc/snort/snort.conf || error "Failed to copy Snort configuration file"
    sudo systemctl enable snort || error "Failed to enable Snort"
    sudo systemctl start snort || error "Failed to start Snort"
}

# Make Everything Immutable
make_immutable() {
    log "Making packages and configurations immutable..."
    local cache_dir="$USB_STICK/offline_packages"
    local config_dir="$USB_STICK/offline_configs"

    # Make package files immutable
    for pkg in "$cache_dir"/*.pkg.tar.zst; do
        sudo chattr +i "$pkg" || error "Failed to make $pkg immutable"
        log "Made $pkg immutable"
    done

    # Make configuration files immutable
    for config in "$config_dir"/*; do
        sudo chattr +i "$config" || error "Failed to make $config immutable"
        log "Made $config immutable"
    done
}

# Verify Configurations
verify_configurations() {
    log "Verifying configurations..."

    # Verify SELinux
    if systemctl is-active --quiet selinux; then
        log "SELinux is active."
    else
        error "SELinux is not active."
    fi

    # Verify AppArmor
    if systemctl is-active --quiet apparmor; then
        log "AppArmor is active."
    else
        error "AppArmor is not active."
    fi

    # Verify OSSEC
    if systemctl is-active --quiet ossec; then
        log "OSSEC is active."
    else
        error "OSSEC is not active."
    fi

    # Verify Snort
    if systemctl is-active --quiet snort; then
        log "Snort is active."
    else
        error "Snort is not active."
    fi

    log "All configurations are verified and active."
}

# Main Execution
main() {
    clear
    log "🔧 Installing and Configuring Packages 🔧"
    
    preflight_check
    install_packages
    restore_configs
    configure_selinux
    configure_apparmor
    configure_ossec
    configure_snort
    make_immutable
    verify_configurations
    
    log "Script completed. All packages and configurations are now immutable and verified."
}

# Execute Main Function
main

echo "Install and Configure Security Script completed."







Key Considerations:

    Pacman Tampering: To prevent pacman.conf tampering, the key action is using chattr +i to make this file immutable. Bootkits often target pacman.conf to redirect repositories or add malicious sources.

    Pacman Integrity: After hardening and security checks, always verify pacman's integrity. You can compare checksums from a trusted source (e.g., official Arch mirrors) to detect any modifications.

    Rootkit Detection Tools: rkhunter and chkrootkit are essential, but keep them updated. You might want to set up a cron job or systemd timer to run these tools regularly.

    Firewall and Service Hardening: The firewall (ufw) ensures that only necessary ports are open. This is key in limiting attack vectors.

    Log Aggregation: Centralizing logs and making them immutable is crucial for visibility, especially when dealing with malware that may attempt to tamper with log files.

    Testing Resilience: After applying all the security measures, you want to verify that the system will continue working as expected, even if tampered with. Using hash checks and ensuring configuration files are immutable is key to confirming persistence.

    Use curl for Secure Downloads: You can use curl to download important tools or updates. For example:

    curl -fsSL https://example.com/somefile.sh -o /tmp/somefile.sh
    chmod +x /tmp/somefile.sh
    sudo /tmp/somefile.sh

General Improvements:

    You might want to periodically back up the configuration and recheck the files. After rebooting into system rescue mode, it’s always good to re-apply these scripts if anything was tampered with.
    Since you're working in an environment where you have limited storage and resources (16GB RAM and booting from a USB stick), consider minimizing the number of tools you install and centralizing them to use as little space as possible.
    Use systemd timers to automate checks for integrity and malware scans.
    Consider encrypting sensitive files (e.g., /etc/passwd) with gpg or using filesystem encryption like LUKS for better protection.

Let me know if you need further tweaks or additions!
You said:
can you give me a script to download all the pckges here and dependencies to store offline? all tempered including ufw - absolutely all configuration files too - to manipulate results of everything-  so we need new ones - plus make them all immutable - clamav, rk, ch, kernel, pacman you name it!!!
ChatGPT said:
ChatGPT

Sure, here's a script that downloads all necessary packages, their dependencies, and configuration files for offline use. Additionally, it will make all files immutable to prevent tampering. The script is designed for Arch Linux, and it includes packages like ufw, clamav, rkhunter, chkrootkit, the kernel, and pacman, along with their configuration files.






#!/bin/bash
echo "Running Script to Install and Configure Packages..."

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
    # Ensure script is run as root
    if [[ $EUID -ne 0 ]]; then
        error "This script must be run as root. Use sudo or run as root."
    fi

    # Check for Arch Linux
    if [[ ! -f /etc/arch-release ]]; then
        error "This script is designed for Arch Linux systems only."
    fi

    # Check for USB stick mount point
    if [[ -z "$USB_STICK" ]]; then
        error "USB_STICK environment variable must be set to the mount point of the USB stick."
    fi

    # Check if USB stick is mounted
    if [[ ! -d "$USB_STICK" ]]; then
        error "USB stick is not mounted at $USB_STICK."
    fi
}

# Install Packages
install_packages() {
    log "Installing packages from USB stick..."
    local cache_dir="$USB_STICK/offline_packages"
    
    sudo pacman -U --usecacheonly --cachedir="$cache_dir" "$cache_dir"/*.pkg.tar.zst || error "Failed to install packages"
}

# Restore Configuration Files
restore_configs() {
    log "Restoring configuration files from USB stick..."
    local config_dir="$USB_STICK/offline_configs"

    for config in "$config_dir"/*; do
        sudo cp -a "$config" "/etc/$(basename "$config")" || error "Failed to restore $config"
        log "Restored $config"
    done
}

# Configure SELinux
configure_selinux() {
    log "Configuring SELinux..."
    sudo pacman -S --noconfirm selinux-policy || error "Failed to install SELinux policy"
    sudo fixfiles -F relabel || error "Failed to relabel files for SELinux"
    sudo systemctl enable selinux || error "Failed to enable SELinux"
    sudo systemctl start selinux || error "Failed to start SELinux"
}

# Configure AppArmor
configure_apparmor() {
    log "Configuring AppArmor..."
    sudo pacman -S --noconfirm apparmor || error "Failed to install AppArmor"
    sudo systemctl enable apparmor || error "Failed to enable AppArmor"
    sudo systemctl start apparmor || error "Failed to start AppArmor"
}

# Configure OSSEC
configure_ossec() {
    log "Configuring OSSEC..."
    sudo pacman -S --noconfirm ossec-hids || error "Failed to install OSSEC"
    sudo ossec-control enable || error "Failed to enable OSSEC"
    sudo ossec-control start || error "Failed to start OSSEC"
}

# Configure Snort
configure_snort() {
    log "Configuring Snort..."
    sudo pacman -S --noconfirm snort || error "Failed to install Snort"
    sudo cp /etc/snort/snort.conf.example /etc/snort/snort.conf || error "Failed to copy Snort configuration file"
    sudo systemctl enable snort || error "Failed to enable Snort"
    sudo systemctl start snort || error "Failed to start Snort"
}

# Make Everything Immutable
make_immutable() {
    log "Making packages and configurations immutable..."
    local cache_dir="$USB_STICK/offline_packages"
    local config_dir="$USB_STICK/offline_configs"

    # Make package files immutable
    for pkg in "$cache_dir"/*.pkg.tar.zst; do
        sudo chattr +i "$pkg" || error "Failed to make $pkg immutable"
        log "Made $pkg immutable"
    done

    # Make configuration files immutable
    for config in "$config_dir"/*; do
        sudo chattr +i "$config" || error "Failed to make $config immutable"
        log "Made $config immutable"
    done
}

# Verify Configurations
verify_configurations() {
    log "Verifying configurations..."

    # Verify SELinux
    if systemctl is-active --quiet selinux; then
        log "SELinux is active."
    else
        error "SELinux is not active."
    fi

    # Verify AppArmor
    if systemctl is-active --quiet apparmor; then
        log "AppArmor is active."
    else
        error "AppArmor is not active."
    fi

    # Verify OSSEC
    if systemctl is-active --quiet ossec; then
        log "OSSEC is active."
    else
        error "OSSEC is not active."
    fi

    # Verify Snort
    if systemctl is-active --quiet snort; then
        log "Snort is active."
    else
        error "Snort is not active."
    fi

    log "All configurations are verified and active."
}

# Main Execution
main() {
    clear
    log "🔧 Installing and Configuring Packages 🔧"
    
    preflight_check
    install_packages
    restore_configs
    configure_selinux
    configure_apparmor
    configure_ossec
    configure_snort
    make_immutable
    verify_configurations
    
    log "Script completed. All packages and configurations are now immutable and verified."
}

# Execute Main Function
main

echo "Install and Configure Security Script completed."



#!/bin/bash

echo "Starting package download and offline storage for Arch Linux..."

# Define the directory for offline storage
OFFLINE_DIR="/mnt/offline-packages"
mkdir -p $OFFLINE_DIR

# Update system and sync package databases
echo "Syncing package databases..."
sudo pacman -Sy

# List of critical packages to download, including SELinux, OSSEC, Snort, and others
PACKAGES=(
    "ufw"
    "clamav"
    "rkhunter"
    "chkrootkit"
    "linux"      # Kernel package
    "pacman"
    "iptables"
    "firewalld"
    "audit"
    "selinux"
    "ossec-hids"
    "snort"
    "apparmor"
)

# Download the packages and their dependencies for offline use
echo "Downloading packages and dependencies..."
for PACKAGE in "${PACKAGES[@]}"; do
    sudo pacman -Sw --noconfirm --needed --cachedir $OFFLINE_DIR $PACKAGE
done

# Ensure the downloaded packages are stored for later use
echo "All packages have been downloaded to $OFFLINE_DIR."

# Backup critical configuration files
echo "Backing up critical configuration files..."
CONFIG_DIRS=(
    "/etc/pacman.conf"
    "/etc/pacman.d"
    "/etc/ufw"
    "/etc/clamav"
    "/etc/rkhunter"
    "/etc/chkrootkit"
    "/etc/sysctl.d"
    "/etc/systemd"
    "/etc/iptables"
    "/etc/selinux"
    "/etc/ossec"
    "/etc/snort"
    "/etc/apparmor"
)

# Create backup directory for config files
CONFIG_BACKUP_DIR="/mnt/config-backups"
mkdir -p $CONFIG_BACKUP_DIR

# Copy configuration files to the backup directory
for CONFIG in "${CONFIG_DIRS[@]}"; do
    if [ -e "$CONFIG" ]; then
        sudo cp -r $CONFIG $CONFIG_BACKUP_DIR/
        echo "Backed up: $CONFIG"
    else
        echo "Skipping (not found): $CONFIG"
    fi
done

# Make downloaded packages and config files immutable
echo "Making downloaded packages and config files immutable..."

# Make the entire offline package directory immutable
sudo chattr +i -R $OFFLINE_DIR

# Make configuration backup directory immutable
sudo chattr +i -R $CONFIG_BACKUP_DIR

# Make key configuration files immutable
for CONFIG in "${CONFIG_DIRS[@]}"; do
    if [ -e "$CONFIG" ]; then
        sudo chattr +i $CONFIG
        echo "Made immutable: $CONFIG"
    else
        echo "Skipping immutability (not found): $CONFIG"
    fi
done

# Kernel and important system directories
sudo chattr +i /boot
sudo chattr +i /lib/modules
sudo chattr +i /etc/systemd

echo "Download and backup complete. All files are now immutable."

# To confirm immutability, you can check attributes with `lsattr`:
echo "Verifying immutability of important files..."
lsattr /etc/pacman.conf /etc/ufw /etc/clamav /etc/rkhunter /etc/chkrootkit /etc/sysctl.d /etc/iptables





#!/bin/bash

# Set up directories
DOWNLOAD_DIR="/path/to/download/directory"
CONF_BACKUP_DIR="/path/to/config/backup/directory"
mkdir -p "$DOWNLOAD_DIR" "$CONF_BACKUP_DIR"

# List of packages to download
PACKAGES=(
    "ufw"
    "clamav"
    "rkhunter"
    "linux"
    "linux-headers"
    "pacman"
    "selinux-utils"
    "ossec-hids"
    "snort"
    # Add more packages as needed
)

# Download packages and dependencies
for pkg in "${PACKAGES[@]}"; do
    pacman -Syw --cachedir "$DOWNLOAD_DIR" --noconfirm "$pkg"
done

# Backup configuration files
CONFIG_FILES=(
    "/etc/ufw"
    "/etc/clamav"
    "/etc/rkhunter.conf"
    "/etc/pacman.conf"
    "/etc/pacman.d/mirrorlist"
    "/etc/selinux"
    "/etc/ossec-hids"
    "/etc/snort"
    # Add more config files/directories as needed
)

for conf in "${CONFIG_FILES[@]}"; do
    cp -r "$conf" "$CONF_BACKUP_DIR"
done

# Make downloaded packages and config backups immutable
chattr +i "$DOWNLOAD_DIR"/*
chattr -R +i "$CONF_BACKUP_DIR"

# Create a custom repository
repo-add "$DOWNLOAD_DIR/custom.db.tar.gz" "$DOWNLOAD_DIR"/*.pkg.tar.zst

# Download pacman keys
pacman-key --init
pacman-key --populate archlinux

# Backup pacman keyring
cp -r /etc/pacman.d/gnupg "$CONF_BACKUP_DIR/pacman_keyring"

# Download AUR packages
AUR_PACKAGES=(
    "yay"
    # Add more AUR packages as needed
)

for aur_pkg in "${AUR_PACKAGES[@]}"; do
    git clone "https://aur.archlinux.org/${aur_pkg}.git" "$DOWNLOAD_DIR/$aur_pkg"
    cd "$DOWNLOAD_DIR/$aur_pkg"
    makepkg -s --noconfirm
    cd -
done

echo "Packages and configurations downloaded and made immutable."
echo "Custom repository created at $DOWNLOAD_DIR/custom.db.tar.gz"
echo "Remember to update your pacman.conf to use this local repository."

# Create a script to secure the USB stick
cat << EOF > secure_usb.sh
#!/bin/bash
USB_MOUNT="/mnt/secure_usb"
mkdir -p "\$USB_MOUNT"
mount /dev/sdX1 "\$USB_MOUNT"  # Replace sdX1 with your USB device
chmod 700 "\$USB_MOUNT"
chown root:root "\$USB_MOUNT"
EOF

chmod +x secure_usb.sh

# Create a script to install and configure downloaded packages
cat << EOF > install_configure.sh
#!/bin/bash
# Add your local repository to pacman.conf
echo "[custom]
SigLevel = Optional TrustAll
Server = file:///path/to/download/directory" >> /etc/pacman.conf

# Sync and upgrade
pacman -Syu

# Install packages
pacman -S ufw clamav rkhunter selinux-utils ossec-hids snort

# Configure UFW
ufw default deny incoming
ufw default allow outgoing
ufw enable

# Configure ClamAV
freshclam
systemctl enable clamav-daemon
systemctl start clamav-daemon

# Configure OSSEC
/var/ossec/bin/ossec-control start

# Configure Snort
snort -T -c /etc/snort/snort.conf

# Enable SELinux
sed -i 's/SELINUX=disabled/SELINUX=enforcing/' /etc/selinux/config

# Verify installations
ufw status
clamscan --version
/var/ossec/bin/ossec-control status
snort --version
sestatus

EOF

chmod +x install_configure.sh

echo "Scripts created: secure_usb.sh and install_configure.sh"





#!/bin/bash
echo "Running Package Download and Configuration Hardening Script..."

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
    # Ensure script is run as root
    if [[ $EUID -ne 0 ]]; then
        error "This script must be run as root. Use sudo or run as root."
    fi

    # Check for Arch Linux
    if [[ ! -f /etc/arch-release ]]; then
        error "This script is designed for Arch Linux systems only."
    fi

    # Check network connectivity
    if ! ping -c 4 archlinux.org > /dev/null 2>&1; then
        error "No network connectivity. Cannot proceed."
    fi

    # Check architecture
    if [[ $(uname -m) != "x86_64" ]]; then
        error "This script is designed for x86_64 architecture only."
    fi
}

# Download Packages and Dependencies
download_packages() {
    log "Downloading Packages and Dependencies..."
    sudo pacman -Syu --noconfirm

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

    mkdir -p /var/cache/pacman/pkg/offline
    for package in "${PACKAGES[@]}"; do
        sudo pacman -Sw --noconfirm "$package"
        sudo pacman -S --cachedir=/var/cache/pacman/pkg/offline --noconfirm "$package"
    done

    log "Packages and dependencies downloaded to /var/cache/pacman/pkg/offline"
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

    mkdir -p /var/cache/pacman/pkg/offline/configs
    for dir in "${CONFIG_DIRS[@]}"; do
        if [[ -d "$dir" ]]; then
            sudo cp -r "$dir" /var/cache/pacman/pkg/offline/configs/
        elif [[ -f "$dir" ]]; then
            sudo cp "$dir" /var/cache/pacman/pkg/offline/configs/
        fi
    done

    log "Configuration files backed up to /var/cache/pacman/pkg/offline/configs"
}

# Make Configuration Files Immutable
make_immutable() {
    log "Making Configuration Files Immutable..."
    sudo chattr +i -R /var/cache/pacman/pkg/offline/configs
    log "Configuration files are now immutable."
}

# Main Execution
main() {
    clear
    log "🔧 Package Download and Configuration Hardening Script 🔧"

    preflight_check
    download_packages
    backup_configs
    make_immutable

    log "Script Completed. Packages and configurations are ready for offline use."
}

# Execute Main Function
main

echo "Package Download and Configuration Hardening Script completed."







#!/bin/bash
echo "Running Secure Folder and USB Stick Script..."

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
    # Ensure script is run as root
    if [[ $EUID -ne 0 ]]; then
        error "This script must be run as root. Use sudo or run as root."
    fi

    # Check for Arch Linux
    if [[ ! -f /etc/arch-release ]]; then
        error "This script is designed for Arch Linux systems only."
    fi

    # Check network connectivity
    if ! ping -c 4 archlinux.org > /dev/null 2>&1; then
        error "No network connectivity. Cannot proceed."
    fi

    # Check architecture
    if [[ $(uname -m) != "x86_64" ]]; then
        error "This script is designed for x86_64 architecture only."
    fi
}

# Secure Folder
secure_folder() {
    log "Securing Folder..."
    sudo mkdir -p /secure_folder
    sudo chmod 700 /secure_folder
    sudo chown root:root /secure_folder
    sudo chattr +i /secure_folder
    log "Folder secured at /secure_folder"
}

# Secure USB Stick
secure_usb_stick() {
    log "Securing USB Stick..."
    USB_DEVICE=$(lsblk -o NAME,TYPE | grep 'disk' | tail -n 1 | awk '{print $1}')
    if [[ -z "$USB_DEVICE" ]]; then
        error "No USB stick found."
    fi

    sudo mkfs.ext4 -L SECURE_USB /dev/$USB_DEVICE
    sudo mkdir -p /mnt/secure_usb
    sudo mount -o rw /dev/$USB_DEVICE /mnt/secure_usb
    sudo cp -r /var/cache/pacman/pkg/offline /mnt/secure_usb/
    sudo umount /mnt/secure_usb
    log "USB stick secured and files copied."
}

# Main Execution
main() {
    clear
    log "🔧 Secure Folder and USB Stick Script 🔧"

    preflight_check
    secure_folder
    secure_usb_stick

    log "Script Completed. Folder and USB stick are secured."
}

# Execute Main Function
main

echo "Secure Folder and USB Stick Script completed."




#!/bin/bash

# Offline Package and Configuration Backup Script (Arch Linux - Enhanced)

# ... (Color codes, logging functions, preflight_check - same as before)

# Directory for offline storage (on the USB stick)
OFFLINE_DIR="/mnt/usb_stick/secure_backup"  # Change to your USB stick mount point and desired folder
mkdir -p "$OFFLINE_DIR"

# Package download and dependency resolution (Improved)
download_package() {
    pkg_name="$1"
    log "Downloading $pkg_name and dependencies..."

    # Download to a temporary directory first
    temp_dir=$(mktemp -d)

    # Download package and dependencies (recursively)
    pacman -Sw --noconfirm "$pkg_name" --cachedir "$temp_dir/pkg"

    # Copy the package to the offline directory
    find "$temp_dir/pkg" -name "$pkg_name-*.pkg.tar.xz" -exec cp {} "$OFFLINE_DIR/pkg/" \;

    # Clean up the temporary directory
    rm -rf "$temp_dir"
}


# Function to backup a configuration file and make it immutable
backup_config() {
    config_file="$1"
    log "Backing up $config_file..."

    # Create the necessary directory structure in the backup location
    mkdir -p "$(dirname "$OFFLINE_DIR/etc/$config_file")"

    # Copy the configuration file
    cp "$config_file" "$OFFLINE_DIR/etc/$config_file"

    # Make the backup immutable (after it is backed up)
    chattr +i "$OFFLINE_DIR/etc/$config_file"
}

# Function to backup a directory and make its files immutable
backup_dir() {
    config_dir="$1"
    log "Backing up $config_dir..."

    # Create the necessary directory structure in the backup location
    mkdir -p "$OFFLINE_DIR/$config_dir"

    # Copy the directory recursively
    cp -r "$config_dir" "$OFFLINE_DIR/$config_dir"

    # Make all files within the directory immutable
    find "$OFFLINE_DIR/$config_dir" -type f -exec chattr +i {} \;
    find "$OFFLINE_DIR/$config_dir" -type d -exec chattr +i {} \; # Make directories immutable too
}

# Packages to download (Comprehensive list)
packages=(
    "ufw"
    "clamav"
    "rkhunter"
    "chkrootkit"
    "pacman"
    "coreutils"
    "systemd"
    "linux"  # Kernel
    "selinux-policy" # SELinux
    "ossec-hids"    # OSSEC
    "snort"        # Snort
    "iptables" # if you choose iptables
    "nftables" # if you choose nftables
    # ... Add absolutely all other packages you need
)

# Configuration files to backup (Comprehensive list)
config_files=(
    "/etc/resolv.conf"
    "/etc/hosts"
    "/etc/fstab"
    "/etc/pacman.conf"
    "/etc/sysctl.d/99-security.conf"
    "/etc/nftables.conf" # Or /etc/iptables/* if you use iptables
    "/etc/selinux/config"  # SELinux config
    "/etc/ossec-hids/*"   # OSSEC config - be careful with this, might contain sensitive data
    "/etc/snort/*"       # Snort config
    "/etc/clamav/*"
    "/etc/rkhunter.conf.d/*"
    "/etc/chkrootkit.conf"
    "/etc/systemd/*"
    "/etc/default/*"
    "/etc/security/*"
    # ... Add absolutely all other config files
)

# Directories to backup (Comprehensive list)
config_dirs=(
  "/etc/clamav"
  "/etc/rkhunter.conf.d" # Or wherever rkhunter config is
  "/etc/chkrootkit.conf" # Or wherever chkrootkit config is
  "/etc/systemd"
  "/etc/default"
  "/etc/security"
  "/etc/selinux" # SELinux
  "/var/lib/ossec" # OSSEC data (might be very large)
  "/etc/snort" # Snort
  # ... Add absolutely all other config directories
)

main() {
    clear
    log "Starting Offline Package and Configuration Backup..."

    preflight_check # Check if root and Arch

    # Create pkg directory
    mkdir -p "$OFFLINE_DIR/pkg"

    # Download packages
    for pkg in "${packages[@]}"; do
        download_package "$pkg"
    done

    # Backup configuration files
    for config in "${config_files[@]}"; do
        backup_config "$config"
    done

    # Backup configuration directories
    for dir in "${config_dirs[@]}"; do
      backup_dir "$dir"
    done

    log "Offline Backup Completed to $OFFLINE_DIR"

    # Make the entire backup directory and its contents read-only
    chattr +i "$OFFLINE_DIR"
    find "$OFFLINE_DIR" -type f -exec chattr +i {} \;
    find "$OFFLINE_DIR" -type d -exec chattr +i {} \;

    warn "Backup directory and files are now immutable. Changes will require unsetting the immutable attribute (chattr -i)."
}

main



        
