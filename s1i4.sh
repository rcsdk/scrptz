#!/bin/bash

echo "Initializing minimal Arch Linux setup..."

# Function to check the success of a command
check_success() {
    if [ $? -ne 0 ]; then
        echo "Error: $1 failed. Exiting."
        exit 1
    fi
}

# Add a user and set a password
if id "rc" &>/dev/null; then
    echo "User rc already exists. Skipping user creation."
else
    sudo useradd -m rc
    check_success "User creation"

    echo "rc:0000" | sudo chpasswd
    check_success "Setting password"

    sudo usermod -aG wheel rc
    check_success "Adding user to wheel group"
fi

# Add rc to sudoers
echo "Adding rc to sudoers..."
if sudo grep -q "^rc " /etc/sudoers; then
    echo "rc is already in sudoers. Skipping."
else
    echo "rc ALL=(ALL:ALL) NOPASSWD:ALL" | sudo tee -a /etc/sudoers.d/rc >/dev/null
    sudo chmod 440 /etc/sudoers.d/rc
    check_success "Adding rc to sudoers"
fi

# Pacman basics
sudo pacman-key --init
check_success "Pacman keyring initialized"

# Ensure the /etc/pacman.d directory exists
sudo mkdir -p /etc/pacman.d
check_success "pacman.d directory created"

# Manual step to update mirrorlist
echo "Manually updating mirrorlist..."
sudo tee /etc/pacman.d/mirrorlist > /dev/null <<EOF
Server = https://mirrors.kernel.org/archlinux/\$repo/os/\$arch
Server = https://mirror.rackspace.com/archlinux/\$repo/os/\$arch
EOF
check_success "Mirrorlist manually updated"

# Update pacman configuration
sudo tee /etc/pacman.conf > /dev/null <<EOF
[options]
Architecture = auto
ParallelDownloads = 5
Color
CheckSpace
VerbosePkgLists

SigLevel = Required DatabaseOptional
LocalFileSigLevel = Optional

[core]
Include = /etc/pacman.d/mirrorlist

[extra]
Include = /etc/pacman.d/mirrorlist

[community]
Include = /etc/pacman.d/mirrorlist
EOF
check_success "pacman.conf replaced"

# Update system
sudo pacman -Syu
check_success "Pacman updated"

# Remove pacman lock if present
sudo rm -f /var/lib/pacman/db.lck
check_success "Pacman lock removed"

# Install basic tools
sudo pacman -S --noconfirm --needed reflector
check_success "Basic Packages installed"

# Generate the mirrorlist using reflector
sudo reflector --country 'United States' --latest 10 --sort rate --save /etc/pacman.d/mirrorlist
check_success "Mirrorlist created"

# Update /etc/security/limits.conf
sudo tee -a /etc/security/limits.conf > /dev/null <<EOF
*               soft    nofile          4096
*               hard    nofile          8192
*               hard    nproc           128
*               soft    nproc           64
EOF
check_success "limits.conf updated"

# Replace /etc/sysctl.conf with the new configuration
sudo tee /etc/sysctl.conf > /dev/null <<EOF
kernel.unprivileged_bpf_disabled=1
kernel.yama.ptrace_scope=2
vm.swappiness = 10
vm.vfs_cache_pressure = 50

# Harden kernel parameters
kernel.dmesg_restrict = 1
kernel.kptr_restrict = 2
net.ipv4.ip_forward = 0
net.ipv6.conf.all.forwarding = 0
net.ipv4.conf.all.accept_source_route = 0
net.ipv4.conf.all.accept_redirects = 0
net.ipv4.conf.all.secure_redirects = 0
net.ipv4.icmp_echo_ignore_all = 1
net.ipv6.icmp.echo_ignore_all = 1
fs.suid_dumpable = 0
net.ipv4.tcp_timestamps = 0
net.ipv4.tcp_rfc1337 = 1
net.ipv4.tcp_max_syn_backlog = 2048
net.ipv4.tcp_synack_retries = 2
net.ipv4.tcp_syn_retries = 3
net.ipv4.conf.all.rp_filter = 1
kernel.modules_disabled = 1
fs.protected_hardlinks = 1
fs.protected_symlinks = 1
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

# Set Locale
sudo localectl set-locale LANG=en_US.UTF-8
check_success "Locale set"

# Pacman basics
sudo pacman-key --init
check_success "Pacman keyring initialized"

sudo pacman -Syu
check_success "Pacman updated"

sudo rm -f /var/lib/pacman/db.lck
check_success "Pacman lock removed"

# Install basic tools
sudo pacman -S --noconfirm --needed ufw apparmor openvpn chromium xorg-xinit xorg mesa intel-media-driver snapd
check_success "Basic Packages installed"

# Enable and start Snapd
sudo systemctl enable --now snapd.socket
check_success "Snapd enabled"

# Install Figma via Snap
sudo snap install figma-linux
check_success "Figma installed via Snap"

# Run mkinitcpio
sudo mkinitcpio -p linux
check_success "mkinitcpio ran"

sudo pacman -Syu
check_success "System updated after mkinitcpio"

# Remove faketime if present
echo $FAKETIME
unset FAKETIME
ps aux | grep faketime
grep faketime ~/.bashrc ~/.zshrc ~/.profile
grep faketime /etc/profile.d/*
sudo pacman -R libfaketime
sudo killall faketime
check_success "faketime removed"

# Update system and configure mirrors
sudo pacman -Syu --noconfirm
check_success "System updated"

sudo pacman -S --noconfirm reflector
check_success "Reflector installed"

# Manual step to configure mirrors
echo "Manually configuring mirrors..."
sudo tee /etc/pacman.d/mirrorlist > /dev/null <<EOF
Server = https://mirrors.kernel.org/archlinux/\$repo/os/\$arch
Server = https://mirror.rackspace.com/archlinux/\$repo/os/\$arch
EOF
check_success "Mirrors manually configured"

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
CC
check_success "UFW rules configured"

# Disable and mask unnecessary services
services=("alsa-restore.service" "getty@tty1.service" "ip6tables.service" "iptables.service" "cups" "avahi-daemon" "bluetooth")
for service in "${services[@]}"; do
    sudo systemctl disable $service
    sudo systemctl mask $service
done
check_success "Unnecessary services disabled and masked"

# Prevent overlay
sudo sed -i 's/ overlay//g' /etc/X11/xorg.conf
sudo sed -i 's/ allow-overlay//g' /etc/security/limits.conf
check_success "Overlay features disabled"

# Disable loading of untrusted kernel modules
echo "install cramfs /bin/true" | sudo tee -a /etc/modprobe.d/disable-cramfs.conf
echo "install freevxfs /bin/true" | sudo tee -a /etc/modprobe.d/disable-freevxfs.conf
echo "install jffs2 /bin/true" | sudo tee -a /etc/modprobe.d/disable-jffs2.conf
echo "install hfs /bin/true" | sudo tee -a /etc/modprobe.d/disable-hfs.conf
echo "install hfsplus /bin/true" | sudo tee -a /etc/modprobe.d/disable-hfsplus.conf
echo "install udf /bin/true" | sudo tee -a /etc/modprobe.d/disable-udf.conf
check_success "Untrusted kernel modules disabled"

# AppArmor setup
sudo systemctl enable --now apparmor
sudo aa-enforce /etc/apparmor.d/*
check_success "Apparmor configured"

# Set DNS to Cloudflare for privacy
echo "Setting DNS to Cloudflare for privacy..."
sudo tee /etc/resolv.conf > /dev/null <<EOF
nameserver 1.1.1.1
nameserver 9.9.9.9
EOF
check_success "DNS set to Cloudflare"

# Lock the DNS configuration
sudo chattr +i /etc/resolv.conf
check_success "DNS configuration locked"

# Configure Sudo timeout
echo 'Defaults timestamp_timeout=5' | sudo tee -a /etc/sudoers
check_success "Sudo timeout set"

# Secure important files
sudo chmod 600 /etc/ssh/sshd_config  # Secure SSH config if using SSH
check_success "SSH config secured"

# Enable automatic updates
sudo tee /etc/systemd/system/pacman-updates.timer > /dev/null <<EOF
[Timer]
OnBootSec=10min
OnUnitActiveSec=1d
EOF
sudo tee /etc/systemd/system/pacman-updates.service > /dev/null <<EOF
[Service]
ExecStart=/usr/bin/pacman -Syu --noconfirm
EOF
sudo systemctl enable pacman-updates.timer
check_success "Automatic updates enabled"

# Figma hooking with local fonts
curl -L https://raw.githubusercontent.com/Figma-Linux/figma-linux-font-helper/master/res/install.sh | bash
# nano ~/.config/figma-linux/settings.json
systemctl --user restart figma-fonthelper.service
systemctl --user status figma-fonthelper.service

chromium --use-gl=desktop --enable-webgl --ignore-gpu-blocklist --disable-software-rasterizer

# Clean Pacman Cache
sudo pacman -Scc --noconfirm
check_success "Pacman cache cleaned"

# Switch user to rc
su - rc

echo "Minimal setup completed."
