#!/bin/bash

# Crude reality: Run as root or with sudo
if [[ $EUID -ne 0 ]]; then
  echo "[ERROR] Run this script as root or with sudo privileges."
  exit 1
fi

# Required dependencies
DEPENDENCIES=("bettercap" "iw" "ip" "whiptail")

# Function to check dependencies
check_dependencies() {
  echo "[INFO] Checking dependencies..."
  missing=()
  for dep in "${DEPENDENCIES[@]}"; do
    if ! command -v "$dep" &> /dev/null; then
      missing+=("$dep")
    fi
  done

  if [ ${#missing[@]} -ne 0 ]; then
    echo "[ERROR] The following dependencies are missing: ${missing[*]}"
    echo "[INFO] Install them using your package manager (e.g., apt, yum, etc.) before running this script."
    exit 1
  fi

  echo "[INFO] All dependencies are installed."
}

# Dependency check (script refuses to run if any are missing)
check_dependencies

# Step 1: Confirm Interface
INTERFACE=$(whiptail --inputbox "Enter your wireless interface (e.g., wlp2s0):" 10 60 wlp2s0 --title "Bettercap Interface Selection" 3>&1 1>&2 2>&3)
if [[ $? -ne 0 ]]; then
  echo "[INFO] Operation cancelled."
  exit 1
fi

# Verify the interface exists via `ip a`
if ! ip link show "$INTERFACE" &> /dev/null; then
  whiptail --msgbox "Interface '$INTERFACE' not found. Check with 'ip a' to confirm the correct interface name." 10 60 --title "Error"
  exit 1
fi

# Step 2: Confirm Switching to Monitor Mode
if ! whiptail --yesno "Switch interface '$INTERFACE' to monitor mode?\n\nThis is required for Wi-Fi reconnaissance." 10 60 --title "Monitor Mode Confirmation"; then
  echo "[INFO] Operation cancelled."
  exit 1
fi

# Switch to monitor mode
echo "[INFO] Switching interface $INTERFACE to monitor mode..."
ip link set "$INTERFACE" down
iw dev "$INTERFACE" set type monitor
ip link set "$INTERFACE" up

# Verify monitor mode success
if [[ $(iwconfig "$INTERFACE" | grep -i "Mode:Monitor") ]]; then
  whiptail --msgbox "Interface '$INTERFACE' successfully switched to monitor mode." 10 60 --title "Monitor Mode Activated"
else
  whiptail --msgbox "Failed to switch interface '$INTERFACE' to monitor mode. Check your wireless card compatibility." 10 60 --title "Error"
  exit 1
fi

# Step 3: Run Bettercap Command
whiptail --msgbox "Starting Bettercap with Wi-Fi reconnaissance on '$INTERFACE'.\n\nCommand:\nsudo bettercap -iface $INTERFACE -eval \"wifi.recon on; wifi.show; wifi.assoc all; wifi.write handshake.pcap\"\n\nPress OK to continue." 15 60 --title "Bettercap Starting"

sudo bettercap -iface "$INTERFACE" -eval "wifi.recon on; wifi.show; wifi.assoc all; wifi.write handshake.pcap" | tee /tmp/bettercap_output.log

# Step 4: Parse Results for Best Targets
TOP_APS=$(grep -E "SSID|SIGNAL" /tmp/bettercap_output.log | sort -k3 -nr | head -n 5)
if [[ -z "$TOP_APS" ]]; then
  whiptail --msgbox "No access points detected. Ensure you are in a suitable environment with active Wi-Fi networks." 10 60 --title "No Results"
  exit 1
fi

whiptail --msgbox "Top Access Points Detected:\n\n$TOP_APS\n\nCheck /tmp/bettercap_output.log for details." 15 60 --title "Scan Results"

# Step 5: Option to Switch Back to Managed Mode
if whiptail --yesno "Would you like to switch the interface '$INTERFACE' back to managed mode (normal mode)?" 10 60 --title "Switch Back to Managed Mode"; then
  ip link set "$INTERFACE" down
  iw dev "$INTERFACE" set type managed
  ip link set "$INTERFACE" up
  whiptail --msgbox "Interface '$INTERFACE' successfully switched back to managed mode." 10 60 --title "Managed Mode Restored"
else
  whiptail --msgbox "Interface '$INTERFACE' remains in monitor mode. Use the following commands to switch back manually:\n\nip link set $INTERFACE down\niw dev $INTERFACE set type managed\nip link set $INTERFACE up" 15 60 --title "Manual Switch Instructions"
fi

echo "[INFO] Done. Happy hunting!"
