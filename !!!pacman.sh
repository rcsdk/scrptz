#!/bin/bash

# Exit immediately if a command fails
set -e

# Check if the script is running as root
if [[ $EUID -ne 0 ]]; then
    echo "This script must be run as root" 1>&2
    exit 1
fi

# Clean pacman cache to clear out corrupted DB files
echo "Cleaning pacman cache..."
pacman -Scc --noconfirm

# Reinitialize pacman keys (resets pacman keyring)
echo "Reinitializing pacman keys..."
pacman-key --init
pacman-key --populate archlinux

# Delete any pacman sync cache to get fresh copies of databases
echo "Removing compromised pacman sync directories..."
rm -rf /var/lib/pacman/sync/*

# Update pacman database and install latest pacman version
echo "Synchronizing pacman databases..."
pacman -Sy --noconfirm pacman

# Change DNS to secure DNS (Google and Cloudflare DNS as backup)
echo "Changing DNS configuration..."
cat <<EOF > /etc/resolv.conf
# DNS Servers
nameserver 1.1.1.1   # Cloudflare DNS
nameserver 8.8.8.8   # Google DNS
nameserver 8.8.4.4   # Google DNS
EOF

# Lock DNS configuration to prevent further tampering
echo "Locking DNS configuration..."
chattr +i /etc/resolv.conf

# Confirm that DNS is correctly configured
echo "Checking DNS resolution..."
dig google.com +short

# Notify user of completion
echo "Pacman repair and DNS configuration complete. DNS is now locked and protected."
