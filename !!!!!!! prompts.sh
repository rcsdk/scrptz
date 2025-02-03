code in bash to help me harden my envinroment - im on ram - 16g - booting on system rescue - 4, 5 times a day   booting from a strick to try and work as a designer.
i want to develop 04 scripts. 
01 - preparation offline
02 - download and check all around for breaches - hidden services, hidden connections, opened ports (close all minus http), hidden ssh, kernel, change/refresh literally all confs (and similar) once he tempers all of them including clamav, rk chk etc etc
03 - download and setup all security - firewall, etc etc etc - centralizing all logs - in a single place - minimum files as possible - condensing and creating files based on interpretation of really matters (I always feel there is 90% garbage)
04 - check all the above again - to be sure they are working and will continue to work once malware coming from vram - can temper whatever he wants - creating a lot of confusion - eg. didnt we fix DNS already?? (and the same for EVERYTHING - so its very confusing...)

now check my original one and combine both....


This is the first - not yet finished. please give your opinion on the overall and improvements suggestions

now check my original one and combine both....
 and add At the end of this script a system that check again from the beginning if all the implementations are working as expected. If not, script it again. Lock it, make it immutable (speaking conceptuaLLY) - get my point? then we get to script 02 - downloads - we are good with least interference possible.


its arch - not apt get - and better with curl bootlit always tempering pacman

can you give me a script to download all the pckges here and dependencies to store offline? all tempered including ufw - absolutely all configuration files too - to manipulate results of everything-  so we need new ones - plus make them all immutable - clamav, rk, ch, kernel, pacman you name it!!!

lets also add SELinux + OSSEC + Snort (let me know if i need to create profiles for them0 also download them so I have literally everything on the stick - wheN I download he tempers - big vector there - lets download all these AND ALL on ther other scripts  - secure folder, then secure folder on usb stick - need scripts for these - but separate. the on these we need to install them befor usign and configurinig - and again- qt the end - checking f it s working - 0
Configuring SELinux or AppArmor to provide an additional layer of security.
Installing and configuring a host-based intrusion detection system (HIDS) such as OSSEC to monitor for suspicious activity.





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
}

# Comprehensive Pacman Repair Procedure
pacman_repair() {
    # Step 1: Remove Pacman Lock Files
    log "Removing Pacman Lock Files"
    rm -f /var/lib/pacman/db.lck

    # Step 2: Clear Pacman Cache with Confirmation
    warn "Pacman Cache Cleanup"
    read -p "Do you want to remove ALL files from cache? [y/N] " -n 1 -r
    echo    # move to a new line
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
        
        curl -L "$mirror/core/os/x86_64/core.db" -o /var/lib/pacman/sync/core.db
        curl -L "$mirror/extra/os/x86_64/extra.db" -o /var/lib/pacman/sync/extra.db
        curl -L "$mirror/community/os/x86_64/community.db" -o /var/lib/pacman/sync/community.db
    done
    
    # Force database sync
    pacman -Syy
}

# Fix Inodes
fix_inodes() {
    local inode_list=$(dumpe2fs -h /dev/sda1 | grep -oP '(?<=Inode count:)\s*\K\d+')

    for inode in $(seq 1 $inode_list); do
        # Check if inode exists
        if ! sudo debugfs -R "stat <$inode>" /dev/sda1 > /dev/null 2>&1; then
            warn "Inode $inode does not exist. Skipping..."
            continue
        fi

        # Check for garbage in inode
        sudo debugfs -R "dump <$inode> /tmp/inode_dump_$inode" /dev/sda1 > /dev/null 2>&1
        if [[ $(file /tmp/inode_dump_$inode) =~ garbage ]]; then
            read -p "Inode $inode seems to contain garbage. Clear? [y/N] " -n 1 -r
            echo    # move to a new line
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                sudo debugfs -R "rm <$inode>" /dev/sda1
                log "Inode $inode cleared."
            else
                log "Inode $inode not cleared."
            fi
        fi
        rm -f /tmp/inode_dump_$inode

        # Check for specific flags
        flags=$(sudo debugfs -R "stat <$inode>" /dev/sda1 | grep "Flags:")
        if [[ $flags =~ "casefold" || $flags =~ "ea_inode" ]]; then
            read -p "Inode $inode has incorrect flags set. Clear flags? [y/N] " -n 1 -r
            echo    # move to a new line
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                sudo debugfs -R "set_inode_flag <$inode> -casefold -ea_inode" /dev/sda1
                log "Inode $inode flags cleared."
            else
                log "Inode $inode flags not cleared."
            fi
        fi

        # Check for inline data and extent flags
        if [[ $flags =~ "inline" || $flags =~ "extent" ]]; then
            read -p "Inode $inode has inline data and extent flags set but i_block contains junk. Clear inode? [y/N] " -n 1 -r
            echo    # move to a new line
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                sudo debugfs -R "rm <$inode>" /dev/sda1
                log "Inode $inode cleared."
            else
                log "Inode $inode not cleared."
            fi
        fi

        # Check for zero dtime
        dtime=$(sudo debugfs -R "stat <$inode>" /dev/sda1 | grep "dtime" | awk '{print $2}')
        if [[ "$dtime" -eq 0 ]]; then
            read -p "Deleted inode $inode has zero dtime. Fix? [y/N] " -n 1 -r
            echo    # move to a new line
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                sudo debugfs -R "set_inode_field <$inode> dtime $(date +%s)" /dev/sda1
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
    sudo useradd -m rc
    echo "rc:0000" | sudo chpasswd
    sudo usermod -aG wheel rc
    echo "rc ALL=(ALL) NOPASSWD:ALL" | sudo tee /etc/sudoers.d/rc
    sudo chown -R rc:rc /home/rc
    sudo chmod -R 700 /home/rc
    echo 'export PATH=$PATH:/usr/local/bin' | sudo tee -a /home/rc/.bashrc
}

# Set screen brightness
set_brightness() {
    log "Setting screen brightness"
    xrandr --output eDP1 --brightness 0.4
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
    sudo pacman -R --noconfirm libfaketime
    sudo killall faketime
}

# Unmount all mounted partitions
unmount_partitions() {
    log "Unmounting all mounted partitions..."
    umount -a -f
}

# Boot sector scanning and cleaning using Linux tools
clean_boot_sectors() {
    log "Scanning and cleaning boot sectors..."
    sudo fdisk -l
    sudo dd if=/dev/zero of=/dev/sda bs=512 count=1 conv=notrunc
    sudo sfdisk -R /dev/sda
}

# Disable SSH completely
disable_ssh() {
    log "Disabling SSH..."
    sudo pacman -R --noconfirm openssh-server
    sudo pacman -Rns --noconfirm openssh
}

# Deactivate IPv6
deactivate_ipv6() {
    log "Deactivating IPv6..."
    echo "net.ipv6.conf.all.disable_ipv6 = 1" | sudo tee -a /etc/sysctl.conf
    echo "net.ipv6.conf.default.disable_ipv6 = 1" | sudo tee -a /etc/sysctl.conf
    echo "net.ipv6.conf.lo.disable_ipv6 = 1" | sudo tee -a /etc/sysctl.conf
    sysctl -p
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

# Remove and prevent faketime from reappearing
remove_faketime() {
    log "Removing faketime..."
    sudo pacman -R --noconfirm libfaketime
    sudo killall faketime
    sudo find / -type f -name "*faketime*" -exec rm -f {} \;
    sudo sed -i '/faketime/d' ~/.bashrc ~/.zshrc ~/.profile /etc/profile.d/*
}

# Kill all non-vital processes
kill_non_vital_processes() {
    log "Killing all non-vital processes..."
    sudo killall -9 -u root
    sudo killall -9 -u your_username
}

# Check for all connections
check_connections() {
    log "Checking for all connections..."
    sudo netstat -anp | grep ESTABLISHED
}

# Main Execution
main() {
    clear
    log "🔧 Comprehensive Pacman Repair and System Recovery 🔧"
    
    preflight_check
    create_user
    set_brightness
    unset_faketime
    unmount_partitions
    clean_boot_sectors
    pacman_repair
    filesystem_recovery
    network_recovery
    fix_inodes
    disable_ssh
    deactivate_ipv6
    close_ports
    harden_kernel
    set_dns
    remove_faketime
    kill_non_vital_processes
    check_connections
    
    log "Repair Process Completed. System should now be stable."
}

# Execute Main Function
main

echo "Initial Bootkit Removal and System Hardening Script completed."


















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

    # Check available disk space
    if [[ $(df / --output=avail | tail -n 1) -lt 5242880 ]]; then
        error "Not enough disk space available. Cannot proceed."
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
echo "Running Breach Detection Script..."

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

# Check for Hidden Services
check_hidden_services() {
    log "Checking for Hidden Services..."
    sudo netstat -tulnp | grep LISTEN
    sudo lsof -i -P -n | grep LISTEN
}

# Check for Open Ports
check_open_ports() {
    log "Checking for Open Ports..."
    sudo nmap -sT -O localhost
}

# Check for Hidden SSH
check_hidden_ssh() {
    log "Checking for Hidden SSH Services..."
    sudo netstat -tulnp | grep ssh
}

# Check for Kernel Integrity
check_kernel_integrity() {
    log "Checking for Kernel Integrity..."
    sudo dmesg | grep -i integrity
}

# Check for Configuration Tampering
check_config_tampering() {
    log "Checking for Configuration Tampering..."
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

    for dir in "${CONFIG_DIRS[@]}"; do
        sudo sha256sum "$dir"
    done
}

# Check for Rootkits
check_rootkits() {
    log "Checking for Rootkits..."
    sudo rkhunter --check
    sudo chkrootkit
}

# Check for Malware
check_malware() {
    log "Checking for Malware..."
    sudo freshclam
    sudo clamscan -r / --bell -i
}

# Check for Unauthorized Changes
check_unauthorized_changes() {
    log "Checking for Unauthorized Changes..."
    sudo aide --check
}

# Check for Log Tampering
check_log_tampering() {
    log "Checking for Log Tampering..."
    sudo sha256sum /var/log/*
}

# Check for Network Breaches
check_network_breaches() {
    log "Checking for Network Breaches..."
    sudo snort -A console -q -c /etc/snort/snort.conf
}

# Main Execution
main() {
    clear
    log "🔧 Breach Detection Script 🔧"

    preflight_check
    check_hidden_services
    check_open_ports
    check_hidden_ssh
    check_kernel_integrity
    check_config_tampering
    check_rootkits
    check_malware
    check_unauthorized_changes
    check_log_tampering
    check_network_breaches

    log "Script Completed. Breach detection checks are done."
}

# Execute Main Function
main

echo "Breach Detection Script completed."






#!/bin/bash
echo "Running Security Setup Script..."

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

# Install and Configure Firewall
configure_firewall() {
    log "Configuring Firewall..."
    sudo pacman -S --noconfirm ufw
    sudo ufw default deny incoming
    sudo ufw default allow outgoing
    sudo ufw allow ssh
    sudo ufw allow 80/tcp
    sudo ufw enable
    sudo ufw status
}

# Install and Configure ClamAV
configure_clamav() {
    log "Configuring ClamAV..."
    sudo pacman -S --noconfirm clamav
    sudo freshclam
    sudo systemctl enable clamav-daemon
    sudo systemctl start clamav-daemon
}

# Install and Configure rkhunter
configure_rkhunter() {
    log "Configuring rkhunter..."
    sudo pacman -S --noconfirm rkhunter
    sudo rkhunter --propupd
    sudo rkhunter --check
}

# Install and Configure chkrootkit
configure_chkrootkit() {
    log "Configuring chkrootkit..."
    sudo pacman -S --noconfirm chkrootkit
    sudo chkrootkit
}

# Install and Configure Fail2Ban
configure_fail2ban() {
    log "Configuring Fail2Ban..."
    sudo pacman -S --noconfirm fail2ban
    sudo systemctl enable fail2ban
    sudo systemctl start fail2ban
    sudo cp /etc/fail2ban/jail.conf /etc/fail2ban/jail.local
    sudo sed -i 's/^#\?\(bantime\s*=\s*\).*\$/\1900/' /etc/fail2ban/jail.local
    sudo sed -i 's/^#\?\(findtime\s*=\s*\).*\$/\1600/' /etc/fail2ban/jail.local
    sudo sed -i 's/^#\?\(maxretry\s*=\s*\).*\$/\13/' /etc/fail2ban/jail.local
    sudo systemctl restart fail2ban
}

# Install and Configure AIDE
configure_aide() {
    log "Configuring AIDE..."
    sudo pacman -S --noconfirm aide
    sudo aideinit
    sudo aide --check
}

# Install and Configure Cronie
configure_cronie() {
    log "Configuring Cronie..."
    sudo pacman -S --noconfirm cronie
    sudo systemctl enable cronie
    sudo systemctl start cronie
}

# Install and Configure SELinux
configure_selinux() {
    log "Configuring SELinux..."
    sudo pacman -S --noconfirm selinux
    sudo selinux-activate
    sudo sestatus
}

# Install and Configure OSSEC
configure_ossec() {
    log "Configuring OSSEC..."
    sudo pacman -S --noconfirm ossec-hids
    sudo systemctl enable ossec
    sudo systemctl start ossec
}

# Install and Configure Snort
configure_snort() {
    log "Configuring Snort..."
    sudo pacman -S --noconfirm snort
    sudo systemctl enable snort
    sudo systemctl start snort
}

# Main Execution
main() {
    clear
    log "🔧 Security Setup Script 🔧"

    preflight_check
    configure_firewall
    configure_clamav
    configure_rkhunter
    configure_chkrootkit
    configure_fail2ban
    configure_aide
    configure_cronie
    configure_selinux
    configure_ossec
    configure_snort

    log "Script Completed. Security setup is done."
}

# Execute Main Function
main

echo "Security Setup Script completed."







#!/bin/bash
echo "Running Final Check Script..."

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

# Re-check for Hidden Services
recheck_hidden_services() {
    log "Re-checking for Hidden Services..."
    sudo netstat -tulnp | grep LISTEN
    sudo lsof -i -P -n | grep LISTEN
}

# Re-check for Open Ports
recheck_open_ports() {
    log "Re-checking for Open Ports..."
    sudo nmap -sT -O localhost
}

# Re-check for Hidden SSH
recheck_hidden_ssh() {
    log "Re-checking for Hidden SSH Services..."
    sudo netstat -tulnp | grep ssh
}

# Re-check for Kernel Integrity
recheck_kernel_integrity() {
    log "Re-checking for Kernel Integrity..."
    sudo dmesg | grep -i integrity
}

# Re-check for Configuration Tampering
recheck_config_tampering() {
    log "Re-checking for Configuration Tampering..."
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

    for dir in "${CONFIG_DIRS[@]}"; do
        sudo sha256sum "$dir"
    done
}

# Re-check for Rootkits
recheck_rootkits() {
    log "Re-checking for Rootkits..."
    sudo rkhunter --check
    sudo chkrootkit
}

# Re-check for Malware
recheck_malware() {
    log "Re-checking for Malware..."
    sudo freshclam
    sudo clamscan -r / --bell -i
}

# Re-check for Unauthorized Changes
recheck_unauthorized_changes() {
    log "Re-checking for Unauthorized Changes..."
    sudo aide --check
}

# Re-check for Log Tampering
recheck_log_tampering() {
    log "Re-checking for Log Tampering..."
    sudo sha256sum /var/log/*
}

# Re-check for Network Breaches
recheck_network_breaches() {
    log "Re-checking for Network Breaches..."
    sudo snort -A console -q -c /etc/snort/snort.conf
}

# Main Execution
main() {
    clear
    log "🔧 Final Check Script 🔧"

    preflight_check
    recheck_hidden_services
    recheck_open_ports
    recheck_hidden_ssh
    recheck_kernel_integrity
    recheck_config_tampering
    recheck_rootkits
    recheck_malware
    recheck_unauthorized_changes
    recheck_log_tampering
    recheck_network_breaches

    log "Script Completed. Final checks are done."
}

# Execute Main Function
main

echo "Final Check Script completed."










