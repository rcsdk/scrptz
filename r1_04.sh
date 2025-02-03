#!/bin/bash
echo "Running Initial Environment Preparation Script on Arch Linux..."

# Update timestamps and locale settings
echo "Timestamp: $(date '+%Y-%m-%d %H:%M:%S')"
sudo timedatectl set-timezone UTC
sudo localectl set-locale LANG=en_US.UTF-8

# Disable unused services, which can be unsafe or unnecessary
echo "Disabling unused services..."
sudo systemctl stop bluetooth.service
sudo systemctl disable bluetooth.service
sudo systemctl stop avahi-daemon.service
sudo systemctl disable avahi-daemon.service

# Clean temporary files
echo "Cleaning temporary files..."
sudo rm -rf /tmp/*
sudo rm -rf /var/tmp/*
sudo pacman -Rns $(pacman -Qdtq) --noconfirm

# Lock down key config files
echo "Locking down key config files..."
sudo chattr +i /etc/pacman.conf /etc/passwd /etc/shadow /etc/gshadow /etc/group

# Implement checksums for key files
echo "Generating checksums for key files..."
sha256sum /etc/pacman.conf /etc/passwd /etc/shadow /etc/gshadow /etc/group > /etc/security/checksums.sha256

echo "Offline Preparation Complete."





#!/bin/bash
echo "Running Security Breaches Detection and System Hardening on Arch Linux..."

# Check for hidden services and open ports
echo "Checking for open ports and services..."
sudo netstat -tulnp
sudo ss -tulnp

# Scan for rootkits and malware using rkhunter and chkrootkit
echo "Scanning system for rootkits..."
sudo pacman -S rkhunter chkrootkit --noconfirm
sudo rkhunter --check
sudo chkrootkit

# Harden kernel settings
echo "Hardening kernel..."
cat << EOF | sudo tee /etc/sysctl.d/99-security.conf
kernel.kptr_restrict=2
kernel.dmesg_restrict=1
kernel.printk=3 3 3 3
EOF
sudo sysctl -p /etc/sysctl.d/99-security.conf

# Close unnecessary ports (keep HTTP/HTTPS open only)
echo "Configuring firewall to block all ports except HTTP/HTTPS..."
sudo ufw default deny incoming
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw enable

# Validate DNS settings
echo "Validating DNS settings..."
cat /etc/resolv.conf





#!/bin/bash
echo "Running Security Setup and Log Centralization on Arch Linux..."

# Install essential security tools
sudo pacman -S ufw fail2ban --noconfirm

# Configure UFW (Uncomplicated Firewall)
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw enable

# Install and configure fail2ban
sudo systemctl enable fail2ban
sudo systemctl start fail2ban

# Centralize logs
echo "Centralizing logs..."
sudo mkdir -p /var/log/centralized
sudo ln -sf /var/log/syslog /var/log/centralized/syslog
sudo ln -sf /var/log/auth.log /var/log/centralized/auth.log
sudo chattr +i /var/log/centralized/syslog
sudo chattr +i /var/log/centralized/auth.log

# Verify permissions and ensure log integrity
echo "Checking log file integrity..."
ls -l /var/log/centralized




#!/bin/bash
echo "Running Verification and Resilience Check on Arch Linux..."

# Verify network and open ports
echo "Verifying network and open ports..."
sudo netstat -tulnp

# Re-scan for rootkits and malware
echo "Rescanning for rootkits..."
sudo rkhunter --check
sudo chkrootkit

# Validate kernel hardening
echo "Validating kernel hardening..."
sysctl -p /etc/sysctl.d/99-security.conf

# Check log files and file integrity
echo "Checking log file integrity..."
sha256sum /etc/pacman.conf /etc/passwd /etc/shadow /etc/gshadow /etc/group > /etc/security/checksums.new.sha256
diff /etc/security/checksums.sha256 /etc/security/checksums.new.sha256

# Check if critical files are immutable
lsattr /etc/pacman.conf /etc/passwd /etc/shadow /etc/gshadow /etc/group





