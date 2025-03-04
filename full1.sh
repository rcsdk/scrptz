#!/bin/bash

# Run in RAM, log everything
set -e
exec > >(tee -a /tmp/boot_security_log.txt) 2>&1
echo "[*] Boot security sweep started: $(date)"

# --- LAN-Only ---
echo "[*] Forcing wired-only mode..."
nmcli radio wifi off
rfkill block wifi
ip link set wlan0 down 2>/dev/null || echo "No wlan0 found."
rfkill block bluetooth

# Verify eth0
echo "[*] Checking network interfaces..."
ip a | grep eth0 || echo "[!] eth0 not found—check cable!"
if ip a | grep eth0 | grep -q "UP"; then
    echo "[*] eth0 is UP."
    nmcli con up "wired-ceo" 2>/dev/null || nmcli con add type ethernet ifname eth0 con-name "wired-ceo" autoconnect yes
else
    echo "[!] eth0 DOWN—exiting."
    exit 1
fi
ping -c 5 1.1.1.1 || echo "[!] No internet—check LAN!"

# --- Check Rogues ---
echo "[*] Scanning ARP table..."
apt install -y arp-scan
arp-scan -l -I eth0 > /tmp/arp_scan.txt
grep -v "192.168.15.1" /tmp/arp_scan.txt && echo "[!] Unexpected devices found!"

echo "[*] Checking traffic..."
tcpdump -i eth0 -n -c 1000 > /tmp/traffic.log 2>/dev/null &
TCPDUMP_PID=$!
sleep 10
kill $TCPDUMP_PID
grep -v "192.168.15.1\|1.1.1.1\|9.9.9.9\|8.8.8.8" /tmp/traffic.log > /tmp/suspicious.log
[ -s /tmp/suspicious.log ] && echo "[!] Suspicious traffic detected!"

# --- Kill & Clean ---
echo "[*] Killing rogue processes..."
pkill -f "nc\|netcat\|bash\|python\|perl" 2>/dev/null || echo "No rogue processes found."
rm -rf /tmp/* /var/tmp/* 2>/dev/null

# --- Install Tools (No OSSEC) ---
echo "[*] Updating package lists..."
apt update -y

echo "[*] Installing Wireshark & tcpdump..."
apt install -y wireshark tcpdump
echo "wireshark-common wireshark-common/install-setuid boolean true" | debconf-set-selections
dpkg-reconfigure -f noninteractive wireshark-common
usermod -a -G wireshark demo

echo "[*] Installing Fail2Ban..."
apt install -y fail2ban
cat << EOF > /etc/fail2ban/jail.local
[DEFAULT]
bantime = 3600
maxretry = 5
[sshd]
enabled = true
port = ssh
filter = sshd
logpath = /var/log/auth.log
EOF
service fail2ban start || echo "[!] Fail2Ban start failed!"
update-rc.d fail2ban defaults

# --- Verify & Lock ---
echo "[*] Verifying tools..."
wireshark --version || echo "[!] Wireshark failed."
tcpdump --version || echo "[!] tcpdump failed."
[ -f /var/ossec/bin/ossec-control ] && /var/ossec/bin/ossec-control status || echo "[!] OSSEC not installed yet."
fail2ban-client status sshd || echo "[!] Fail2Ban SSH not active."

echo "[*] Running OSSEC scan (if installed)..."
[ -f /var/ossec/bin/ossec-syscheckd ] && /var/ossec/bin/ossec-syscheckd 2>/dev/null || echo "[!] OSSEC not installed—skipping scan."
[ -f /var/ossec/logs/alerts/alerts.log ] && tail -n 20 /var/ossec/logs/alerts/alerts.log > /tmp/ossec_alerts.txt

echo "[*] Setting hostname..."
echo "ceo-secure" > /etc/hostname
hostname ceo-secure
nmcli general hostname ceo-secure

echo "[*] Securing DNS..."
echo -e "nameserver 1.1.1.1\nnameserver 9.9.9.9\nnameserver 8.8.8.8" > /etc/resolv.conf
chattr +i /etc/resolv.conf

# --- Final Clean ---
rm -rf /tmp/* /var/tmp/* 2>/dev/null

echo "[*] Sweep complete: $(date)"
echo "Check /tmp/boot_security_log.txt, /tmp/suspicious.log, /tmp/ossec_alerts.txt."
