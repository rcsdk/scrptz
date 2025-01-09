# ---------------------------------------
# Fast Initialization Script for Secure Environment
# ---------------------------------------

# Function to check the success of a command
check_success() {
    if [ $? -ne 0 ]; then
        echo "Error: $1 failed. Exiting."
        exit 1
    fi
}

# --- Done: Keyboard Bindings ---
# echo "Setting keyboard bindings..."
# echo "bind \"^C\": copy" >> ~/.inputrc
# echo "bind \"^V\": paste" >> ~/.inputrc
# echo "bind \"^Z\": suspend" >> ~/.inputrc
# check_success "Keyboard bindings"
# xfce4-terminal &
# sleep 1

# --- Done: Disable Touchpad ---
echo "Disabling touchpad..."
synclient TouchpadOff=1
check_success "Touchpad disabled"


# Edit pacman
nano /etc/pacman.conf
sleep 1


sudo pacman -S reflector
sudo reflector --country 'United States' --latest 10 --sort rate --save /etc/pacman.d/mirrorlist

# Edit Sysctl
sudo nano /etc/sysctl.conf
sudo sysctl -p
sysctl -a | grep -E "dmesg_restrict|kptr_restrict|ip_forward|rp_filter|disable_ipv6"


echo $FAKETIME
unset FAKETIME
ps aux | grep faketime
grep faketime ~/.bashrc ~/.zshrc ~/.profile
grep faketime /etc/profile.d/*
kill -9 9394 9400
grep faketime ~/.bashrc ~/.zshrc /etc/profile /etc/profile.d/*
sudo pacman -R libfaketime
sudo killall faketime






# --- Done: Remove Pacman Lock ---
echo "Removing pacman database lock..."
sudo rm -f /var/lib/pacman/db.lck
check_success "Pacman lock removed"
sleep 1


# --- Firefox Hardened Configuration ---
echo "Launching Firefox in private mode..."
firefox --private &
check_success "Firefox launched"
sleep 1


echo "Preparing pacman and limux's classics..."
pacman-key --init
gpg --check-trustdb
pacman -Syy
pacman -Syu
pacman -Sy
#pacman -S --noconfirm linux
#pacman -S --noconfirm linux-firmware
sudo rm -f /var/lib/pacman/db.lck
pacman -S --noconfirm ufw
pacman -S --noconfirm apparmor
pacman -S --noconfirm openvpn
sudo mkinitcpio -p linux
sudo pacman -Syu
lsmod | grep xhci_pci
lsmod | grep ast
lsmod | grep aic94xx
lsmod | grep wd719x
dmesg | grep -i firmware
sleep 1


#Please add more, if you know
echo "Disabling unecessary services..."
sudo systemctl disable alsa-restore.service
sudo systemctl disable getty@tty1.service
sudo systemctl disable ip6tables.service
sudo systemctl disable iptables.service
sudo systemctl disable cups
sudo systemctl disable avahi-daemon
sudo systemctl disable bluetooth
sudo systemctl mask alsa-restore.service
sudo systemctl mask getty@tty1.service
sudo systemctl mask ip6tables.service
sudo systemctl mask iptables.service
sudo systemctl mask cups
sudo systemctl mask avahi-daemon
sudo systemctl mask bluetooth
sleep 1

# Disable Debugging Interfaces
sudo echo "kernel.dmesg_restrict=1" | sudo tee -a /etc/sysctl.conf
sudo echo "kernel.kptr_restrict=2" | sudo tee -a /etc/sysctl.conf
sudo sysctl -p
check_success "Sysctl configurations applied"



#Please add more, if you know  Can be improved
sudo echo "nameserver 8.8.8.8" | sudo tee /etc/resolv.conf


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

[options]
# Always ask for confirmation before installing, upgrading or removing packages
# Uncomment the line below if you want to disable this behavior
# NoConfirm

# By default, pacman will use the fastest mirrors in your region.
# You can increase speed by updating the mirrorlist to reflect the fastest
# servers. For now, we'll use some reliable global mirrors.
ParallelDownloads = 5       # Download up to 5 packages simultaneously
Color = Always              # Color the output for better readability
TotalDownload = Yes         # Show the total download size before confirming
CheckSpace = Yes            # Check if there is enough space on disk before installing
VerbosePkgLists = Yes       # Enable verbose package list when upgrading
NoProgressBar = No          # Show progress bars during installations/updates

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




# Basic File Integrity Check
echo "Initializing file integrity checks..."
sudo pacman -S --noconfirm aide
check_success "AIDE installed"
sudo aideinit
check_success "AIDE initialized"
sudo aide --check
check_success "AIDE check 


# --- Done: Display Brightness ---
echo "Configuring display brightness..."
xrandr -q
alias br='xrandr --output eDP1 --brightness'
br 0.4
check_success "Display brightness"
sleep 1


# --- Install Browser ---
echo "Installing Chromium browser..."
sudo pacman -S --noconfirm chromium
check_success "Chromium installation"
chromium --new-window "https://example-tab1.com" "https://example-tab2.com" &
sleep 2


# --- Fix Audio and Test Mic ---
echo "Configuring and testing audio..."
sudo pacman -S --noconfirm alsa-utils pulseaudio pavucontrol
check_success "Audio tools installed"
amixer sset Master unmute
check_success "Audio unmuted"
pavucontrol &
sleep 1

# --- Edit Pacman Configuration ---
echo "Editing pacman configuration..."
sudo nano /etc/pacman.conf
completed"


# --- Still to Be Done ---
# --- Create a New User ---
echo "Creating new user 'rc'..."
sudo useradd -m rc
check_success "User creation"
echo "rc:0000" | sudo chpasswd
check_success "Setting user password"
sudo usermod -aG wheel rc
check_success "Granting sudo permissions to 'rc'"

# --- Critical Security Steps ---
echo "Applying critical security steps..."
# Kernel Hardening
sudo sed -i 's/GRUB_CMDLINE_LINUX_DEFAULT="[^"]*/& mitigations=on nosmt slab_nomerge/' /etc/default/grub
check_success "Kernel hardening"
sudo grub-mkconfig -o /boot/grub/grub.cfg
check_success "GRUB configuration updated"
