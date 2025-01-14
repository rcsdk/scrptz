
#!/bin/bash

echo "Initializing minimal Arch Linux setup..."

# Function to check the success of a command
check_success() {
    if [ $? -ne 0 ]; then
        echo "Error: $1 failed. Exiting."
        exit 1
    fi
}

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
pacman-key --init
gpg --check-trustdb
check_success "Pacman keyring initialized"

pacman -Syy
pacman -Syu
pacman -Sy
check_success "Pacman updated"


sudo rm -f /var/lib/pacman/db.lck
check_success "Pacman lock removed"

pacman -S --noconfirm ufw
pacman -S --noconfirm apparmor
pacman -S --noconfirm openvpn
pacman -S --noconfirm chromium 
pacman -S --noconfirm xorg-xinit
pacman -S --noconfirm xorg
check_success "Basic Packages installed"



# Install monitoring tools
pacman -S --noconfirm htop
pacman -S --noconfirm iotop
pacman -S --noconfirm nethogs
pacman -S --noconfirm iftop
pacman -S --noconfirm sysstat
pacman -S --noconfirm auditd
sudo pacman -S xfce4-whiskermenu-plugin

check_success "Monitoring tools installed"


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
sleep 1

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
9


# Add a user and set password
sudo useradd -m rc
check_success "User rc created"

echo "rc:0000" | sudo chpasswd
check_success "Password for rc set"

sudo usermod -aG wheel rc
check_success "User rc added to wheel group"


# Update system and configure mirrors
sudo pacman -Syu --noconfirm
check_success "System updated"

sudo pacman -S --noconfirm reflector
check_success "Reflector installed"

sudo reflector --country 'United States' --latest 10 --sort rate --save /etc/pacman.d/mirrorlist
check_success "Mirrors configured"



# Install basic tools
sudo pacman -S --noconfirm xorg xorg-xinit chromium mesa intel-media-driver ufw
check_success "Basic Tools Installed"

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
sudo systemctl disable alsa-restore.service
sudo systemctl disable getty@tty1.service
sudo systemctl disable ip6tables.service
sudo systemctl disable iptables.service
sudo systemctl disable cups
sudo systemctl disable avahi-daemon
sudo systemctl disable bluetooth
check_success "Unnecessary services disabled"

# Mask unnecessary services
sudo systemctl mask alsa-restore.service
sudo systemctl mask getty@tty1.service
sudo systemctl mask ip6tables.service
sudo systemctl mask iptables.service
sudo systemctl mask cups
sudo systemctl mask avahi-daemon
sudo systemctl mask bluetooth
check_success "Unnecessary services masked"

# Prevent overlay
sudo sed -i 's/ overlay//g' /etc/X11/xorg.conf
sudo sed -i 's/ allow-overlay//g' /etc/security/limits.conf
check_success "Overlay features disabled"


# AppArmor setup (if needed)
sudo systemctl enable apparmor
sudo systemctl start apparmor
sudo aa-enforce /etc/apparmor.d/*
check_success "Apparmor configured"


# Set DNS to Cloudflare for privacy
echo "nameserver 1.1.1.1" | sudo tee /etc/resolv.conf
echo "nameserver 9.9.9.9" | sudo tee -a /etc/resolv.conf
sudo chattr +i /etc/resolv.conf
check_success "DNS set and locked"


# Configure Sudo timeout (for better security)
echo 'Defaults timestamp_timeout=5' | sudo tee -a /etc/sudoers
check_success "Sudo timeout set"

# Secure important files
sudo chmod 600 /etc/ssh/sshd_config  # Secure SSH config if using SSH
check_success "SSH config secured"


# Secure important files
sudo chmod 600 /etc/ssh/sshd_config  # Secure SSH config if using SSH


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



chromium --incognito --disable-background-networking --disable-default-apps --disable-sync --disable-translate --no-first-run --no-sandbox --force-device-scale-factor=1 --disable-gpu-sandbox --enable-native-gpu-memory-buffers --use-gl=desktop --use-cmd-decoder=validating --disable-software-rasterizer --disable-font-subpixel-positioning --disable-gpu-driver-bug-workarounds --disable-gpu-driver-workarounds --disable-gpu-vsync --enable-accelerated-video-decode --enable-accelerated-mjpeg-decode --enable-features=VaapiVideoDecoder,CanvasOopRasterization --enable-gpu-compositing --enable-gpu-rasterization --enable-native-gpu-memory-buffers --enable-oop-rasterization --canvas-oop-rasterization --enable-raw-draw --use-vulkan --enable-zero-copy --ignore-gpu-blocklist --disable-gpu-driver-bug-workarounds
"https://github.com/login"



# Clean Pacman Cache
sudo pacman -Scc --noconfirm
check_success "Pacman cache cleaned"


echo "Minimal setup completed."



# END OF THE SCRIPTn-Always under development - 
# Below things I still do manually and ideas for next steps
#
#
#
#
#
#
#
#
#
#
#
#
#
