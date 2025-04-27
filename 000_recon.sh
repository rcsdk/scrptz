#!/bin/bash

# Ensure the script is run as root
if [[ $EUID -ne 0 ]]; then
  echo "[ERROR] This script must be run as root or with sudo privileges."
  exit 1
fi

# Step 1: Detect wireless interface
INTERFACE=$(iw dev | awk '$1=="Interface"{print $2}' | head -n 1)
if [ -z "$INTERFACE" ]; then
  echo "[ERROR] No wireless interface detected. Ensure your Wi-Fi adapter is connected and supports scanning."
  exit 1
fi
echo "[INFO] Detected wireless interface: $INTERFACE"

# Step 2: Perform Wi-Fi scan
echo "[INFO] Scanning for Wi-Fi networks. This might take a few seconds..."
SCAN_OUTPUT=$(sudo iwlist "$INTERFACE" scan 2>/dev/null)

if [ -z "$SCAN_OUTPUT" ]; then
  echo "[ERROR] No Wi-Fi networks detected. Check your environment or hardware setup."
  exit 1
fi

# Step 3: Parse and display results
echo -e "\nESSID                          Signal (dBm)    Channel"
echo "------------------------------------------------------------"

echo "$SCAN_OUTPUT" | awk -F: '
/ESSID:/ { essid = $2; gsub(/"/, "", essid) }
/Signal level=/ { signal = $3 }
/Channel:/ { channel = $2; printf "%-30s %-15s %s\n", essid, signal, channel }
' | sort -k2 -n | awk '
NF > 0 { 
  if ($1 == "") $1 = "[HIDDEN]";
  printf "%-30s %-15s %s\n", $1, $2, $3 
}'
