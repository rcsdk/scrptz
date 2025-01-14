#!/bin/bash

OUTPUT_DIR="secure_boot_diagnostics"
mkdir -p $OUTPUT_DIR

# Function to log and execute commands
run_command() {
    echo -e "\nRunning: $1\n" | tee -a $OUTPUT_DIR/summary.txt
    eval "$1" | tee -a $OUTPUT_DIR/summary.txt
}

# Collecting System Boot Information
echo "== Collecting Boot Diagnostics ==" | tee -a $OUTPUT_DIR/summary.txt

# System and UEFI Details
run_command "uname -a"
run_command "lsb_release -a || cat /etc/os-release"
run_command "efibootmgr -v"
run_command "ls /sys/firmware/efi/efivars"

# EFI Partition and Files
run_command "lsblk -f"
run_command "find /boot/efi -type f"
run_command "blkid | grep efi"

# GRUB/rEFInd Configurations
run_command "cat /boot/efi/EFI/refind/refind.conf || echo 'rEFInd config not found'"
run_command "cat /boot/refind_linux.conf || echo 'rEFInd Linux config not found'"
run_command "cat /boot/grub/grub.cfg || echo 'GRUB config not found'"

# Bootloader Integrity
run_command "sha256sum /boot/efi/EFI/*/*.efi || echo 'EFI binaries not found'"

# Mounted Partitions and File Systems
run_command "mount | grep /boot"
run_command "findmnt /boot /boot/efi"

# Kernel Command Line and Modules
run_command "cat /proc/cmdline"
run_command "lsinitcpio /boot/* || echo 'Initramfs inspection not supported on this system'"

# Verify Secure Boot Status
if [ -d /sys/firmware/efi ]; then
    run_command "mokutil --sb-state || echo 'mokutil not available'"
else
    echo "This system does not support EFI. Skipping Secure Boot checks." | tee -a $OUTPUT_DIR/summary.txt
fi

# BIOS/UEFI Firmware Variables
run_command "ls /sys/firmware/efi/efivars"
run_command "hexdump -C /sys/firmware/efi/efivars/BootOrder* 2>/dev/null || echo 'No BootOrder found'"
run_command "hexdump -C /sys/firmware/efi/efivars/SecureBoot* 2>/dev/null || echo 'No SecureBoot status found'"

# Summarizing Findings
echo -e "\nDiagnostics collected in $OUTPUT_DIR." | tee -a $OUTPUT_DIR/summary.txt
