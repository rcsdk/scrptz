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
echo "Setting keyboard bindings..."
echo "bind \"^C\": copy" >> ~/.inputrc
echo "bind \"^V\": paste" >> ~/.inputrc
echo "bind \"^Z\": suspend" >> ~/.inputrc
check_success "Keyboard bindings"
xfce4-terminal &
sleep 1

# --- Done: Disable Touchpad ---
echo "Disabling touchpad..."
synclient TouchpadOff=1
check_success "Touchpad disabled"

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
pacman --Syy
pacman -Syu
pacman -Sy
#pacman -S --noconfirm linux
#pacman -S --noconfirm linux-firmware
sudo rm -f /var/lib/pacman/db.lck
pacman -S --noconfirm ufw
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

# Basic Firewall Setup
sudo ufw enable
check_success "Firewall enabled"
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw reload
check_success "Firewall rules configured"

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
