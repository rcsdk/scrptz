#!/bin/bash

# 1. Disable Networking & Services
echo "Disabling networking and unnecessary services..."
systemctl stop NetworkManager
systemctl disable NetworkManager
systemctl stop sshd
systemctl disable sshd

# 2. Enable Strict Permissions for Critical Files
echo "Setting strict permissions for critical files..."
chmod 700 /root
chmod 600 /root/.bash_history

# 3. Mount a Read-Only Filesystem
echo "Mounting /etc and /var as read-only..."
mount -o remount,ro /etc
mount -o remount,ro /var

# 4. Encrypt Sensitive Files
echo "Encrypting sensitive files..."
gpg --symmetric --cipher-algo AES256 /path/to/sensitive_file

# 5. Log Security Changes
echo "Enabling logging for security-critical changes..."
auditctl -w /etc/ssh/sshd_config -p wa

# 6. Clear System Cache
echo "Clearing system cache..."
rm -rf /var/cache/*

# 7. Check RAM Integrity
echo "Checking RAM integrity for errors..."
dmesg | grep -i error

# 8. Secure File System Configuration
echo "Ensuring strict permissions on /etc/fstab..."
chmod 644 /etc/fstab

# 9. Backup Configuration Files
echo "Backing up critical configuration files..."
cp /etc/ssh/sshd_config /etc/ssh/sshd_config.bak
cp /etc/fstab /etc/fstab.bak

# 10. Mount Filesystem to Read-Only for Protection
echo "Mounting /etc and /var as read-only..."
mount -o remount,ro /etc
mount -o remount,ro /var




#!/bin/bash

# 1. Download and Store Security Tools
echo "Downloading and storing security tools..."
apt-get update
apt-get install -y rkhunter clamav nmap ufw

# 2. Port Scanning to Close Unnecessary Ports
echo "Checking for open ports..."
netstat -tuln | grep LISTEN

# 3. Run Rootkit Hunter
echo "Running rootkit scan..."
rkhunter --check

# 4. Scan for Hidden Services (Hidden SSH, HTTP, etc.)
echo "Checking for hidden SSH services..."
ps aux | grep sshd

# 5. Revert Configuration Files
echo "Reverting configuration files..."
cp /etc/ssh/sshd_config.bak /etc/ssh/sshd_config
cp /etc/fstab.bak /etc/fstab

# 6. Run ClamAV for Malware Detection
echo "Running ClamAV to detect any malware..."
freshclam
clamscan -r / --bell -i

# 7. Check Kernel Integrity
echo "Verifying kernel integrity..."
dmesg | grep -i "invalid"

# 8. Check User and Group Configurations for Suspicious Activity
echo "Checking user and group configurations..."
cat /etc/passwd
cat /etc/group

# 9. Check for Suspicious File Changes
echo "Checking for suspicious file changes..."
find / -type f -exec file {} \; | grep -i 'suspicious'

# 10. Check System Time for Tampering
echo "Checking system time for anomalies..."
timedatectl status



#!/bin/bash

# 1. Download and Install Security Packages
echo "Downloading and installing security packages..."
apt-get update
apt-get install -y ufw fail2ban dnscrypt-proxy auditd apparmor clamav

# 2. Install and Configure Firewall
echo "Setting up the firewall..."
ufw default deny incoming
ufw default allow outgoing
ufw allow http
ufw enable

# 3. Centralize Logs for Easy Access
echo "Centralizing system logs..."
mkdir -p /var/log/centralized
ln -s /var/log/syslog /var/log/centralized/syslog
ln -s /var/log/auth.log /var/log/centralized/auth.log

# 4. Set Up Fail2Ban for Brute Force Protection
echo "Configuring Fail2Ban for brute force protection..."
systemctl enable fail2ban
systemctl start fail2ban

# 5. Harden SSH Configuration
echo "Hardening SSH configuration..."
sed -i 's/PermitRootLogin yes/PermitRootLogin no/' /etc/ssh/sshd_config
sed -i 's/PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config
systemctl restart sshd

# 6. Install Automatic Security Updates
echo "Enabling automatic security updates..."
apt-get install -y unattended-upgrades
dpkg-reconfigure --priority=low unattended-upgrades

# 7. Enable AppArmor for Application Protection
echo "Enabling AppArmor..."
systemctl enable apparmor
systemctl start apparmor

# 8. Harden `/etc/hostname` and `/etc/hosts`
echo "Hardening /etc/hostname and /etc/hosts files..."
chmod 644 /etc/hostname
chmod 644 /etc/hosts

# 9. Secure DNS with DNSCrypt
echo "Configuring DNS over HTTPS..."
systemctl enable dnscrypt-proxy
systemctl start dnscrypt-proxy

# 10. Disable IPv6 if Not Required
echo "Disabling IPv6..."
sysctl -w net.ipv6.conf.all.disable_ipv6=1




#!/bin/bash

# 1. Verify Open Ports and Services
echo "Verifying open ports..."
netstat -tuln

# 2. Test Firewall Configuration
echo "Checking firewall status..."
ufw status

# 3. Run File Integrity Check
echo "Running file integrity check using aide..."
aide --check

# 4. Test SSH Access
echo "Testing SSH access..."
ssh -v localhost

# 5. Confirm ClamAV is Running
echo "Confirming ClamAV is running..."
systemctl status clamav-freshclam

# 6. Monitor System Resources for Anomalies
echo "Monitoring system resources for abnormal behavior..."
top

# 7. Confirm Centralized Log Location
echo "Confirming centralized log location..."
ls /var/log/centralized/

# 8. Verify AppArmor Profiles
echo "Verifying AppArmor profiles..."
apparmor_status

# 9. Ensure All Services Are Active
echo "Checking all essential services are active..."
systemctl list-units --type=service

# 10. Monitor Changes to Critical Files Using Auditd
echo "Monitoring changes to critical files..."
auditctl -w /etc/ -p wa





#!/bin/bash

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Logging function
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

# 1. Verify system integrity
verify_system_integrity() {
    log "Verifying system integrity..."
    pacman -S aide
    aide --init
    aide --check || warn "System integrity check failed. Manual investigation required."
}

# 2. Secure boot configuration
secure_boot_config() {
    log "Securing boot configuration..."
    pacman -S grub
    grub-mkpasswd-pbkdf2 | tee /etc/grub.d/01_password
    chmod 600 /etc/grub.d/01_password
    sed -i 's/GRUB_CMDLINE_LINUX_DEFAULT="quiet"/GRUB_CMDLINE_LINUX_DEFAULT="quiet lsm=lockdown,yama,apparmor,bpf"/' /etc/default/grub
    grub-mkconfig -o /boot/grub/grub.cfg
}

# 3. Implement kernel hardening
harden_kernel() {
    log "Hardening kernel..."
    cat << EOF >> /etc/sysctl.d/99-security.conf
kernel.kptr_restrict=2
kernel.dmesg_restrict=1
kernel.unprivileged_bpf_disabled=1
net.core.bpf_jit_harden=2
kernel.yama.ptrace_scope=2
kernel.kexec_load_disabled=1
EOF
    sysctl -p /etc/sysctl.d/99-security.conf
}

# 4. Set up AppArmor
setup_apparmor() {
    log "Setting up AppArmor..."
    pacman -S apparmor
    systemctl enable apparmor
    systemctl start apparmor
}

# 5. Configure secure umask
set_secure_umask() {
    log "Setting secure umask..."
    echo "umask 027" >> /etc/profile
    echo "session optional pam_umask.so" >> /etc/pam.d/system-login
}

# 6. Disable core dumps
disable_core_dumps() {
    log "Disabling core dumps..."
    echo "* hard core 0" >> /etc/security/limits.conf
    echo "fs.suid_dumpable=0" >> /etc/sysctl.d/99-security.conf
    sysctl -p /etc/sysctl.d/99-security.conf
}

# 7. Secure shared memory
secure_shared_memory() {
    log "Securing shared memory..."
    echo "tmpfs /dev/shm tmpfs defaults,noexec,nosuid,nodev 0 0" >> /etc/fstab
    mount -o remount /dev/shm
}

# 8. Enable process accounting
enable_process_accounting() {
    log "Enabling process accounting..."
    pacman -S acct
    systemctl enable acct
    systemctl start acct
}

# 9. Set up fail2ban
setup_fail2ban() {
    log "Setting up fail2ban..."
    pacman -S fail2ban
    cp /etc/fail2ban/jail.conf /etc/fail2ban/jail.local
    systemctl enable fail2ban
    systemctl start fail2ban
}

# 10. Configure secure TTY
secure_tty() {
    log "Securing TTY..."
    echo "tty1" > /etc/securetty
}

# Main function
main() {
    if [[ $EUID -ne 0 ]]; then
        error "This script must be run as root"
    fi

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

    log "Offline preparation completed successfully."
}

main










