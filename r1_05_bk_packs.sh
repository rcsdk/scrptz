#!/bin/bash

# Backup Script (Comprehensive and Robust - Corrected)

# Configuration (Customize these)
BACKUP_DIR="/mnt/usb_stick/secure_backup"  # Mount point of your USB stick + backup directory
CHECKSUM_FILE="$BACKUP_DIR/checksums.txt"
REPORT_FILE="$BACKUP_DIR/verification_report.txt"

# --- Logging Functions ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log() { echo -e "${GREEN}[+] $1${NC}"; }
warn() { echo -e "${YELLOW}[!] $1${NC}"; }
error() { echo -e "${RED}[ERROR] $1${NC}"; exit 1; }

# --- Preflight Check ---
preflight_check() {
    if [[ $EUID -ne 0 ]]; then
        error "This script must be run as root. Use sudo."
    fi

    if [[! -w "$BACKUP_DIR" ]]; then  # Check if the backup directory is writable
        error "Backup directory '$BACKUP_DIR' is not writable. Check permissions and mount point."
    fi
}

# --- Backup Functions ---

backup_file() {
    source_file="$1"
    target_file="$2"
    log "Backing up $source_file..."
    mkdir -p "$(dirname "$target_file")"
    cp "$source_file" "$target_file" || error "Failed to copy $source_file"
    chattr +i "$target_file" || warn "Failed to make $target_file immutable" # Make the backup immutable
}

backup_dir() {
    source_dir="$1"
    target_dir="$2"
    log "Backing up $source_dir..."
    mkdir -p "$target_dir"
    cp -r "$source_dir" "$target_dir" || error "Failed to copy $source_dir"
    find "$target_dir" -type f -exec chattr +i {} \;  # Make files immutable
    find "$target_dir" -type d -exec chattr +i {} \;  # Make directories immutable
}

download_package() {
    pkg_name="$1"
    log "Downloading $pkg_name and dependencies..."

    temp_dir=$(mktemp -d)
    pacman -Sw --noconfirm "$pkg_name" --cachedir "$temp_dir/pkg"
    find "$temp_dir/pkg" -name "$pkg_name-*.pkg.tar.xz" -exec cp {} "$BACKUP_DIR/pkg/" \;
    rm -rf "$temp_dir"
}


# --- Verification Functions ---

verify_file() {
    file_path="$1"
    if [[ -f "$file_path" ]]; then
      return 0
    else
      return 1
    fi
}

# --- Main Script ---

main() {
    clear
    log "Starting Backup..."

    preflight_check # Check for root privileges and writable backup directory

    # Create necessary directories (with error checking)
    mkdir -p "$BACKUP_DIR/etc" "$BACKUP_DIR/boot" "$BACKUP_DIR/var/lib" "$BACKUP_DIR/pkg" || error "Failed to create directories"

    # --- 1. Package Download ---
    packages=(
        "ufw" "clamav" "rkhunter" "chkrootkit" "pacman" "coreutils" "systemd" "linux"
        "selinux-policy" "ossec-hids" "snort" "iptables" "nftables" # Add ALL your packages
        #... add all your packages here!
    )

    for pkg in "${packages[@]}"; do
        download_package "$pkg"
    done

    # --- 2. Configuration Backup ---
    config_files=(
        "/etc/resolv.conf" "/etc/hosts" "/etc/fstab" "/etc/pacman.conf" "/etc/sysctl.d/99-security.conf"
        "/etc/nftables.conf" "/etc/selinux/config" "/etc/ossec-hids/*" "/etc/snort/*" "/etc/passwd" "/etc/group" "/etc/shadow"  # Add ALL config files
        "/boot/grub/*" # Or /boot/efi/EFI/arch/*  - VERY IMPORTANT
        #... add ALL your config files here!
    )

    for config in "${config_files[@]}"; do
        backup_file "$config" "$BACKUP_DIR/$config"
    done

    config_dirs=(
        "/etc/clamav" "/etc/rkhunter.conf.d" "/etc/chkrootkit.conf" "/etc/systemd" "/etc/default" "/etc/security"
        "/etc/selinux" "/var/lib/ossec" "/etc/snort" "/lib/modules/$(uname -r)" # Add ALL config directories
        "/var/lib/aide" # If you're using AIDE
        #... add ALL your config directories here!
    )

    for dir in "${config_dirs[@]}"; do
        backup_dir "$dir" "$BACKUP_DIR/$dir"
    done

    # --- 3. Checksums (optional, but highly recommended) ---
    find "$BACKUP_DIR" -type f -print0 | xargs -0 sha256sum > "$CHECKSUM_FILE" || warn "Failed to create checksum file"

    log "Backup Complete to $BACKUP_DIR"

    # --- 4. Verification (Run this separately after backup) ---
    log "Starting Verification (Run this separately)..."

    > "$REPORT_FILE"  # Clear report file (redirect to create/overwrite, handles permissions)

    # Check essential files
    for file in "${config_files[@]}"; do
      if! verify_file "$BACKUP_DIR/$file"; then
        echo "[FAIL] $file is missing!" >> "$REPORT_FILE"
        warn "$file is missing!"
      else
        echo "[PASS] $file is present." >> "$REPORT_FILE"
      fi
    done

    for dir in "${config_dirs[@]}"; do
      if! verify_file "$BACKUP_DIR/$dir"; then
        echo "[FAIL] $dir is missing!" >> "$REPORT_FILE"
        warn "$dir is missing!"
      else
        echo "[PASS] $dir is present." >> "$REPORT_FILE"
      fi
    done


    # Check checksums
    if [[ -f "$CHECKSUM_FILE" ]]; then
        diff -u "$CHECKSUM_FILE" <(find "$BACKUP_DIR" -type f -print0 | xargs -0 sha256sum | sort) >> "$REPORT_FILE"
        if grep -q '^+' "$REPORT_FILE"; then
            warn "Checksum mismatches found. Check $REPORT_FILE"
        else
            log "Checksums match."
        fi
    fi

    log "Verification Report: $REPORT_FILE"
    cat "$REPORT_FILE" # Display report content

}

main
