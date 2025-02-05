#!/bin/bash

# Create secure temporary directory in RAM
REPORT_DIR=$(mktemp -d)
REPORT="${REPORT_DIR}/FULL_REPORT.txt"
touch "$REPORT"

# Timestamp function
ts() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" | tee -a "$REPORT"
}

# Function to append command output to report
run() {
    local cmd="$*"
    {
        echo -e "\n=== $cmd ===\n"
        eval "$cmd" 2>&1 || echo "[ERROR] Command failed with $?"
    } >> "$REPORT"
}

ts "=== STARTING ULTIMATE LEVEL INVESTIGATION ==="
ts "System: $(uname -a)"

# Core System State
ts "--- CORE SYSTEM STATE ---"
run "free -h"
run "cat /proc/cpuinfo"
run "cat /proc/meminfo"
run "swapon -s"
run "mount"
run "df -h"
run "lsblk -f"
run "blkid"

# Memory Analysis
ts "--- MEMORY ANALYSIS ---"
run "ps auxf"
run "top -b -n 1"
run "vmstat 1 5"
run "cat /proc/slabinfo"
run "cat /proc/vmallocinfo"

# Storage Investigation
ts "--- STORAGE DEEP DIVE ---"
for dev in $(ls /dev/sd* /dev/nvme* 2>/dev/null); do
    ts "Investigating $dev"
    run "hdparm -I $dev 2>/dev/null"
    run "smartctl -a $dev 2>/dev/null"
    run "blockdev --getsize64 $dev"
done

# USB and PCI Analysis
ts "--- USB/PCI ANALYSIS ---"
run "lsusb -v"
run "lspci -vv"
run "dmesg | grep -i usb"
run "dmesg | grep -i pci"

# Network State
ts "--- NETWORK STATE ---"
run "ip a"
run "ip route"
run "netstat -tupan"
run "ss -tulpn"
run "iptables-save"

# Kernel and Module Analysis
ts "--- KERNEL ANALYSIS ---"
run "lsmod"
run "cat /proc/modules"
run "cat /proc/sys/kernel/tainted"
run "cat /proc/sys/kernel/modules_disabled"
for mod in $(lsmod | awk '{print $1}' | grep -v Module); do
    run "modinfo $mod"
done

# Process and File Handle Investigation
ts "--- PROCESS INVESTIGATION ---"
run "lsof"
run "lsof | grep DEL"
run "lsof | grep mem"
run "cat /proc/sys/fs/file-nr"

# Boot and EFI Analysis
ts "--- BOOT ANALYSIS ---"
run "efibootmgr -v"
run "ls -laR /boot"
run "cat /proc/cmdline"
run "systemctl list-units"

# File System Analysis
ts "--- FILESYSTEM ANALYSIS ---"
run "find / -type f -perm -4000 -ls"
run "find / -type f -perm -2000 -ls"
run "find / -type f -size +10M -ls"

# Check for common issues and apply fixes

# 1. Check for full disk partitions and clean up
ts "--- CLEANUP FULL DISKS ---"
for part in $(df -h | awk '{print $5}' | grep -E '[0-9]+%' | grep -v Use); do
    if [[ $part == *"100%"* ]]; then
        ts "Full partition found: $part"
        # Simple cleanup of old logs
        ts "Cleaning up old logs..."
        journalctl --vacuum-size=100M
        find /var/log -type f -name "*.gz" -exec rm {} \;
        ts "Rechecking disk space after cleanup..."
        run "df -h"
    fi
done

# 2. Check for swap usage and enable swap if necessary
ts "--- SWAP USAGE ---"
if [[ $(swapon -s | wc -l) -le 1 ]]; then
    ts "No swap enabled, enabling swap..."
    fallocate -l 2G /swapfile
    chmod 600 /swapfile
    mkswap /swapfile
    swapon /swapfile
    echo "/swapfile none swap sw 0 0" | tee -a /etc/fstab
    ts "Swap enabled."
fi

# 3. Check for running processes with high memory usage and kill them
ts "--- HIGH MEMORY USAGE PROCESSES ---"
high_mem_pid=$(ps aux --sort=-%mem | awk 'NR==2 {print $2}')
high_mem_usage=$(ps aux --sort=-%mem | awk 'NR==2 {print $4}')
if (( $(echo "$high_mem_usage > 80" | bc -l) )); then
    ts "High memory usage by PID $high_mem_pid ($high_mem_usage%)"
    ts "Killing process $high_mem_pid"
    kill -9 $high_mem_pid
fi

# 4. Check for running processes with high CPU usage and kill them
ts "--- HIGH CPU USAGE PROCESSES ---"
high_cpu_pid=$(ps aux --sort=-%cpu | awk 'NR==2 {print $2}')
high_cpu_usage=$(ps aux --sort=-%cpu | awk 'NR==2 {print $3}')
if (( $(echo "$high_cpu_usage > 80" | bc -l) )); then
    ts "High CPU usage by PID $high_cpu_pid ($high_cpu_usage%)"
    ts "Killing process $high_cpu_pid"
    kill -9 $high_cpu_pid
fi

# 5. Check for file permissions and fix them
ts "--- FILE PERMISSIONS ---"
run "find / -type f ! -perm 644 -exec chmod 644 {} \;"
run "find / -type d ! -perm 755 -exec chmod 755 {} \;"

# 6. Check for SELinux/AppArmor issues and log them
ts "--- SECURITY MODULES ---"
if [[ $(sestatus | grep "SELinux status" | awk '{print $3}') == "enabled" ]]; then
    run "sestatus"
    run "audit2allow -a"
fi
if [[ $(aa-status | grep "apparmor" | awk '{print $2}') == "enabled" ]]; then
    run "aa-status"
    run "aa-logprof"
fi

# 7. Update system packages
ts "--- SYSTEM UPDATE ---"
run "apt-get update"
run "apt-get upgrade -y"

# 8. Clean up apt cache
ts "--- APT CACHE CLEANUP ---"
run "apt-get clean"

# Package final report
ts "=== INVESTIGATION AND FIXES COMPLETE ==="
ts "Report size: $(wc -c < "$REPORT") bytes"

# Create compressed archive
FINAL_ARCHIVE="/tmp/system_investigation_$(date +%Y%m%d_%H%M%S).tar.gz"
tar -czf "$FINAL_ARCHIVE" -C "$REPORT_DIR" .

echo "Complete report available at: $FINAL_ARCHIVE"
echo "To view: tar -xzf $FINAL_ARCHIVE && cat FULL_REPORT.txt"
