#!/bin/bash

echo "Initializing minimal Arch Linux setup..."

# Check the system specs
inxi -Fxz


# Function to check the success of a command
check_success() {
    if [ $? -ne 0 ]; then
        echo "Error: $1 failed. Exiting."
        exit 1
    fi
}



# Add a user and set a password
sudo useradd -m rc
if [ $? -ne 0 ]; then
    echo "Error: User creation failed. Exiting."
    exit 1
fi

echo "rc:0000" | sudo chpasswd
if [ $? -ne 0 ]; then
    echo "Error: Setting password failed. Exiting."
    exit 1
fi

sudo usermod -aG wheel rc
if [ $? -ne 0 ]; then
    echo "Error: Adding user to wheel group failed. Exiting."
    exit 1
fi

# Add rc to sudoers
echo "Adding rc to sudoers..."
if sudo grep -q "^rc " /etc/sudoers; then
    echo "rc is already in sudoers. Skipping."
else
    echo "rc ALL=(ALL:ALL) NOPASSWD:ALL" | sudo tee -a /etc/sudoers.d/rc >/dev/null
    sudo chmod 440 /etc/sudoers.d/rc
    if [ $? -ne 0 ]; then
        echo "Error: Adding rc to sudoers failed. Exiting."
        exit 1
    fi
fi

# Switch user to rc
su - rc



# Replace /etc/pacman.conf with the new configuration
sudo tee /etc/pacman.conf > /dev/null <<EOF
[options]
# Always ask for confirmation before installing, upgrading or removing packages
# Uncomment the line below if you want to disable this behavior
# NoConfirm

# By default, pacman will use the fastest mirrors in your region.
# You can increase speed by updating the mirrorlist to reflect the fastest
# servers. For now, we'll use some reliable global mirrors.
ParallelDownloads = 5
Color = Always
TotalDownload
CheckSpace = Yes
VerbosePkgLists = Yes
NoProgressBar = No

# Use sigLevel 'Optional TrustAll' for keyring and avoid keyring problems
SigLevel = Optional TrustAll
LocalFileSigLevel = Optional

[archlinuxfr]
SigLevel = Never
Server = http://repo.archlinux.fr/$arch

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
Server = http://repo.archlinux.fr/\$arch

# Custom Repositories (You can add more here, such as other community repos)
[myrepo]
SigLevel = Optional TrustAll
Server = https://repo.mysite.com/\$arch

# Mirrors (United States)
Server = https://mirror.rackspace.com/archlinux/\$repo/os/\$arch
Server = https://mirror.us.leaseweb.net/archlinux/\$repo/os/\$arch

# Mirrors (Europe)
Server = https://mirror.hetzner.com/archlinux/\$repo/os/\$arch
Server = https://archlinux.ikoula.com/\$repo/os/\$arch

# Mirrors (Asia)
Server = https://mirror.sjtu.edu.cn/archlinux/\$repo/os/\$arch
Server = https://ftp.yz.yamagata-u.ac.jp/pub/linux/archlinux/\$repo/os/\$arch

# A good mirror set for reliable and fast connections
Server = https://mirror.nl.leaseweb.net/archlinux/\$repo/os/\$arch
Server = https://archlinux.thaller.ws/\$repo/os/\$arch
Server = https://mirrors.kernel.org/archlinux/\$repo/os/\$arch

# Keep these values as default for global use
# Server = https://archlinux.mirror.ninja/\$repo/os/\$arch


EOF



# Update /etc/security/limits.conf
sudo tee -a /etc/security/limits.conf > /dev/null <<EOF
*               soft    nofile          4096
*               hard    nofile          8192
*               hard    nproc           128
*               soft    nproc           64
EOF



# Replace /etc/sysctl.conf with the new configuration
sudo tee /etc/sysctl.conf > /dev/null <<EOF
kernel.unprivileged_bpf_disabled=1
kernel.yama.ptrace_scope=2
vm.swappiness = 10
vm.vfs_cache_pressure = 50

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
EOF
check_success "sysctl.conf replaced"







# Set Time Zone to São Paulo
sudo timedatectl set-timezone America/Sao_Paulo
check_success "Timezone set"

# Configure Display Brightness
xrandr --output eDP1 --brightness 0.4
check_success "Brightness adjusted"

# Set Locale (if not set already)
sudo localectl set-locale LANG=en_US.UTF-8
check_success "Locale set"

# Pacman basics
sudo pacman-key --init
sudo gpg --check-trustdb
check_success "Pacman keyring initialized"

sudo pacman -Syu
check_success "Pacman updated"

sudo rm -f /var/lib/pacman/db.lck
check_success "Pacman lock removed"


# Install basic tools
sudo pacman -S --noconfirm --needed ufw apparmor openvpn chromium
check_success "Basic Packages installed" 
sudo rm -f /var/lib/pacman/db.lck


# Install basic tools
sudo pacman -S --noconfirm --needed xorg-xinit xorg mesa
check_success "Basic Packages installed" 
sudo rm -f /var/lib/pacman/db.lck


# Install basic tools
sudo pacman -S --noconfirm --needed intel-media-driver snapd
check_success "Basic Packages installed" 
sudo rm -f /var/lib/pacman/db.lck

# Download Snapd
sudo pacman -Syu
sudo pacman -S snapd

# Enable and start Snapd
sudo systemctl enable --now snapd.socket
check_success "Snapd enabled"

# Install Figma via Snap
sudo snap install figma-linux
check_success "Figma installed via Snap"


# Install monitoring tools
# Uncomment if needed
# sudo pacman -S --noconfirm --needed htop iotop nethogs iftop sysstat auditd xfce4-whiskermenu-plugin
# check_success "Monitoring tools installed"

sudo mkinitcpio -p linux
check_success "mkinitcpio ran"

sudo pacman -Syu
check_success "System updated after mkinitcpio"

lsmod | grep xhci_pci
lsmod | grep ast
lsmod | grep aic94xx
lsmod | grep wd719x
dmesg | grep -i firmware
check_success "System info and firmware checked"

sudo rm -f /var/lib/pacman/db.lck
check_success "Pacman lock removed again"

echo $FAKETIME
unset FAKETIME
ps aux | grep faketime
grep faketime ~/.bashrc ~/.zshrc ~/.profile
grep faketime /etc/profile.d/*
kill -9 9394 9400
grep faketime ~/.bashrc ~/.zshrc /etc/profile /etc/profile.d/*
sudo pacman -R libfaketime
sudo killall faketime
check_success "faketime removed"

# Update system and configure mirrors
sudo pacman -Syu --noconfirm
check_success "System updated"

sudo pacman -S --noconfirm reflector
check_success "Reflector installed"

sudo reflector --country 'United States' --latest 10 --sort rate --save /etc/pacman.d/mirrorlist
check_success "Mirrors configured"



# Disable Touchpad
synclient TouchpadOff=1
check_success "Touchpad disabled"

# Harden Kernel Parameters
cat <<EOF | sudo tee /etc/sysctl.d/99-custom.conf
kernel.dmesg_restrict = 1
kernel.kptr_restrict = 2
EOF
sudo sysctl --system
check_success "Kernel parameters set"

# Enable and configure UFW (Firewall)
sudo systemctl enable --now ufw
check_success "UFW enabled"

sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow ssh
sudo ufw reload
check_success "UFW rules configured"

# Disable unnecessary services (Bluetooth, Printer, etc.)
sudo systemctl disable alsa-restore.service getty@tty1.service ip6tables.service iptables.service cups avahi-daemon bluetooth
check_success "Unnecessary services disabled"

# Mask unnecessary services
sudo systemctl mask alsa-restore.service getty@tty1.service ip6tables.service iptables.service cups avahi-daemon bluetooth
check_success "Unnecessary services masked"

# Prevent overlay
sudo sed -i 's/ overlay//g' /etc/X11/xorg.conf
sudo sed -i 's/ allow-overlay//g' /etc/security/limits.conf
check_success "Overlay features disabled"

# AppArmor setup
sudo systemctl enable --now apparmor
sudo aa-enforce /etc/apparmor.d/*
check_success "Apparmor configured"

# Set DNS to Cloudflare for privacy
echo "nameserver 1.1.1.1" | sudo tee /etc/resolv.conf
echo "nameserver 9.9.9.9" | sudo tee -a /etc/resolv.conf
sudo chattr +i /etc/resolv.conf
check_success "DNS set and locked"

# Configure Sudo timeout
echo 'Defaults timestamp_timeout=5' | sudo tee -a /etc/sudoers
check_success "Sudo timeout set"

# Secure important files
sudo chmod 600 /etc/ssh/sshd_config  # Secure SSH config if using SSH
check_success "SSH config secured"

# Enable automatic updates
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
systemctl --user status figma-fonthelper.service

chromium --use-gl=desktop --enable-webgl --ignore-gpu-blocklist --disable-software-rasterizer


# Clean Pacman Cache
sudo pacman -Scc --noconfirm
check_success "Pacman cache cleaned"

echo "Minimal setup completed."


#
#
#
#
#

