

chmod +x hardware_report.sh
./hardware_report.sh > hardware_report.txt







#!/bin/bash

echo "=== System Overview ==="
uname -a && lscpu && free -h && lsb_release -a
echo -e "\n=== Storage Information ==="
lsblk -o NAME,SIZE,TYPE,MOUNTPOINT,FSTYPE
smartctl --all /dev/sda 2>/dev/null
echo -e "\n=== Graphics Information ==="
lspci -nnk | grep -A3 -E "VGA|3D"
glxinfo | grep "OpenGL"
echo -e "\n=== Network Information ==="
ip a
nmcli device show
ethtool eth0 2>/dev/null
echo -e "\n=== PCI Devices ==="
lspci -v
echo -e "\n=== USB Devices ==="
lsusb -v
echo -e "\n=== BIOS and Firmware ==="
dmidecode
echo -e "\n=== Power Management and Battery ==="
upower -i /org/freedesktop/UPower/devices/battery_BAT0
echo -e "\n=== Thermal and Sensor Information ==="
sensors
echo -e "\n=== Audio Devices ==="
aplay -l
arecord -l
echo -e "\n=== Active Connections ==="
ss -tuln
echo -e "\n=== Kernel Modules ==="
lsmod
echo -e "\n=== Fan and Thermal Settings ==="
pwmconfig 2>/dev/null
