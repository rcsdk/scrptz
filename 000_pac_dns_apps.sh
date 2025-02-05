#!/bin/bash

# Define the directory to store downloaded packages
LOCAL_REPO="/mnt/1/apps"
mkdir -p "$LOCAL_REPO"

# Define the list of packages to install
PACKAGES=(
    warp-terminal
    alacritty
    kitty
    firefox
    nemo
    dolphin
    ranger
    stacer
    gnome-system-monitor
    ksysguard
    bashtop
    plank
    conky
    variety
    timeshift
    syncthing
    arc-gtk-theme
    rofi
    picom
)

# Function to check if a package is installed
is_installed() {
    pacman -Q $1 &>/dev/null
}

# Pacman security cleanup
echo "Cleaning pacman cache..."
rm -f /var/lib/pacman/db.lck
pacman -Scc --noconfirm
echo "Reinitializing pacman keys..."
pacman-key --init
pacman-key --populate archlinux
echo "Removing compromised pacman sync directories..."
rm -rf /var/lib/pacman/sync/*
echo "Synchronizing pacman databases..."
pacman -Sy --noconfirm pacman

# Secure DNS setup
echo "Updating and securing DNS..."
if lsattr /etc/resolv.conf | grep -q "i"; then
    echo "Removing immutable flag from resolv.conf..."
    chattr -i /etc/resolv.conf
fi

echo -e "nameserver 1.1.1.1\nnameserver 8.8.8.8\nnameserver 8.8.4.4" > /etc/resolv.conf
chattr +i /etc/resolv.conf
echo "DNS secured and locked."

# Update system and install packages from local repo if available
rm -f /var/lib/pacman/db.lck
sudo pacman -Syu --noconfirm --needed

for pkg in "${PACKAGES[@]}"; do
    if is_installed "$pkg"; then
        echo "$pkg is already installed. Skipping..."
    else
        echo "Downloading $pkg..."
        sudo pacman -Sw --cachedir "$LOCAL_REPO" --noconfirm --needed "$pkg"
        echo "Installing $pkg..."
        sudo pacman -U --noconfirm "$LOCAL_REPO"/*.pkg.tar.zst
    fi
done

# Enable necessary services
sudo systemctl enable --now syncthing.service

# Backup script placeholder
BACKUP_SCRIPT="/usr/local/bin/system_backup.sh"
echo "Creating backup script at $BACKUP_SCRIPT..."
cat <<EOL | sudo tee "$BACKUP_SCRIPT"
#!/bin/bash

echo "Starting system backup with Timeshift..."
sudo timeshift --create --comments "Automated Backup" --tags D
EOL

sudo chmod +x "$BACKUP_SCRIPT"

# Finish
echo "All selected applications installed successfully!"












#!/bin/bash

# Define the directory to store downloaded packages
LOCAL_REPO="/mnt/1/apps"
mkdir -p "$LOCAL_REPO"

# Define the list of packages to install
PACKAGES=(
    warp-terminal
    alacritty
    kitty
    firefox
    nemo
    dolphin
    ranger
    stacer
    gnome-system-monitor
    ksysguard
    bashtop
    plank
    conky
    variety
    timeshift
    syncthing
    arc-gtk-theme
    rofi
    picom
)

# Function to check if a package is installed
is_installed() {
    pacman -Q $1 &>/dev/null
}

# Pacman security cleanup
echo "Cleaning pacman cache..."
pacman -Scc --noconfirm
echo "Reinitializing pacman keys..."
pacman-key --init
pacman-key --populate archlinux
echo "Removing compromised pacman sync directories..."
rm -rf /var/lib/pacman/sync/*
echo "Synchronizing pacman databases..."
pacman -Sy --noconfirm pacman

# Secure DNS setup
echo "Updating and securing DNS..."
if lsattr /etc/resolv.conf | grep -q "i"; then
    echo "Removing immutable flag from resolv.conf..."
    chattr -i /etc/resolv.conf
fi

echo -e "nameserver 1.1.1.1\nnameserver 8.8.8.8\nnameserver 8.8.4.4" > /etc/resolv.conf
chattr +i /etc/resolv.conf
echo "DNS secured and locked."

# Update system and install packages from local repo if available
sudo pacman -Syu --noconfirm --needed

for pkg in "${PACKAGES[@]}"; do
    if is_installed "$pkg"; then
        echo "$pkg is already installed. Skipping..."
    else
        echo "Downloading $pkg..."
        sudo pacman -Sw --cachedir "$LOCAL_REPO" --noconfirm --needed "$pkg"
        echo "Installing $pkg..."
        sudo pacman -U --noconfirm "$LOCAL_REPO"/*.pkg.tar.zst
    fi
done

# Enable necessary services
sudo systemctl enable --now syncthing.service

# Backup script placeholder
BACKUP_SCRIPT="/usr/local/bin/system_backup.sh"
echo "Creating backup script at $BACKUP_SCRIPT..."
cat <<EOL | sudo tee "$BACKUP_SCRIPT"
#!/bin/bash

echo "Starting system backup with Timeshift..."
sudo timeshift --create --comments "Automated Backup" --tags D
EOL

sudo chmod +x "$BACKUP_SCRIPT"

# Finish
echo "All selected applications installed successfully!"
















ok so i need to solve this - and i like the folders idea, how do i implement?  
dns and pacman scripts were the ones I was using to bypass malware - 

this folders:
/mnt/1/
├── apps/
│   ├── cache/          # Pacman cache directory
│   └── packages/       # Local package storage
├── scripts/
│   ├── arch-install.sh # Main installer script
│   └── backup.sh       # Backup configuration script
└── config/
    └── packages.list   # Package definitions
    
------------
    
I need to fix this and was discussing: 
    
-Ssyu - is 800Gb - really necessary?
ChatGPT said:
ChatGPT

If your system upgrade (-Syu) is downloading 800GB, that's definitely not normal. A full Arch Linux system with most applications should not exceed a few GBs at most. Here’s what could be causing the issue:

    Local Repository (/mnt/1/apps) Issue:
        If you're caching too many packages and versions, it could be using a large amount of space. Try cleaning it out:

    rm -rf /mnt/1/apps/*

Pacman Database Corruption:

    Your pacman database might be corrupt or bloated. Try this before running pacman -Syu again:

    pacman -Scc --noconfirm
    rm -rf /var/lib/pacman/sync/*
    pacman -Sy --noconfirm

Mirrors Downloading Excessive Data:

    Your mirrorlist may be pointing to a faulty or overloaded mirror. Try refreshing mirrors:

    reflector --latest 10 --protocol https --sort rate --save /etc/pacman.d/mirrorlist
    pacman -Syyu

Check Disk Usage:

    Run this to see what's using the space:

du -sh /var/cache/pacman/pkg


------------



#!/bin/bash

# Define the directory to store downloaded packages
LOCAL_REPO="/mnt/1/apps"
mkdir -p "$LOCAL_REPO"

# Define the list of packages to install
PACKAGES=(
    warp-terminal
    alacritty
    kitty
    firefox
    nemo
    dolphin
    ranger
    stacer
    gnome-system-monitor
    ksysguard
    bashtop
    plank
    conky
    variety
    timeshift
    syncthing
    arc-gtk-theme
    rofi
    picom
)

# Function to check if a package is installed
is_installed() {
    pacman -Q $1 &>/dev/null
}

# Pacman security cleanup
echo "Cleaning pacman cache..."
pacman -Scc --noconfirm
echo "Reinitializing pacman keys..."
pacman-key --init
pacman-key --populate archlinux
echo "Removing compromised pacman sync directories..."
rm -rf /var/lib/pacman/sync/*
echo "Synchronizing pacman databases..."
pacman -Sy --noconfirm pacman

# Secure DNS setup
echo "Updating and securing DNS..."
if lsattr /etc/resolv.conf | grep -q "i"; then
    echo "Removing immutable flag from resolv.conf..."
    chattr -i /etc/resolv.conf
fi

echo -e "nameserver 1.1.1.1\nnameserver 8.8.8.8\nnameserver 8.8.4.4" > /etc/resolv.conf
chattr +i /etc/resolv.conf
echo "DNS secured and locked."

# Update system and install packages from local repo if available
sudo pacman -Syu --noconfirm --needed

for pkg in "${PACKAGES[@]}"; do
    if is_installed "$pkg"; then
        echo "$pkg is already installed. Skipping..."
    else
        echo "Downloading $pkg..."
        sudo pacman -Sw --cachedir "$LOCAL_REPO" --noconfirm --needed "$pkg"
        echo "Installing $pkg..."
        sudo pacman -U --noconfirm "$LOCAL_REPO"/*.pkg.tar.zst
    fi
done

# Enable necessary services
sudo systemctl enable --now syncthing.service

# Backup script placeholder
BACKUP_SCRIPT="/usr/local/bin/system_backup.sh"
echo "Creating backup script at $BACKUP_SCRIPT..."
cat <<EOL | sudo tee "$BACKUP_SCRIPT"
#!/bin/bash

echo "Starting system backup with Timeshift..."
sudo timeshift --create --comments "Automated Backup" --tags D
EOL

sudo chmod +x "$BACKUP_SCRIPT"

# Finish
echo "All selected applications installed successfully!"




ok so i need to solve this - and i like the folders idea, how do i implement?  


this folders:
/mnt/1/
├── apps/
│   ├── cache/          # Pacman cache directory
│   └── packages/       # Local package storage
├── scripts/
│   ├── arch-install.sh # Main installer script
│   └── backup.sh       # Backup configuration script
└── config/
    └── packages.list   # Package definitions
    
------------
    
I need to fix this and was discussing: 
    
-Ssyu - is 800Gb - really necessary?
ChatGPT said:
ChatGPT

If your system upgrade (-Syu) is downloading 800GB, that's definitely not normal. A full Arch Linux system with most applications should not exceed a few GBs at most. Here’s what could be causing the issue:

    Local Repository (/mnt/1/apps) Issue:
        If you're caching too many packages and versions, it could be using a large amount of space. Try cleaning it out:

    rm -rf /mnt/1/apps/*

Pacman Database Corruption:

    Your pacman database might be corrupt or bloated. Try this before running pacman -Syu again:

    pacman -Scc --noconfirm
    rm -rf /var/lib/pacman/sync/*
    pacman -Sy --noconfirm

Mirrors Downloading Excessive Data:

    Your mirrorlist may be pointing to a faulty or overloaded mirror. Try refreshing mirrors:

    reflector --latest 10 --protocol https --sort rate --save /etc/pacman.d/mirrorlist
    pacman -Syyu

Check Disk Usage:

    Run this to see what's using the space:

du -sh /var/cache/pacman/pkg


------------



#!/bin/bash

# Define the directory to store downloaded packages
LOCAL_REPO="/mnt/1/apps"
mkdir -p "$LOCAL_REPO"

# Define the list of packages to install
PACKAGES=(
    warp-terminal
    alacritty
    kitty
    firefox
    nemo
    dolphin
    ranger
    stacer
    gnome-system-monitor
    ksysguard
    bashtop
    plank
    conky
    variety
    timeshift
    syncthing
    arc-gtk-theme
    rofi
    picom
)

# Function to check if a package is installed
is_installed() {
    pacman -Q $1 &>/dev/null
}

# Pacman security cleanup
echo "Cleaning pacman cache..."
pacman -Scc --noconfirm
echo "Reinitializing pacman keys..."
pacman-key --init
pacman-key --populate archlinux
echo "Removing compromised pacman sync directories..."
rm -rf /var/lib/pacman/sync/*
echo "Synchronizing pacman databases..."
pacman -Sy --noconfirm pacman

# Secure DNS setup
echo "Updating and securing DNS..."
if lsattr /etc/resolv.conf | grep -q "i"; then
    echo "Removing immutable flag from resolv.conf..."
    chattr -i /etc/resolv.conf
fi

echo -e "nameserver 1.1.1.1\nnameserver 8.8.8.8\nnameserver 8.8.4.4" > /etc/resolv.conf
chattr +i /etc/resolv.conf
echo "DNS secured and locked."

# Update system and install packages from local repo if available
sudo pacman -Syu --noconfirm --needed

for pkg in "${PACKAGES[@]}"; do
    if is_installed "$pkg"; then
        echo "$pkg is already installed. Skipping..."
    else
        echo "Downloading $pkg..."
        sudo pacman -Sw --cachedir "$LOCAL_REPO" --noconfirm --needed "$pkg"
        echo "Installing $pkg..."
        sudo pacman -U --noconfirm "$LOCAL_REPO"/*.pkg.tar.zst
    fi
done

# Enable necessary services
sudo systemctl enable --now syncthing.service

# Backup script placeholder
BACKUP_SCRIPT="/usr/local/bin/system_backup.sh"
echo "Creating backup script at $BACKUP_SCRIPT..."
cat <<EOL | sudo tee "$BACKUP_SCRIPT"
#!/bin/bash

echo "Starting system backup with Timeshift..."
sudo timeshift --create --comments "Automated Backup" --tags D
EOL

sudo chmod +x "$BACKUP_SCRIPT"

# Finish
echo "All selected applications installed successfully!"


#!/bin/bash

# Exit immediately if a command fails
set -e

# Check if the script is running as root
if [[ $EUID -ne 0 ]]; then
    echo "This script must be run as root" 1>&2
    exit 1
fi

# Clean pacman cache to clear out corrupted DB files
echo "Cleaning pacman cache..."
pacman -Scc --noconfirm

# Reinitialize pacman keys (resets pacman keyring)
echo "Reinitializing pacman keys..."
pacman-key --init
pacman-key --populate archlinux

# Delete any pacman sync cache to get fresh copies of databases
echo "Removing compromised pacman sync directories..."
rm -rf /var/lib/pacman/sync/*

# Update pacman database and install latest pacman version
echo "Synchronizing pacman databases..."
pacman -Sy --noconfirm pacman

# Change DNS to secure DNS (Google and Cloudflare DNS as backup)
echo "Changing DNS configuration..."
cat <<EOF > /etc/resolv.conf
# DNS Servers
nameserver 1.1.1.1   # Cloudflare DNS
nameserver 8.8.8.8   # Google DNS
nameserver 8.8.4.4   # Google DNS
EOF

# Lock DNS configuration to prevent further tampering
echo "Locking DNS configuration..."
chattr +i /etc/resolv.conf

# Confirm that DNS is correctly configured
echo "Checking DNS resolution..."
dig google.com +short

# Notify user of completion
echo "Pacman repair and DNS configuration complete. DNS is now locked and protected."












