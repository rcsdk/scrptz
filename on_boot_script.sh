#!/bin/bash
################################################################################
# Enterprise Security Hardening Script
#
# Dynamic Index (auto-generated from external JSON configuration):
#   Category 1: Wi-Fi Security .................... 6 ideas
#   Category 2: Bluetooth Security ................. 3 ideas
#   Category 3: Network Service Hardening .......... 3 ideas
#   Category 4: SSH & Remote Access Security ....... 4 ideas
#   Category 5: IPv6 Security ....................... 3 ideas
#   Category 6: DNS & Network Privacy .............. 2 ideas
#   Category 7: ARP & Rogue Device Detection ......... 2 ideas
#
# TOTAL IDEAS: 23
#
# This script reads its configuration and dependency list from a single JSON file.
# Make sure that 'jq' is installed and that the file 'config.json' is in the same
# directory as this script (or adjust CONFIG_FILE accordingly).
################################################################################

# External configuration file (JSON)
CONFIG_FILE="./config.json"

apt-get update -o Debug::NoLocking=true && apt-get install jq


# Check if jq is installed
if ! command -v jq >/dev/null 2>&1; then
    echo "Error: 'jq' is required but not installed. Please install jq and try again."
    exit 1
fi

# Load configuration values from JSON using jq
VERSION=$(jq -r '.version' "$CONFIG_FILE")
INTERFACE=$(jq -r '.environment.interface' "$CONFIG_FILE")
WHITELIST=$(jq -r '.environment.whitelist[]' "$CONFIG_FILE")
BLOCK_SSIDS=$(jq -r '.environment.block_ssids[]' "$CONFIG_FILE")
THRESHOLD=$(jq -r '.environment.threshold' "$CONFIG_FILE")
SECURE_DNS=$(jq -r '.environment.secure_dns' "$CONFIG_FILE")
BLOCKED_PORTS=$(jq -r '.environment.blocked_ports[]' "$CONFIG_FILE")

# Load instructions for each category
INST_WIFI=$(jq -r '.instructions.wifi_security' "$CONFIG_FILE")
INST_BT=$(jq -r '.instructions.bluetooth_security' "$CONFIG_FILE")
INST_NET=$(jq -r '.instructions.network_service_hardening' "$CONFIG_FILE")
INST_SSH=$(jq -r '.instructions.ssh_remote_access_security' "$CONFIG_FILE")
INST_IPV6=$(jq -r '.instructions.ipv6_security' "$CONFIG_FILE")
INST_DNS=$(jq -r '.instructions.dns_network_privacy' "$CONFIG_FILE")
INST_ARP=$(jq -r '.instructions.arp_rogue_detection' "$CONFIG_FILE")

# Load installation settings
PKG_MANAGER=$(jq -r '.install.package_manager' "$CONFIG_FILE")
INSTALL_FLAGS=$(jq -r '.install.flags' "$CONFIG_FILE")
INSTALL_PACKAGES=$(jq -r '.install.packages[]' "$CONFIG_FILE")

# Set up log file
LOGFILE="/tmp/enterprise_security.log"
echo "Enterprise Security Hardening Log - $(date)" > "$LOGFILE"

# Logging function: prints message with a timestamp
log() {
    local msg="$1"
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $msg" | tee -a "$LOGFILE"
}

# run_command: Execute a command, log its description and output, and return its exit status.
run_command() {
    local cmd="$1"
    local desc="$2"
    log "[*] $desc"
    eval "$cmd" >> "$LOGFILE" 2>&1
    local status=$?
    if [ $status -eq 0 ]; then
        log "[+] $desc succeeded."
    else
        log "[-] $desc failed with status $status."
    fi
    return $status
}


rfkill block bluetooth


sudo apt update && sudo apt install -y linux-image-6.1.0-31-amd64 intel-microcode  

sudo apt install -y firmware-misc-nonfree  

echo "powersave" | sudo tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor  

sudo sed -i 's/\[SeatDefaults\]/\[Seat:*\]/g' /etc/lightdm/lightdm.conf /usr/share/lightdm/lightdm.conf.d/*.conf

sudo apt update && sudo apt upgrade -y && sudo apt install --reinstall xorg xorg-server pixman-1 -y

echo "Disabling suspicious files and directories..."
sudo mv /etc/.java /etc/.java_disabled 2>/dev/null
sudo mv /usr/lib/debug/.dwz /usr/lib/debug/.dwz_disabled 2>/dev/null
sudo mv /usr/lib/jvm/.java-1.17.0-openjdk-amd64.jinfo /usr/lib/jvm/.java-1.17.0-openjdk-amd64.jinfo_disabled 2>/dev/null
sudo mv /usr/lib/libreoffice/share/.registry /usr/lib/libreoffice/share/.registry_disabled 2>/dev/null


sudo touch /var/log/wtmp
sudo touch /var/log/lastlog
sudo chmod 664 /var/log/wtmp
sudo chmod 664 /var/log/lastlog



#######################################
# Dependency Installation
#######################################
install_dependencies() {
    log "-----------------------------"
    log "[Dependency Installation] - Installing necessary tools"
    local pkg_list=""
    for pkg in $INSTALL_PACKAGES; do
        pkg_list="$pkg_list $pkg"
    done
    log "[*] Installing packages: $pkg_list"
    run_command "sudo $PKG_MANAGER install $INSTALL_FLAGS $pkg_list" "Installing dependencies"
}

#######################################
# Category 1: Wi-Fi Security
# Instruction: $INST_WIFI
#######################################
wifi_security() {
    log "-----------------------------"
    log "[Category: Wi-Fi Security] - $INST_WIFI"
    local cat_status=1

    # 1. Disconnect from all networks
    run_command 'nmcli radio wifi off && sleep 2 && nmcli radio wifi on' "Disconnecting from all Wi-Fi networks"
    [ $? -ne 0 ] && cat_status=0

    # 2. Block rogue SSIDs (from config)
    for ssid in $BLOCK_SSIDS; do
        run_command "nmcli connection delete \"$ssid\"" "Blocking rogue SSID: $ssid"
        [ $? -ne 0 ] && cat_status=0
    done

    # 3. Forget unknown networks (keep only whitelisted)
    local connections
    connections=$(nmcli -t -f NAME connection show)
    for conn in $connections; do
        local keep=0
        for w in $WHITELIST; do
            if [[ "$conn" == "$w" ]]; then
                keep=1
                break
            fi
        done
        if [ $keep -eq 0 ]; then
            run_command "nmcli connection delete \"$conn\"" "Forgetting unknown network: $conn"
            [ $? -ne 0 ] && cat_status=0
        fi
    done

    # 4. Advisory: Prevent Wi-Fi password leaks (manual check)
    log "[*] Advisory: Verify that 'nmcli connection show' does not log plaintext Wi-Fi passwords."

    # 5. Enable MAC randomization on whitelisted networks
    for ssid in $WHITELIST; do
        run_command "nmcli connection modify \"$ssid\" 802-11-wireless.mac-address-randomization random" "Enabling MAC randomization for $ssid"
        [ $? -ne 0 ] && cat_status=0
    done

    # 6. Dynamic Rogue AP Detection & Mitigation
    dynamic_wifi_rogue_mitigation
    [ $? -ne 0 ] && cat_status=0

    log "[Category: Wi-Fi Security] Completed with status: $cat_status"
    return $cat_status
}

# Function: dynamic_wifi_rogue_mitigation
dynamic_wifi_rogue_mitigation() {
    log "-----------------------------"
    log "[Wi-Fi Dynamic Rogue AP Detection]"
    local target_ssid="VIVOFIBRA-2421"
    local count=0
    local max_rate=0
    local min_rate=10000
    local rogue_bssid=""
    local line
    local numeric_rate

    mapfile -t wifi_lines < <(nmcli -t -f BSSID,SSID,CHAN,RATE device wifi list | grep "$target_ssid")
    count=${#wifi_lines[@]}
    log "[*] Found $count entries for SSID $target_ssid."

    if [ $count -lt 2 ]; then
        log "[*] Not enough entries to compare. Skipping dynamic rogue detection."
        return 0
    fi

    for line in "${wifi_lines[@]}"; do
        IFS=":" read -r bssid ssid chan rate <<< "$line"
        numeric_rate=$(echo "$rate" | awk '{print $1+0}')
        log "[*] Detected AP: BSSID=$bssid, SSID=$ssid, Channel=$chan, Rate=$numeric_rate Mbit/s"
        (( numeric_rate > max_rate )) && max_rate=$numeric_rate
        if (( numeric_rate < min_rate )); then
            min_rate=$numeric_rate
            rogue_bssid="$bssid"
        fi
    done

    log "[*] Maximum rate: $max_rate Mbit/s | Minimum rate: $min_rate Mbit/s (Candidate rogue: $rogue_bssid)"
    local diff=$(( max_rate - min_rate ))
    if (( diff >= THRESHOLD )); then
        log "[*] Difference ($diff Mbit/s) meets threshold ($THRESHOLD Mbit/s). Rogue AP detected: $rogue_bssid"
        deauth_rogue_ap "$rogue_bssid"
        return $?
    else
        log "[*] No significant rate difference detected. No rogue AP mitigation needed."
        return 0
    fi
}

# Function: deauth_rogue_ap
deauth_rogue_ap() {
    local target_bssid="$1"
    local iface="$INTERFACE"
    local mon_iface="${iface}mon"

    log "[*] Initiating deauthentication attack on rogue BSSID: $target_bssid"
    run_command "airmon-ng start $iface" "Enabling monitor mode on $iface"
    if [ $? -ne 0 ]; then
        log "[-] Failed to enable monitor mode on $iface. Skipping deauth."
        return 1
    fi

    run_command "timeout 10 aireplay-ng --deauth 0 -a $target_bssid $mon_iface" "Deauthenticating rogue AP $target_bssid"
    run_command "airmon-ng stop $mon_iface" "Disabling monitor mode on $mon_iface"
    log "[*] Deauthentication attack completed for rogue AP $target_bssid."
    return 0
}

#######################################
# Category 2: Bluetooth Security
# Instruction: $INST_BT
#######################################
bluetooth_security() {
    log "-----------------------------"
    log "[Category: Bluetooth Security] - $INST_BT"
    local cat_status=1

    run_command "rfkill block bluetooth" "Disabling Bluetooth"
    [ $? -ne 0 ] && cat_status=0

    local bt_devices
    bt_devices=$(bluetoothctl devices | awk '{print $2}')
    for dev in $bt_devices; do
        run_command "bluetoothctl remove \"$dev\"" "Removing Bluetooth device $dev"
        [ $? -ne 0 ] && cat_status=0
    done

    run_command "hciconfig hci0 reset" "Resetting Bluetooth interface hci0"
    [ $? -ne 0 ] && cat_status=0
    run_command "systemctl restart bluetooth" "Restarting Bluetooth service"
    [ $? -ne 0 ] && cat_status=0

    log "[Category: Bluetooth Security] Completed with status: $cat_status"
    return $cat_status
}

#######################################
# Category 3: Network Service Hardening
# Instruction: $INST_NET
#######################################
network_service_hardening() {
    log "-----------------------------"
    log "[Category: Network Service Hardening] - $INST_NET"
    local cat_status=1

    run_command "systemctl stop smbd rpcbind avahi-daemon saned" "Stopping SMB, RPC, Avahi, and saned services"
    [ $? -ne 0 ] && cat_status=0
    run_command "systemctl disable smbd rpcbind avahi-daemon saned" "Disabling these services at boot"
    [ $? -ne 0 ] && cat_status=0

    for port in $BLOCKED_PORTS; do
        run_command "iptables -A INPUT -p tcp --dport $port -j DROP" "Blocking port $port"
        [ $? -ne 0 ] && cat_status=0
    done

    log "[Category: Network Service Hardening] Completed with status: $cat_status"
    return $cat_status
}

#######################################
# Category 4: SSH & Remote Access Security
# Instruction: $INST_SSH
#######################################
ssh_remote_access_security() {
    log "-----------------------------"
    log "[Category: SSH & Remote Access Security] - $INST_SSH"
    local cat_status=1

    run_command "systemctl stop sshd" "Stopping SSH service"
    [ $? -ne 0 ] && cat_status=0
    run_command "systemctl disable sshd" "Disabling SSH at boot"
    [ $? -ne 0 ] && cat_status=0
    run_command "ufw deny 22/tcp" "Blocking SSH (port 22) at firewall level"
    [ $? -ne 0 ] && cat_status=0
    run_command "ss -tulnp | grep ssh" "Verifying SSH is not listening"
    if [ $? -eq 0 ]; then
        log "[-] SSH ports are still listening."
        cat_status=0
    else
        log "[+] No SSH listening ports detected."
    fi

    log "[Category: SSH & Remote Access Security] Completed with status: $cat_status"
    return $cat_status
}

#######################################
# Category 5: IPv6 Security
# Instruction: $INST_IPV6
#######################################
ipv6_security() {
    log "-----------------------------"
    log "[Category: IPv6 Security] - $INST_IPV6"
    local cat_status=1

    run_command "sysctl -w net.ipv6.conf.all.disable_ipv6=1" "Disabling IPv6 temporarily"
    [ $? -ne 0 ] && cat_status=0

    if ! grep -q "^net.ipv6.conf.all.disable_ipv6" /etc/sysctl.conf; then
        run_command "echo 'net.ipv6.conf.all.disable_ipv6 = 1' >> /etc/sysctl.conf" "Appending IPv6 disable to sysctl.conf"
        [ $? -ne 0 ] && cat_status=0
    else
        log "[*] IPv6 permanent disable already set in sysctl.conf."
    fi
    run_command "sysctl -p" "Applying sysctl.conf changes"
    [ $? -ne 0 ] && cat_status=0

    log "[Category: IPv6 Security] Completed with status: $cat_status"
    return $cat_status
}

#######################################
# Category 6: DNS & Network Privacy
# Instruction: $INST_DNS
#######################################
dns_network_privacy() {
    log "-----------------------------"
    log "[Category: DNS & Network Privacy] - $INST_DNS"
    local cat_status=1

    run_command "systemd-resolve --flush-caches" "Flushing DNS cache"
    [ $? -ne 0 ] && cat_status=0
    run_command "echo 'nameserver $SECURE_DNS' | tee /etc/resolv.conf" "Setting secure DNS to $SECURE_DNS"
    [ $? -ne 0 ] && cat_status=0

    log "[Category: DNS & Network Privacy] Completed with status: $cat_status"
    return $cat_status
}
4
dns_network_privacy() {
    log "-----------------------------"
    log "[Category: DNS & Network Privacy] - $INST_DNS"
    local cat_status=1

    # Unlock the resolve.conf
    run_command "chmod 644 /etc/resolv.conf" "Unlocking /etc/resolv.conf"
    [ $? -ne 0 ] && cat_status=0

    # Test several DNS pings and get the 3 fastest
    log "[*] Testing DNS servers for latency..."
    local dns_servers=("1.1.1.1" "8.8.8.8" "9.9.9.9" "8.8.4.4" "1.0.0.1")
    local fastest_dns=""
    local fastest_time=1000
    for dns in "${dns_servers[@]}"; do
        local ping_time
        ping_time=$(ping -c 3 -q "$dns" | grep -oP 'min/avg/max/mdev = \K[0-9.]+')
        local avg_ping=$(echo "$ping_time" | awk -F'/' '{print $2}')
        log "[*] DNS: $dns, Average Ping: $avg_ping ms"
        
        if (( $(echo "$avg_ping < $fastest_time" | bc -l) )); then
            fastest_dns="$dns"
            fastest_time="$avg_ping"
        fi
    done

    log "[*] Fastest DNS is: $fastest_dns"

    # Replace resolv.conf with the fastest DNS
    run_command "echo 'nameserver $fastest_dns' | tee /etc/resolv.conf" "Setting secure DNS to $fastest_dns"
    [ $? -ne 0 ] && cat_status=0

    # Lock the resolve.conf again
    run_command "chmod 600 /etc/resolv.conf" "Locking /etc/resolv.conf"
    [ $? -ne 0 ] && cat_status=0

    log "[Category: DNS & Network Privacy] Completed with status: $cat_status"
    return $cat_status
}


#######################################
# Category 7: ARP & Rogue Device Detection
# Instruction: $INST_ARP
#######################################
arp_rogue_detection() {
    log "-----------------------------"
    log "[Category: ARP & Rogue Device Detection] - $INST_ARP"
    local cat_status=1

    run_command "ip neigh show" "Running ARP scan (ip neigh show)"
    [ $? -ne 0 ] && cat_status=0
    run_command "nmcli device wifi list | grep -E 'SSID|BSSID'" "Detecting rogue APs via Wi-Fi scan"
    [ $? -ne 0 ] && cat_status=0

    log "[Category: ARP & Rogue Device Detection] Completed with status: $cat_status"
    return $cat_status
}

#######################################
# Main Execution: Run All Categories
#######################################
log "-----------------------------"
log "Starting Enterprise Security Hardening Script - Version $VERSION"

# First, install dependencies as per the JSON config.
install_dependencies

wifi_security;                status_wifi=$?
bluetooth_security;           status_bt=$?
network_service_hardening;    status_net=$?
ssh_remote_access_security;   status_ssh=$?
ipv6_security;                status_ipv6=$?
dns_network_privacy;          status_dns=$?
arp_rogue_detection;          status_arp=$?

# Overall Summary
log "-----------------------------"
log "Enterprise Security Hardening Script Completed."
log "Summary of Category Statuses:"
log "Wi-Fi Security: $status_wifi"
log "Bluetooth Security: $status_bt"
log "Network Service Hardening: $status_net"
log "SSH & Remote Access Security: $status_ssh"
log "IPv6 Security: $status_ipv6"
log "DNS & Network Privacy: $status_dns"
log "ARP & Rogue Device Detection: $status_arp"
log "-----------------------------"
