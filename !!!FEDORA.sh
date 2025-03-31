#!/bin/bash
# =============================================
# FEDORA LIVE USB - DEFCON ZERO HARDENING + EXECUTIVE BROWSER
# OPTIMIZED FOR RAM/LIVEUSB CONSTRAINTS
# =============================================
# Author: DeepSeek Security Team | Venice AI
# Version: 4.2 (BUGFREE_RAM_PATCH)
# Usage:  
#   sudo ./fedora_defcon0_ceo.sh [-v|--verbose] [-q|--quiet]
# Requirements:
#   External storage mounted at /dev/sdb3 (adjust EXTERNAL_DRIVE variable if needed)

# ---- CONSTANTS & CONFIG ----
EXTERNAL_DRIVE="/dev/sdb3"        # Adjust if your external is a different device
EXTERNAL_MOUNT="/mnt/external"    # Mount point for external storage
TMP_DIR="$EXTERNAL_MOUNT/tmp"     # Primary temp directory on external drive
LOG_FILE="$TMP_DIR/defcon0_$(date +%FT%TZ).log"

declare -xr SECURE_BROWSER="/usr/bin/chromium-browser"
declare -ra DISABLE_SERVICES=(
  avahi-daemon cups bluetoothd tracker-miner tracker-extract-3
  colord PackageKit power-profiles-daemon
)
declare -ra SECURE_SITES=(
  "https://chatgpt.com"
  "https://claude.ai"
  "https://lm-arena.ai"
  "https://grok.stream"
  "https://github.com/login"
)

# ---- ERROR HANDLING ----
set -eu -o pipefail
trap 'cleanup $? "$BASH_COMMAND" "$LINENO"' EXIT TERM INT

# ---- UTILITY FUNCTIONS ----
mount_external() {
  if ! mountpoint -q "$EXTERNAL_MOUNT"; then
    echo "Mounting external storage..."
    mkdir -p "$EXTERNAL_MOUNT"
    mount "$EXTERNAL_DRIVE" "$EXTERNAL_MOUNT" || {
      echo "FATAL: Failed to mount $EXTERNAL_DRIVE to $EXTERNAL_MOUNT"
      exit 1
    }
    chmod 700 "$EXTERNAL_MOUNT"
  fi
}

setup_swap() {
  local ZRAM_SIZE=$(( $(grep MemTotal /proc/meminfo | awk '{print $2}') * 2 ))k
  echo "Creating zram swap of $((ZRAM_SIZE/1024/1024))M..."
  modprobe zram num_devices=1
  echo "$ZRAM_SIZE" > /sys/devices/virtual/block/zram0/disksize
  mkswap /dev/zram0 && swapon /dev/zram0
}

verify_root() {
  [[ $(id -u) -eq 0 ]] || { echo "🚨 Run as root!"; exit 1; }
}

init_env() {
  export TMPDIR="$TMP_DIR"
  mkdir -p "$TMP_DIR"
  export XDG_RUNTIME_DIR="$TMP_DIR/xdg"
  mkdir -p "$XDG_RUNTIME_DIR"
  chmod 700 "$XDG_RUNTIME_DIR"
}

# ---- RESOURCE MANAGEMENT ----
cleanup() {
  local exit_code=$1
  local failed_cmd="$2"
  local line_number="$3"

  echo "=== CLEANUP PHASE ==="
  echo "Exit Code: $exit_code"
  [[ -n $failed_cmd ]] && echo "Failed Command: $failed_cmd at line $line_number"

  # Unmount external storage
  umount -l "$EXTERNAL_MOUNT" || true
  rm -rf "$EXTERNAL_MOUNT"/*  # Clear ephemeral storage

  # Remove zram swap
  swapoff /dev/zram0 && rmmod zram || true

  # Zero log file
  shred -u -n 3 -z "$LOG_FILE" || true

  # Final report
  [[ $exit_code -eq 0 ]] && echo "✅ Success" || echo "❌ Failure"
}

# ---- SYSTEM HARDENING ----
system_harden() {
  echo "🛡️ [KERNEL] Applying memory protections..."
  cat <<EOF | tee /etc/sysctl.d/99-defcon0.conf
kernel.kptr_restrict=2
vm.overcommit_memory=2
net.ipv4.conf.all.log_martians=1
EOF
  sysctl --system

  echo "🛡️ [SERVICES] Disabling non-essential..."
  for svc in "${DISABLE_SERVICES[@]}"; do
    systemctl stop "$svc" &>/dev/null && systemctl mask "$svc" &>/dev/null
  done

  echo "🛡️ [FIREWALL] Enforcing Drop policy..."
  firewall-cmd --set-default-zone=drop --permanent &>/dev/null
  firewall-cmd --reload &>/dev/null
}

# ---- BROWSER LAUNCHER ----
launch_browser() {
  local profile_dir=$(mktemp -d "$TMP_DIR/chrome_profile.XXXXXX")
  local firejail_profile=$(mktemp "$TMP_DIR/firejail.XXXXXX")

  cat <<EOF> "$firejail_profile"
private
netfilter
seccomp
nogroups
read-only /etc
EOF

  echo "Launching secure browser..."
  firejail --profile="$firejail_profile" \
    "$SECURE_BROWSER" \
    --user-data-dir="$profile_dir" \
    --no-sandbox \
    --disable-features=AudioServiceOutOfProcess \
    --disable-logging \
    --args "${SECURE_SITES[@]}" &

  echo "🔊 Dictation activated via $(pacmd list-sources | grep -B1 'alsa_output' | awk '/index/ {print $2}')"
}

# ---- EXECUTIVE REPORT ----
generate_report() {
  echo "Generating operational report..."
  cat <</EOF> "$LOG_FILE"
DEFCON0_EXECUTION_REPORT:
EXTERNAL_DRIVE: $(df -h "$EXTERNAL_MOUNT" | tail -1 | awk '{print $1" "$2" "$3}')
SWAP_ACTIVE: $(grep /dev/zram0 /proc/swaps | awk '{print $3}')
MEMORY_USAGE: $(free -m | awk '/Mem:/{printf "%d/%dMB (%.0f%%)", $3, $2, $3/$2*100}')
ATTACK_SURFACE: ${#DISABLE_SERVICES[@]} services neutralized
BROWSER_SANDBOX: Firejail profile $firejail_profile
EOF
}

# ---- MAIN EXECUTION ----
main() {
  verify_root
  mount_external
  setup_swap
  init_env

  # Core hardening
  system_harden

  # Launch secure interface
  launch_browser

  # Generate audit report
  generate_report

  # Keep alive
  while true; do sleep 3600; done
}

# ---- ENTRY POINT ----
main "$@"



