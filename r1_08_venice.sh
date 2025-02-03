#!/bin/bash
echo "[+] Starting initial system preparation..."

echo "[+] Starting task: Check if script is run as root"
if [ "$EUID" -ne 0 ]; then
    echo "[ERROR] Task failed: Check if script is run as root"
    echo "This script must be run as root" >> /var/log/setup_errors.log
else
    echo "[+] Task completed: Check if script is run as root"
fi

echo "[+] Starting task: Check for Arch Linux"
if ! grep -qi "arch linux" /etc/os-release; then
    echo "[ERROR] Task failed: Check for Arch Linux"
    echo "This script must be run on Arch Linux" >> /var/log/setup_errors.log
else
    echo "[+] Task completed: Check for Arch Linux"
fi

echo "[+] Starting task: Check for USB stick mount point"
if [ -z "$USB_MOUNT_POINT" ]; then
    echo "[ERROR] Task failed: Check for USB stick mount point"
    echo "USB stick mount point not set" >> /var/log/setup_errors.log
else
    echo "[+] Task completed: Check for USB stick mount point"
fi

echo "[+] Starting task: Check if USB stick is mounted"
if ! mount | grep -q "$USB_MOUNT_POINT"; then
    echo "[ERROR] Task failed: Check if USB stick is mounted"
    echo "USB stick is not mounted" >> /var/log/setup_errors.log
else
    echo "[+] Task completed: Check if USB stick is mounted"
fi

echo "[+] Starting task: Check network connectivity"
if ! ping -c 1 8.8.8.8 &> /dev/null; then
    echo "[ERROR] Task failed: Check network connectivity"
    echo "Network connectivity check failed" >> /var/log/setup_errors.log
else
    echo "[+] Task completed: Check network connectivity"
fi

echo "[+] Starting task: Check architecture"
if ! uname -m | grep -q "x86_64"; then
    echo "[ERROR] Task failed: Check architecture"
    echo "Architecture check failed, expected x86_64" >> /var/log/setup_errors.log
else
    echo "[+] Task completed: Check architecture"
fi

echo "[+] Starting task: Check available disk space"
if ! df -h "$USB_MOUNT_POINT" | grep -q "avail"; then
    echo "[ERROR] Task failed: Check available disk space"
    echo "Disk space check failed" >> /var/log/setup_errors.log
else
    echo "[+] Task completed: Check available disk space"
fi

echo "[+] Starting task: Create cache directory"
mkdir -p "$USB_MOUNT_POINT/cache"
if [ $? -ne 0 ]; then
    echo "[ERROR] Task failed: Create cache directory"
    echo "Failed to create cache directory" >> /var/log/setup_errors.log
else
    echo "[+] Task completed: Create cache directory"
fi

echo "[+] Starting task: Create config directory"
mkdir -p "$USB_MOUNT_POINT/configs"
if [ $? -ne 0 ]; then
    echo "[ERROR] Task failed: Create config directory"
    echo "Failed to create config directory" >> /var/log/setup_errors.log
else
    echo "[+] Task completed: Create config directory"
fi
