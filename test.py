#!/usr/bin/env python3

from scapy.all import sniff, Dot11, Dot11Elt, RadioTap, Raw
import logging
import os
import sys

# ----- CONFIGURATION -----
LOG_FILE = "/tmp/scapy_test.log"

logging.basicConfig(
    level=logging.DEBUG,
    format="%(asctime)s [%(levelname)s] %(message)s",
    handlers=[logging.FileHandler(LOG_FILE), logging.StreamHandler()],
)


def check_root():
    """Ensure the script is run as root."""
    if os.geteuid() != 0:
        logging.error("This script must be run as root.")
        sys.exit(1)


def packet_handler(packet):
    """Handle and log all captured packets."""
    try:
        # Log raw packet
        logging.debug("Raw packet captured: %s", packet.summary())

        # Wi-Fi Beacon Frames (802.11)
        if packet.haslayer(Dot11) and packet.type == 0 and packet.subtype == 8:
            ssid = packet[Dot11Elt].info.decode(errors="ignore") if packet[Dot11Elt].info else "[HIDDEN]"
            bssid = packet[Dot11].addr2
            channel = get_channel(packet)
            logging.info(f"Wi-Fi Beacon: SSID={ssid}, BSSID={bssid}, Channel={channel}")

        # Deauthentication Frames
        elif packet.haslayer(Dot11) and packet.type == 0 and packet.subtype == 12:
            logging.info(f"Deauth Packet: Source={packet.addr2}, Target={packet.addr1}")

        # Capture raw data payloads
        elif packet.haslayer(Raw):
            logging.debug(f"Raw Payload: {packet[Raw].load}")

    except Exception as e:
        logging.error(f"Error processing packet: {e}")


def get_channel(packet):
    """Extract the channel from the Dot11Elt layer, if available."""
    try:
        if packet.haslayer(Dot11Elt):
            elements = packet[Dot11Elt]
            while elements:
                if elements.ID == 3:  # Channel ID is 3
                    return ord(elements.info)
                elements = elements.payload
    except Exception:
        pass
    return "Unknown"


def run_sniffer(interface):
    """Start Scapy sniffer on specified interface."""
    logging.info(f"Starting Scapy sniffer on interface: {interface}")
    try:
        sniff(iface=interface, prn=packet_handler, timeout=30, store=False)
    except Exception as e:
        logging.error(f"Sniffer error: {e}")
        sys.exit(1)


def main():
    check_root()

    interface = input("Enter your Wi-Fi interface (e.g., wlan0): ").strip()
    if not os.path.exists(f"/sys/class/net/{interface}"):
        logging.error(f"Invalid interface: {interface}")
        sys.exit(1)

    logging.info(f"Testing Scapy sniffing on interface: {interface}")
    run_sniffer(interface)

    logging.info(f"Scapy test complete. Logs saved to {LOG_FILE}.")


if __name__ == "__main__":
    main()
