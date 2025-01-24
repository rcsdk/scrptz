Got it! You want to have the installation files for all the tools stored locally in your /tools folder, so you can use them even if the internet is unavailable. This is an excellent idea for self-sufficiency in recovery scenarios. Here's how you can set it up.


---

Step-by-Step Plan

1. Download Installation Files:

You'll download .tar.zst, .tar.gz, or other compressed files for the tools and store them in your /tools folder.



2. Prepare a Script for Local Installation:

The script will install these tools from your local folder without requiring an internet connection.



3. Organize the Tools:

Store each tool's archive in a well-organized folder inside /tools.





---

Script to Download and Store Tools Locally

Save the following script as download_tools.sh:

#!/bin/bash

# Define the tools and their download URLs
declare -A TOOLS
TOOLS=(
    # System Recovery & Diagnostics
    ["testdisk"]="https://archlinux.org/packages/extra/x86_64/testdisk/download/"
    ["parted"]="https://archlinux.org/packages/extra/x86_64/parted/download/"
    ["gparted"]="https://archlinux.org/packages/community/x86_64/gparted/download/"
    ["memtest86+"]="https://archlinux.org/packages/community/x86_64/memtest86+/download/"
    ["smartmontools"]="https://archlinux.org/packages/extra/x86_64/smartmontools/download/"
    ["clonezilla"]="https://sourceforge.net/projects/clonezilla/files/latest/download"

    # Networking Tools
    ["nmap"]="https://archlinux.org/packages/community/x86_64/nmap/download/"
    ["wireshark-gtk"]="https://archlinux.org/packages/community/x86_64/wireshark-gtk/download/"
    ["gnu-netcat"]="https://archlinux.org/packages/community/x86_64/gnu-netcat/download/"
    ["curl"]="https://archlinux.org/packages/core/x86_64/curl/download/"
    ["inetutils"]="https://archlinux.org/packages/core/x86_64/inetutils/download/"

    # Penetration Testing & Security Tools
    ["hydra"]="https://archlinux.org/packages/community/x86_64/hydra/download/"
    ["john"]="https://archlinux.org/packages/community/x86_64/john/download/"
    ["aircrack-ng"]="https://archlinux.org/packages/community/x86_64/aircrack-ng/download/"
    ["metasploit"]="https://archlinux.org/packages/community/x86_64/metasploit/download/"

    # Disk Encryption & Password Tools
    ["cryptsetup"]="https://archlinux.org/packages/core/x86_64/cryptsetup/download/"
    ["keepassxc"]="https://archlinux.org/packages/community/x86_64/keepassxc/download/"
    ["hashcat"]="https://archlinux.org/packages/community/x86_64/hashcat/download/"

    # File Management & Backup Tools
    ["rsync"]="https://archlinux.org/packages/extra/x86_64/rsync/download/"
    ["tar"]="https://archlinux.org/packages/core/x86_64/tar/download/"
    ["p7zip"]="https://archlinux.org/packages/community/x86_64/p7zip/download/"

    # System Monitoring Tools
    ["htop"]="https://archlinux.org/packages/extra/x86_64/htop/download/"
    ["iotop"]="https://archlinux.org/packages/community/x86_64/iotop/download/"
    ["nmon"]="https://archlinux.org/packages/community/x86_64/nmon/download/"
    ["sysstat"]="https://archlinux.org/packages/community/x86_64/sysstat/download/"

    # Disk Recovery & Forensics
    ["sleuthkit"]="https://archlinux.org/packages/community/x86_64/sleuthkit/download/"
    ["foremost"]="https://archlinux.org/packages/community/x86_64/foremost/download/"
)

# Create a tools directory
mkdir -p /tools
cd /tools

# Download each tool
for tool in "${!TOOLS[@]}"; do
    echo "Downloading $tool..."
    curl -L -o "$tool.tar.zst" "${TOOLS[$tool]}"
done

echo "All tools downloaded to /tools!"


---

Offline Installation Script

Save this as install_tools_offline.sh:

#!/bin/bash

# Path to the tools folder
TOOLS_DIR="/tools"

# Check if tools folder exists
if [ ! -d "$TOOLS_DIR" ]; then
    echo "Tools folder not found! Make sure /tools exists."
    exit 1
fi

# Install each tool from the local folder
for package in "$TOOLS_DIR"/*.tar.zst; do
    echo "Installing $(basename $package)..."
    sudo pacman -U $package --noconfirm
done

echo "All tools installed from local files!"


---

How to Use

1. Download Tools:

Run the download_tools.sh script on a working system with internet access:

chmod +x download_tools.sh
./download_tools.sh

This will download all tool packages into /tools.



2. Use Offline:

Copy the /tools folder to the second partition of your USB stick.

When you need to install the tools offline, run the install_tools_offline.sh script:

chmod +x install_tools_offline.sh
./install_tools_offline.sh





---

Why This is Useful

You don’t need an internet connection to install the tools in a recovery scenario.

The tools are readily available in the /tools folder.

You can update the tools periodically by re-running download_tools.sh.


Does this approach work for your needs?

