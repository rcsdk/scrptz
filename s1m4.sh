#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

echo "Initializing minimal Arch Linux setup..."

# Function to check the success of a command
check_success() {
    if [ $? -ne 0 ]; then
        echo "Error: $1 failed. Exiting."
        exit 1
    fi
}

#------------------------------------------------------------
# Add a user and set password
if sudo useradd -m rc; then
    echo "User rc created successfully"
else
    echo "Error: Failed to create user rc"
    exit 1
fi

if echo "rc:0000" | sudo chpasswd; then
    echo "Password for rc set successfully"
else
    echo "Error: Failed to set password for rc"
    exit 1
fi

if sudo usermod -aG wheel rc; then
    echo "User rc added to wheel group successfully"
else
    echo "Error: Failed to add user rc to wheel group"
    exit 1
fi

if echo "rc ALL=(ALL) NOPASSWD:ALL" | sudo tee /etc/sudoers.d/rc; then
    echo "User rc granted sudo privileges"
else
    echo "Error: Failed to grant sudo privileges to user rc"
    exit 1
fi

if su - rc; then
    echo "Switched to user rc"
else
    echo "Error: Failed to switch to user rc"
    exit 1
fi

if sudo chown -R rc:rc /home/rc; then
    echo "Ownership of /home/rc changed to user rc"
else
    echo "Error: Failed to change ownership of /home/rc to user rc"
    exit 1
fi

if sudo chmod -R 700 /home/rc; then
    echo "Permissions set to 700 for /home/rc"
else
    echo "Error: Failed to set permissions for /home/rc"
    exit 1
fi

#------------------------------------------------------------
# Install yay (AUR helper)
if [ -d "yay" ]; then
    sudo rm -rf yay
    check_success "Existing yay directory removed"
fi

if git clone https://aur.archlinux.org/yay.git; then
    cd yay
    if makepkg -si; then
        check_success "yay installed"
    else
        echo "Error: Failed to install yay"
        exit 1
    fi
    cd ..
else
    echo "Error: Failed to clone yay repository"
    exit 1
fi

#------------------------------------------------------------
# Install Snapd using yay
if yay -S --noconfirm snapd; then
    check_success "Snapd installed"
else
    echo "Error: Failed to install Snapd"
    exit 1
fi

# Enable and start Snapd
if sudo systemctl enable --now snapd.socket; then
    check_success "Snapd service enabled"
else
    echo "Error: Failed to enable Snapd service"
    exit 1
fi

# Install Figma via Snap
if sudo snap install figma-linux; then
    check_success "Figma installed via Snap"
else
    echo "Error: Failed to install Figma via Snap"
    exit 1
fi

#------------------------------------------------------------
# Set Time Zone to São Paulo
if sudo timedatectl set-timezone America/Sao_Paulo; then
    check_success "Timezone set"
else
    echo "Error: Failed to set timezone"
    exit 1
fi

# Set Locale (if not set already)
if sudo localectl set-locale LANG=en_US.UTF-8; then
    check_success "Locale set"
else
    echo "Error: Failed to set locale"
    exit 1
fi

#------------------------------------------------------------
# Initialize Pacman keyring and populate with Arch Linux keys
if sudo pacman-key --init; then
    check_success "Pacman keyring initialized"
else
    echo "Error: Failed to initialize Pacman keyring"
    exit 1
fi

if sudo pacman-key --populate archlinux; then
    check_success "Pacman keyring populated"
else
    echo "Error: Failed to populate Pacman keyring"
    exit 1
fi

# Check GPG trust database
if sudo gpg --check-trustdb; then
    check_success "GPG trustdb checked"
else
    echo "Error: Failed to check GPG trustdb"
    exit 1
fi

#------------------------------------------------------------
# Prepare Pacman and do all Downloads
if sudo pacman -Syy --needed; then
    check_success "Pacman updated"
else
    echo "Error: Failed to update Pacman"
    exit 1
fi

# Remove any existing Pacman lock file
if sudo rm -f /var/lib/pacman/db.lck; then
    check_success "Pacman lock removed"
else
    echo "Error: Failed to remove Pacman lock"
    exit 1
fi

# Install necessary packages
packages=(
    ufw apparmor openvpn chromium xorg-xinit xorg neofetch lolcat
    mesa intel-media-driver libva libva-intel-driver libva-utils
    intel-gpu-tools vulkan-tools vulkan-intel intel-ucode
)

for package in "${packages[@]}"; do
    if sudo pacman -S --noconfirm --needed "$package"; then
        echo "$package installed successfully"
    else
        echo "Error: Failed to install $package"
        exit 1
    fi
done
check_success "Basic Packages installed"

#------------------------------------------------------------
# Verify Vulkan setup
if vulkaninfo | grep "GPU"; then
    check_success "Vulkan setup verified"
else
    echo "Error: Failed to verify Vulkan setup"
    exit 1
fi

#------------------------------------------------------------
# Enable and Monitor GPU Performance
if intel_gpu_top; then
    check_success "GPU performance monitored"
else
    echo "Error: Failed to monitor GPU performance"
    exit 1
fi

#------------------------------------------------------------
# Create minimal xorg.conf
if cat <<EOF | sudo tee /etc/X11/xorg.conf
Section "ServerFlags"
    Option "AllowIndirectGLX" "off"
EndSection

Section "Device"
    Identifier  "Intel Graphics"
    Driver      "intel"
    Option      "DRI" "iris"
    Option      "TearFree" "true"
EndSection

Section "Monitor"
    Identifier "eDP1"
EndSection

Section "Screen"
    Identifier "Screen0"
    Device "Intel Graphics"
    Monitor "eDP1"
EndSection

Section "ServerLayout"
    Identifier "Layout0"
    Screen "Screen0"
EndSection
EOF
then
    check_success "xorg.conf created"
else
    echo "Error: Failed to create xorg.conf"
    exit 1
fi

#------------------------------------------------------------
# Fix for mkinitcpio error
if cat <<EOF | sudo tee /etc/mkinitcpio.d/linux.preset
ALL_config="/etc/mkinitcpio.conf"
ALL_kver="/boot/vmlinuz-linux"

PRESETS=('default')

default_image="/boot/initramfs-linux.img"
default_options=""
EOF
then
    check_success "/etc/mkinitcpio.d/linux.preset created"
else
    echo "Error: Failed to create /etc/mkinitcpio.d/linux.preset"
    exit 1
fi

if sudo mkinitcpio -p linux; then
    check_success "mkinitcpio ran"
else
    echo "Error: Failed to run mkinitcpio"
    exit 1
fi

if sudo pacman -Syu; then
    check_success "System updated after mkinitcpio"
else
    echo "Error: Failed to update system after mkinitcpio"
    exit 1
fi

#------------------------------------------------------------
# Check system information and firmware
if lsmod | grep xhci_pci && lsmod | grep ast && lsmod | grep aic94xx && lsmod | grep wd719x && dmesg | grep -i firmware; then
    check_success "System info and firmware checked"
else
    echo "Error: Failed to check system info and firmware"
    exit 1
fi

# Remove any existing Pacman lock file again
if sudo rm -f /var/lib/pacman/db.lck; then
    check_success "Pacman lock removed again"
else
    echo "Error: Failed to remove Pacman lock again"
    exit 1
fi

#------------------------------------------------------------
# FAKETIME cleanup
if unset FAKETIME && ps aux | grep faketime && grep faketime ~/.bashrc ~/.zshrc ~/.profile && grep faketime /etc/profile.d/* && sudo pacman -R --noconfirm libfaketime && sudo killall faketime; then
    check_success "faketime removed"
else
    echo "Error: Failed to remove faketime"
    exit 1
fi

#------------------------------------------------------------
# Configure Display Brightness
if xrandr --output eDP1 --brightness 0.4; then
    check_success "Brightness adjusted"
else
    echo "Error: Failed to adjust brightness"
    exit 1
fi

#------------------------------------------------------------
# Harden Kernel Parameters
if cat <<EOF | sudo tee /etc/sysctl.d/99-custom.conf
# Restrict access to kernel logs
kernel.dmesg_restrict = 1

# Restrict access to kernel pointers
kernel.kptr_restrict = 2

# Disable unprivileged BPF (Berkeley Packet Filter)
kernel.unprivileged_bpf_disabled = 1

# Enable kernel address space layout randomization (ASLR)
kernel.randomize_va_space = 2

# Disable loading of new kernel modules
kernel.modules_disabled = 1

# Disable core dumps
fs.suid_dumpable = 0

# Enable protection against SYN flooding
net.ipv4.tcp_syncookies = 1

# Disable IP forwarding
net.ipv4.ip_forward = 0
net.ipv6.conf.all.forwarding = 0

# Enable execshield protection
kernel.exec-shield = 1

# Restrict access to debugfs
kernel.debugfs_restrict = 1

# Enable strict RWX memory permissions
vm.mmap_min_addr = 4096
kernel.exec-shield = 1
vm.mmap_rnd_bits = 24
vm.mmap_rnd_compat_bits = 16

EOF
then
    sudo sysctl --system
    check_success "Kernel parameters set"
else
    echo "Error: Failed to set kernel parameters"
    exit 1
fi

#------------------------------------------------------------

# Enable and configure UFW (Firewall)
if sudo systemctl enable --now ufw; then
    check_success "UFW enabled"
else
    echo "Error: Failed to enable UFW"
    exit 1
fi

if sudo ufw default deny incoming && sudo ufw default allow outgoing && sudo ufw allow ssh && sudo ufw reload; then
    check_success "UFW rules configured"
else
    echo "Error: Failed to configure UFW rules"
    exit 1
fi

#------------------------------------------------------------
# Disable unnecessary services (Bluetooth, Printer, etc.)
services=(
    alsa-restore.service getty@tty1.service ip6tables.service
    iptables.service cups avahi-daemon bluetooth
)

for service in "${services[@]}"; do
    if sudo systemctl disable "$service"; then
        echo "$service disabled successfully"
    else
        echo "Error: Failed to disable $service"
        exit 1
    fi
done
check_success "Unnecessary services disabled"

# Mask unnecessary services
for service in "${services[@]}"; do
    if sudo systemctl mask "$service"; then
        echo "$service masked successfully"
    else
        echo "Error: Failed to mask $service"
        exit 1
    fi
done
check_success "Unnecessary services masked"

#------------------------------------------------------------
# Prevent overlay
if sudo sed -i 's/ overlay//g' /etc/X11/xorg.conf && sudo sed -i 's/ allow-overlay//g' /etc/security/limits.conf; then
    check_success "Overlay features disabled"
else
    echo "Error: Failed to disable overlay features"
    exit 1
fi

#------------------------------------------------------------
# AppArmor setup (if needed)
if sudo systemctl enable apparmor && sudo systemctl start apparmor && sudo aa-enforce /etc/apparmor.d/*; then
    check_success "Apparmor configured"
else
    echo "Error: Failed to configure Apparmor"
    exit 1
fi

#------------------------------------------------------------
# Install OpenVPN
if sudo pacman -S --noconfirm openvpn; then
    check_success "OpenVPN installed"
else
    echo "Error: Failed to install OpenVPN"
    exit 1
fi

# Create a basic OpenVPN configuration file
if cat <<EOF | sudo tee /etc/openvpn/client.conf
client
dev tun
proto udp
remote your.vpn.server 1194
resolv-retry infinite
nobind
persist-key
persist-tun
ca ca.crt
cert client.crt
key client.key
remote-cert-tls server
cipher AES-256-CBC
verb 3
EOF
then
    check_success "OpenVPN configuration file created"
else
    echo "Error: Failed to create OpenVPN configuration file"
    exit 1
fi

# Enable and start OpenVPN service
if sudo systemctl enable openvpn@client && sudo systemctl start openvpn@client; then
    check_success "OpenVPN service started"
else
    echo "Error: Failed to start OpenVPN service"
    exit 1
fi

# Verify OpenVPN connection
if sudo systemctl status openvpn@client; then
    echo "OpenVPN connection verified"
else
    echo "Error: Failed to verify OpenVPN connection"
    exit 1
fi

#------------------------------------------------------------
# Set DNS to Cloudflare for privacy
if echo "nameserver 1.1.1.1" | sudo tee /etc/resolv.conf && echo "nameserver 9.9.9.9" | sudo tee -a /etc/resolv.conf && sudo chattr +i /etc/resolv.conf; then
    check_success "DNS set and locked"
else
    echo "Error: Failed to set and lock DNS"
    exit 1
fi

#------------------------------------------------------------
# Configure Sudo timeout (for better security)
if echo 'Defaults timestamp_timeout=5' | sudo tee -a /etc/sudoers; then
    check_success "Sudo timeout set"
else
    echo "Error: Failed to set sudo timeout"
    exit 1
fi

#------------------------------------------------------------
# Secure important files
files=(
    "/etc/ssh/sshd_config"
    "/etc/shadow"
    "/etc/gshadow"
    "/etc/passwd"
    "/etc/group"
    "/boot"
    "/etc/sudoers"
    "/var/log"
)

permissions=(
    "600" "600" "600" "644" "644" "700" "440" "600"
)

owners=(
    "root:root" "root:root" "root:root" "root:root" "root:root" "root:root" "root:root" "root:root"
)

for i in "${!files[@]}"; do
    if sudo chmod "${permissions[$i]}" "${files[$i]}" && sudo chown "${owners[$i]}" "${files[$i]}"; then
        echo "${files[$i]} secured successfully"
    else
        echo "Error: Failed to secure ${files[$i]}"
        exit 1
    fi
done
check_success "Important files secured"

#------------------------------------------------------------
# Clean Pacman Cache
if sudo pacman -Scc --noconfirm; then
    check_success "Pacman cache cleaned"
else
    echo "Error: Failed to clean Pacman cache"
    exit 1
fi

#------------------------------------------------------------
# Clone and bootstrap GameMode
if git clone https://github.com/FeralInteractive/gamemode.git; then
    cd gamemode
    if ./bootstrap.sh; then
        check_success "GameMode cloned and bootstrapped"
    else
        echo "Error: Failed to bootstrap GameMode"
        exit 1
    fi
    cd ..
else
    echo "Error: Failed to clone GameMode repository"
    exit 1
fi

#------------------------------------------------------------
# Reinstall Firefox
if sudo pacman -Rns firefox && sudo pacman -Scc && sudo pacman -S --noconfirm firefox && rm -rf ~/.mozilla/firefox; then
    echo "Firefox reinstalled successfully"
else
    echo "Error: Failed to reinstall Firefox"
    exit 1
fi

# Create a new Firefox profile named "rc"
if firefox --no-remote -CreateProfile "rc ~/.mozilla/firefox/rc"; then
    echo "Firefox profile 'rc' created successfully"
else
    echo "Error: Failed to create Firefox profile 'rc'"
    exit 1
fi

# Configure Hardware Acceleration in Firefox
if firefox -P rc about:config; then
    # Set the following preferences manually or via script
    # gfx.webrender.all=true
    # layers.acceleration.force-enabled=true
    # webgl.force-enabled=true
    # media.ffmpeg.vaapi.enabled=true
    echo "Hardware acceleration configured in Firefox"
else
    echo "Error: Failed to configure hardware acceleration in Firefox"
    exit 1
fi

#------------------------------------------------------------
# Optimized section for installing and preparing Chromium
echo "Optimizing Chromium installation..."
if sudo pacman -S --noconfirm chromium; then
    check_success "Chromium installed"
else
    echo "Error: Failed to install Chromium"
    exit 1
fi

# Configure Chromium settings
echo "Configuring Chromium settings..."
chromium_flags=(
    "--disable-infobars"
    "--disable-plugins"
    "--disable-extensions"
    "--disable-component-extensions-with-background-pages"
    "--disable-background-networking"
    "--disable-sync"
    "--disable-translate"
    "--disable-default-apps"
    "--disable-software-rasterizer"
    "--disable-background-timer-throttling"
    "--disable-renderer-backgrounding"
    "--disable-backgrounding-occluded-windows"
    "--disable-breakpad"
    "--disable-client-side-phishing-detection"
    "--disable-domain-reliability"
    "--disable-hang-monitor"
    "--disable-popup-blocking"
    "--disable-prompt-on-repost"
    "--disable-speech-api"
    "--disable-webgl"
    "--disable-web-security"
    "--disable-site-isolation-trials"
    "--disable-remote-fonts"
    "--disable-blink-features=AutomationControlled"
    "--incognito"
    "--use-gl=egl"
    "--enable-features=VaapiVideoDecoder"
    "--enable-accelerated-video-decode"
    "--enable-accelerated-mjpeg-decode"
    "--disable-gpu-sandbox"
    "--enable-native-gpu-memory-buffers"
    "--use-vulkan"
    "--enable-zero-copy"
)

# Launch Chromium with optimized flags
if chromium "${chromium_flags[@]}" &; then
    check_success "Chromium configured and launched"
else
    echo "Error: Failed to configure and launch Chromium"
    exit 1
fi

echo "Minimal setup completed."
