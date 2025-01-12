#!/bin/bash

echo "Initializing minimal Arch Linux setup..."

# Check the system specs
inxi -Fxz

# Set Time Zone to São Paulo
sudo timedatectl set-timezone America/Sao_Paulo

# Set Locale (if not set already)
sudo localectl set-locale LANG=en_US.UTF-8

pacman-key --init
gpg --check-trustdb
pacman -Syy
pacman -Syu
pacman -Sy

sudo rm -f /var/lib/pacman/db.lck
pacman -S --noconfirm ufw
pacman -S --noconfirm apparmor
pacman -S --noconfirm openvpn
pacman -S --noconfirm chromium 
pacman -S --noconfirm xorg-xinit
pacman -S --noconfirm xorg

sudo mkinitcpio -p linux
sudo pacman -Syu
lsmod | grep xhci_pci
lsmod | grep ast
lsmod | grep aic94xx
lsmod | grep wd719x
dmesg | grep -i firmware
sleep 1


sudo rm -f /var/lib/pacman/db.lck

echo $FAKETIME
unset FAKETIME
ps aux | grep faketime
grep faketime ~/.bashrc ~/.zshrc ~/.profile
grep faketime /etc/profile.d/*
kill -9 9394 9400
grep faketime ~/.bashrc ~/.zshrc /etc/profile /etc/profile.d/*
sudo pacman -R libfaketime
sudo killall faketime


# Add a user and set password
sudo useradd -m rc
echo "rc:0000" | sudo chpasswd
sudo usermod -aG wheel rc

# Update system and configure mirrors
sudo pacman -Syu --noconfirm
sudo pacman -S --noconfirm reflector
sudo reflector --country 'United States' --latest 10 --sort rate --save /etc/pacman.d/mirrorlist

# Install basic tools
sudo pacman -S --noconfirm xorg xorg-xinit chromium mesa intel-media-driver ufw

# Disable Touchpad
synclient TouchpadOff=1

# Configure Display Brightness
xrandr --output eDP1 --brightness 0.4

# Harden Kernel Parameters
cat <<EOF | sudo tee /etc/sysctl.d/99-custom.conf
kernel.dmesg_restrict = 1
kernel.kptr_restrict = 2
EOF
sudo sysctl --system

# Enable and configure UFW (Firewall)
sudo systemctl enable --now ufw
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow ssh
sudo ufw reload

# Disable unnecessary services (Bluetooth, Printer, etc.)
sudo systemctl disable alsa-restore.service
sudo systemctl disable getty@tty1.service
sudo systemctl disable ip6tables.service
sudo systemctl disable iptables.service
sudo systemctl disable cups
sudo systemctl disable avahi-daemon
sudo systemctl disable bluetooth

# Mask unnecessary services
sudo systemctl mask alsa-restore.service
sudo systemctl mask getty@tty1.service
sudo systemctl mask ip6tables.service
sudo systemctl mask iptables.service
sudo systemctl mask cups
sudo systemctl mask avahi-daemon
sudo systemctl mask bluetooth

# Prevent overlay
sudo sed -i 's/ overlay//g' /etc/X11/xorg.conf
sudo sed -i 's/ allow-overlay//g' /etc/security/limits.conf

# AppArmor setup (if needed)
sudo systemctl enable apparmor
sudo systemctl start apparmor
sudo aa-enforce /etc/apparmor.d/*

# Set DNS to Cloudflare for privacy
echo "nameserver 1.1.1.1" | sudo tee /etc/resolv.conf
echo "nameserver 9.9.9.9" | sudo tee -a /etc/resolv.conf
sudo chattr +i /etc/resolv.conf

# Configure Sudo timeout (for better security)
echo 'Defaults timestamp_timeout=5' | sudo tee -a /etc/sudoers

# Secure important files
sudo chmod 600 /etc/ssh/sshd_config  # Secure SSH config if using SSH

# Clean Pacman Cache
sudo pacman -Scc --noconfirm


# Enable automatic updates (via `pacman` or `systemd`)
echo "[Timer]" | sudo tee /etc/systemd/system/pacman-updates.timer
echo "OnBootSec=10min" | sudo tee -a /etc/systemd/system/pacman-updates.timer
echo "OnUnitActiveSec=1d" | sudo tee -a /etc/systemd/system/pacman-updates.timer
echo "[Service]" | sudo tee -a /etc/systemd/system/pacman-updates.service
echo "ExecStart=/usr/bin/pacman -Syu --noconfirm" | sudo tee -a /etc/systemd/system/pacman-updates.service
sudo systemctl enable pacman-updates.timer


# Figma hooking with local fonts
curl -L https://raw.githubusercontent.com/Figma-Linux/figma-linux-font-helper/master/res/install.sh | bash
# nano ~/.config/figma-linux/settings.json
systemctl --user restart figma-fonthelper.service
#
systemctl --user status figma-fonthelper.service


chromium --new-window --incognito "https://github.com/login"


echo "Minimal setup completed."



# END OF THE SCRIPTn-Always under development - 
# Below things I still do manually and ideas for next steps
#
#
#
#
#








# Edit pacman
nano /etc/pacman.conf

nano /etc/pacman.d/mirrorlist

sudo pacman -S reflector
sudo reflector --country 'United States' --latest 10 --sort rate --save /etc/pacman.d/mirrorlist

# Edit Sysctl
sudo nano /etc/sysctl.conf
sudo sysctl -p
sysctl -a | grep -E "dmesg_restrict|kptr_restrict|ip_forward|rp_filter|disable_ipv6"


# Edit Xorg
sudo nano /etc/X11/xorg.conf

# Edit Limits
sudo nano /etc/security/limits.confs
add these lines: 
*               soft    nofile          4096
*               hard    nofile          8192
*               hard    nproc           128
*               soft    nproc           64











#Please add more, if you know
echo "Disabling unecessary services..."

sleep 1

# Disable Debugging Interfaces
sudo echo "kernel.dmesg_restrict=1" | sudo tee -a /etc/sysctl.conf
sudo echo "kernel.kptr_restrict=2" | sudo tee -a /etc/sysctl.conf
sudo sysctl -p

# Disable unnecessary overlay features Can be improved - Malware do a LOT of overlay - on apps, on site, etc - whatever we can add to avoid it, the better
sudo sed -i 's/ overlay//g' /etc/X11/xorg.conf
sudo sed -i 's/ allow-overlay//g' /etc/security/limits.conf


# Basic Firewall Setup
sudo ufw enable
check_success "Firewall enabled"
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow ssh
sudo ufw allow http
sudo ufw allow https
sudo ufw reload
check_success "Firewall rules configured"
sudo systemctl enable openvpn
check_success "VPN enabled"
sudo systemctl enable apparmor
check_success "Apparmor enabled"
systemctl start apparmor
aa-enforce /etc/apparmor.d/*
check_success "Apparmor rules configured"



# Lock DNS Settings
echo "Locking DNS settings..."
echo "nameserver 1.1.1.1" | sudo tee /etc/resolv.conf
echo "nameserver 9.9.9.9" | sudo tee -a /etc/resolv.conf
sudo chattr +i /etc/resolv.conf
check_success "DNS settings locked"

# Update System
echo "Updating system packages..."
sudo pacman -Syu --noconfirm
check_success "System updated"



=======================================================

# /etc/pacman.conf

# /etc/pacman.conf

[options]
# Always ask for confirmation before installing, upgrading or removing packages
# Uncomment the line below if you want to disable this behavior
# NoConfirm

# By default, pacman will use the fastest mirrors in your region.
# You can increase speed by updating the mirrorlist to reflect the fastest
# servers. For now, we'll use some reliable global mirrors.
ParallelDownloads = 5
Color = Always
TotalDownload = Yes
CheckSpace = Yes
VerbosePkgLists = Yes
NoProgressBar = No

# Use sigLevel 'Optional TrustAll' for keyring and avoid keyring problems
SigLevel = Optional TrustAll
LocalFileSigLevel = Optional

# General repositories for Arch
[core]
Include = /etc/pacman.d/mirrorlist

[extra]
Include = /etc/pacman.d/mirrorlist

[community]
Include = /etc/pacman.d/mirrorlist


# Arch User Repository (AUR)
[archlinuxfr]
SigLevel = Never
Server = http://repo.archlinux.fr/$arch

# Custom Repositories (You can add more here, such as other community repos)
[myrepo]
SigLevel = Optional TrustAll
Server = https://repo.mysite.com/$arch

# Mirrors
# Uncomment or modify the mirrorlist as per your region and preference
# It's good practice to uncomment the fastest mirrors first

[mirrorlist]
## Choose from these if you'd like
# United States
Server = https://mirror.rackspace.com/archlinux/$repo/os/$arch
Server = https://mirror.us.leaseweb.net/archlinux/$repo/os/$arch

# Europe
Server = https://mirror.hetzner.com/archlinux/$repo/os/$arch
Server = https://archlinux.ikoula.com/$repo/os/$arch

# Asia
Server = https://mirror.sjtu.edu.cn/archlinux/$repo/os/$arch
Server = https://ftp.yz.yamagata-u.ac.jp/pub/linux/archlinux/$repo/os/$arch

# A good mirror set for reliable and fast connections
Server = https://mirror.nl.leaseweb.net/archlinux/$repo/os/$arch
Server = https://archlinux.thaller.ws/$repo/os/$arch
Server = https://mirrors.kernel.org/archlinux/$repo/os/$arch

# Keep these values as default for global use
# Server = https://archlinux.mirror.ninja/$repo/os/$arch




=======================================================



# /etc/pacman.conf

[options]
# Always ask for confirmation before installing, upgrading or removing packages
# Uncomment the line below if you want to disable this behavior
# NoConfirm

# By default, pacman will use the fastest mirrors in your region.
# You can increase speed by updating the mirrorlist to reflect the fastest
# servers. For now, we'll use some reliable global mirrors.
ParallelDownloads = 5
Color = Always
TotalDownload = Yes
CheckSpace = Yes
VerbosePkgLists = Yes
NoProgressBar = No

# Use sigLevel 'Optional TrustAll' for keyring and avoid keyring problems
SigLevel = Optional TrustAll
LocalFileSigLevel = Optional

# General repositories for Arch
[core]
Include = /etc/pacman.d/mirrorlist

[extra]
Include = /etc/pacman.d/mirrorlist

[community]
Include = /etc/pacman.d/mirrorlist

# Arch User Repository (AUR)
[archlinuxfr]
SigLevel = Never
Server = http://repo.archlinux.fr/$arch

# Custom Repositories (You can add more here, such as other community repos)
[myrepo]
SigLevel = Optional TrustAll
Server = https://repo.mysite.com/$arch

# Mirrors
# Uncomment or modify the mirrorlist as per your region and preference
# It's good practice to uncomment the fastest mirrors first

[mirrorlist]
## Choose from these if you'd like
# United States
Server = https://mirror.rackspace.com/archlinux/$repo/os/$arch
Server = https://mirror.us.leaseweb.net/archlinux/$repo/os/$arch
# Europe
Server = https://mirror.hetzner.com/archlinux/$repo/os/$arch
Server = https://archlinux.ikoula.com/$repo/os/$arch
# Asia
Server = https://mirror.sjtu.edu.cn/archlinux/$repo/os/$arch
Server = https://ftp.yz.yamagata-u.ac.jp/pub/linux/archlinux/$repo/os/$arch

# A good mirror set for reliable and fast connections
Server = https://mirror.nl.leaseweb.net/archlinux/$repo/os/$arch
Server = https://archlinux.thaller.ws/$repo/os/$arch
Server = https://mirrors.kernel.org/archlinux/$repo/os/$arch

# Keep these values as default for global use
# Server = https://archlinux.mirror.ninja/$repo/os/$arch


=======================================================


# mirrorlist 

## Arch Linux Mirrorlist
## Generated by Reflector

Server = http://mirror.rackspace.com/archlinux/$repo/os/x86_64
Server = http://archlinux.mirror.liteserver.nl/$repo/os/x86_64
Server = http://mirror.osbeck.com/archlinux/$repo/os/x86_64
Server = http://mirror.dkm.cz/archlinux/$repo/os/x86_64
Server = http://ftp.sudhip.com/arch/x86_64
Server = http://mirror.albony.xyz/archlinux/$repo/os/x86_64
Server = http://mirror.pkgbuild.com/$repo/os/x86_64




=======================================================


# Harden kernel parameters
kernel.dmesg_restrict = 1
kernel.kptr_restrict = 2

# Disable IP forwarding (prevents routing traffic)
net.ipv4.ip_forward = 0
net.ipv6.conf.all.forwarding = 0

# Prevent source routing and redirects
net.ipv4.conf.all.accept_source_route = 0
net.ipv4.conf.all.accept_redirects = 0
net.ipv4.conf.all.secure_redirects = 0

# Ignore ICMP echo requests
net.ipv4.icmp_echo_ignore_all = 1
net.ipv6.icmp.echo_ignore_all = 1

# Disable SUID dumpable (prevents core dumps from setuid programs)
fs.suid_dumpable = 0

# Disable TCP timestamps (reduces tracking potential)
net.ipv4.tcp_timestamps = 0

# Prevent TCP sequence number prediction
net.ipv4.tcp_rfc1337 = 1

# Harden SYN flood handling
net.ipv4.tcp_max_syn_backlog = 2048
net.ipv4.tcp_synack_retries = 2
net.ipv4.tcp_syn_retries = 3

# Enable Reverse Path Filtering (security)
net.ipv4.conf.all.rp_filter = 1

# Disable unnecessary kernel modules
kernel.modules_disabled = 1

# Protect hardlinks and symlinks from hijacking
fs.protected_hardlinks = 1
fs.protected_symlinks = 1

# Disable IPv6 completely (security measure)
net.ipv6.conf.all.disable_ipv6 = 1
net.ipv6.conf.default.disable_ipv6 = 1
net.ipv6.conf.lo.disable_ipv6 = 1





=======================================================


# /etc/X11/xorg.conf



# Server Layout - Defines primary display and input devices
Section "ServerLayout"
    Identifier     "Layout0"
    Screen         0 "Screen0" 0 0
    InputDevice    "Keyboard0" "CoreKeyboard"
    InputDevice    "Mouse0" "CorePointer"
EndSection

# Keyboard Configuration - Adjust layout, model, and options
Section "InputDevice"
    Identifier     "Keyboard0"
    Driver         "evdev"
    Option         "XkbLayout" "us"
    Option         "XkbModel" "pc105"
    Option         "XkbOptions" "terminate:ctrl_alt_bksp"
EndSection

# Mouse Configuration - Adjust mouse settings
Section "InputDevice"
    Identifier     "Mouse0"
    Driver         "evdev"
    Option         "CorePointer"
EndSection

# Device Configuration - Configure GPU settings (Intel or other drivers)
Section "Device"
    Identifier     "Card0"
    Driver         "modesetting"  # Default driver for Intel and hybrid graphics
    Option         "NoAccel" "true"  # Disable hardware acceleration
    Option         "AccelMethod" "none"  # Disable acceleration methods
    Option         "RenderAccel" "false"  # Disable rendering acceleration
    Option         "Overlay" "false"  # Disable overlay to prevent malicious overlays
    Option         "TearFree" "true"  # Enable tear-free display for better performance
    Option         "DRI" "3"  # Enable Direct Rendering Infrastructure 3 (improved performance)
    Option         "Backlight" "true"  # Enable backlight control if supported
EndSection

# Screen Configuration - Set display settings (resolution, color depth)
Section "Screen"
    Identifier     "Screen0"
    Device         "Card0"
    DefaultDepth   24
    SubSection     "Display"
        Depth       24
        Modes       "1920x1080"  # Adjust resolution as needed
    EndSubSection
EndSection

# Module Loading - Load essential X11 modules
Section "Module"
    Load           "dbe"            # Double buffer extension
    Load           "extmod"         # Extension module for additional functionality
    Load           "record"         # Record extension for input event recording
    Load           "dri"            # Direct Rendering Infrastructure
    Load           "glx"            # OpenGL extension for rendering
    Load           "vesa"           # Optional fallback driver for older hardware
    Load           "xrandr"         # Enable dynamic screen resolution changes
    Load           "evdev"          # Input driver for various devices (mouse, keyboard)
    Load           "xinput"         # Input extension for fine control over input devices
EndSection

# Security: Disable indirect GLX connections for better security
Section "Security"
    Option         "AllowIndirectGLX" "off"  # Limit indirect GLX connections
EndSection



=======================================================
