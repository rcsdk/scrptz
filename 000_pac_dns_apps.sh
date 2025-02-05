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
