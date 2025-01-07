#!/bin/bash

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
xfce4-terminal &
echo "bind \"^C\": copy" >> ~/.inputrc
echo "bind \"^V\": paste" >> ~/.inputrc
echo "bind \"^Z\": suspend" >> ~/.inputrc
check_success "Keyboard bindings"
xfce4-terminal &
sleep 1

# --- Done: Display Brightness ---
echo "Configuring display brightness..."
xrandr -q
alias br='xrandr --output eDP1 --brightness'
br 0.4
check_success "Display brightness"
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

# --- Still to Be Done ---
# --- Create a New User ---
echo "Creating new user 'rc'..."
sudo useradd -m rc
check_success "User creation"
echo "rc:0000" | sudo chpasswd
check_success "Setting user password"
sudo usermod -aG wheel rc
check_success "Granting sudo permissions to 'rc'"

# --- Install Browser ---
echo "Installing Chromium browser..."
sudo pacman -S --noconfirm chromium
check_success "Chromium installation"
chromium --new-window "https://example-tab1.com" "https://example-tab2.com" &
sleep 2



-----------------------


# --- Firefox Hardened Configuration ---
echo "Launching Firefox in private mode..."
firefox --private &
check_success "Firefox launched"

------ how to do this - ill send 

#!/bin/bash

# Define Firefox profile path
FIREFOX_PROFILE_PATH=$(find ~/.mozilla/firefox -type d -name "*.default-release" 2>/dev/null)

# Check if profile exists
if [ -z "$FIREFOX_PROFILE_PATH" ]; then
  echo "Firefox profile not found. Please start Firefox to create a profile."
  exit 1
fi

# Create user.js file
cat <<EOL > "$FIREFOX_PROFILE_PATH/user.js"
// Firefox Configuration for Security and Privacy

// Disable Telemetry
user_pref("toolkit.telemetry.enabled", false);

// Disable WebRTC (Prevents IP Leaks)
user_pref("media.peerconnection.enabled", false);

// Harden Referrer Policy
user_pref("network.http.referer.XOriginPolicy", 2);

// Enforce HTTPS
user_pref("dom.security.https_only_mode", true);

// Block Dangerous Content
user_pref("privacy.trackingprotection.enabled", true);

// Disable DNS Over HTTPS (Optional)
user_pref("network.trr.mode", 5);

// Isolate First-Party Cookies
user_pref("privacy.firstparty.isolate", true);

// Disable Speculative Connections
user_pref("network.dns.disablePrefetch", true);

// Fingerprinting Resistance
user_pref("privacy.resistFingerprinting", true);

// Disable WebGL
user_pref("webgl.disabled", true);

// Disable Geolocation
user_pref("geo.enabled", false);

// Disable Autofill
user_pref("signon.autofillForms", false);
EOL

echo "Firefox preferences applied in $FIREFOX_PROFILE_PATH/user.js"

------------------------




# --- Fix Audio and Test Mic ---
echo "Configuring and testing audio..."
sudo pacman -S --noconfirm alsa-utils pulseaudio pavucontrol
check_success "Audio tools installed"
amixer sset Master unmute
check_success "Audio unmuted"
pavucontrol &
sleep 1


----------------------------------------------
PACMAN CONF AND MIRRORS - I want to use this soltion - please create a script to go here - 


Rate Mirrors

former Rate Arch Mirrors (changed in v0.4.0) - previous README

Tag Badge

This is a tool, which tests mirror speed for:

    Arch Linux
        including Chaotic-AUR
        including Arch Linux CN
    Arch Linux ARM
    Manjaro
    RebornOS
    Artix Linux
    CachyOS
    EndeavourOS
    any http/https mirrors via stdin.

It uses info about submarine cables and internet exchanges (kudos to TeleGeography for data) to jump between countries and find fast mirrors. And it's fast enough to run it before each system update (~30 seconds with default options).
Installation

    ArchLinux AUR: yay -S rate-mirrors-bin - pre-built binary with statically linked musl
    ArchLinux AUR: yay -S rate-mirrors - build binary from sources, linking glibc dynamically
    Github releases: pre-built binary with statically linked musl

or build manually:

cargo build --release --locked

Usage

    format is: rate-mirrors {base options} subcommand {subcommand options}
    run rate-mirrors help to see base options, which go before subcommand
    it doesn't need root, but if you wish just pass --allow-root option.

Here are supported subcommands:

Each subcommand has its own options, so run rate-mirrors arch --help to see arch specific options, which should go after arch sub-command.

    rate-mirrors arch — fetches Arch Linux mirrors, skips outdated/syncing ones and tests them.

    To backup /etc/pacman.d/mirrorlist file and update it with the rated mirrors run the command below:

    export TMPFILE="$(mktemp)"; \
        sudo true; \
        rate-mirrors --save=$TMPFILE arch --max-delay=43200 \
          && sudo mv /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist-backup \
          && sudo mv $TMPFILE /etc/pacman.d/mirrorlist

Or if you don't need a backup: rate-mirrors arch | sudo tee /etc/pacman.d/mirrorlist.

rate-mirrors archlinuxcn - fetches Arch Linux CN mirrors and tests them

rate-mirrors archarm — fetches Arch Linux ARM mirrors and tests them

rate-mirrors artix — fetches Artix Linux mirrors and tests them

rate-mirrors blackarch - fetches BlackArch mirrors and tests them

rate-mirrors cachyos — fetches CachyOS mirrors and tests them

rate-mirrors chaotic-aur - fetches Arch Linux Chaotic-AUR mirrors and tests them

rate-mirrors endeavouros — fetches/reads EndeavourOS mirrors, skips outdated ones and tests them

rate-mirrors manjaro — fetches Manjaro mirrors, skips outdated ones and tests them

rate-mirrors rebornos — fetches RebornOS mirrors and tests them

rate-mirrors stdin — takes mirrors from stdin

Each string should comply with one of two supported formats:

    tab-separated url and country (either name or country code)
    tab-separated country and url — just in case :)
    url

Urls should be what --path-to-test and --path-to-return are joined to.

e.g. we have a file with mirrors (countries are required for country-hopping):

https://mirror-a.mirrors.org/best-linux-distro/
US\thttps://mirror-b.mirrors.org/best-linux-distro/
https://mirror-c.mirrors.org/best-linux-distro/\tDE
https://mirror-d.mirrors.org/best-linux-distro/\tAustria

and we'd like to test it & format output for Arch:

cat mirrors_by_country.txt | \
    rate-mirrors --concurrency=40 stdin \
       --path-to-test="extra/os/x86_64/extra.files" \
       --path-to-return='$repo/os/$arch' \
       --comment-prefix="# " \
       --output-prefix="Server = "

Algorithm

The tool uses the following info:

    submarine cable connections
    number of internet exchanges per country and distances to weight country connections
    continents to naively assume countries of the same continent are directly linked

e.g. steps for arch:

    fetch mirrors from Arch Linux - Mirror status as json

    skip ones, which haven’t completed syncing (--completion=1 option)

    skip ones with delays-since-the-last-sync longer than 1 day (--max-delay option)

    sort mirrors by “Arch Linux - Mirror Status” score - the lower the better (--sort-mirrors-by=score_asc option)

    take the next country to explore (or --entry-country option, US by default -- no need to change)

    find neighbor countries --country-neighbors-per-country=3, using multiple strategies:
        major internet hubs first ( first two jumps only )
        closest by distance first ( every jump )

    take --country-test-mirrors-per-country=2 mirrors per country, selected at step 6, test speed and find 2 mirrors: 1 fastest and 1 with shortest connection time

    take countries of mirrors from step 7 and go to step 5

    after --max-jumps=7 jumps are done, take top M mirrors by speed (--top-mirrors-number-to-retest=5), test them with no concurrency, sort by speed and prepend to the resulting list

Example of everyday use on Arch Linux:

alias ua-drop-caches='sudo paccache -rk3; yay -Sc --aur --noconfirm'
alias ua-update-all='export TMPFILE="$(mktemp)"; \
    sudo true; \
    rate-mirrors --save=$TMPFILE arch --max-delay=21600 \
      && sudo mv /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist-backup \
      && sudo mv $TMPFILE /etc/pacman.d/mirrorlist \
      && ua-drop-caches \
      && yay -Syyu --noconfirm'

Few notes:

    the tool won't work with root permissions because it doesn't need them
    ua- prefix means "user alias"
    paccache from pacman-contrib package
    yay is an AUR helper
    sudo true forces password prompt in the very beginning

To persist aliases, add them to ~/.zshrc or ~/.bashrc (based on the shell you use)

Once done, just launch a new terminal and run:

ua-update-all




# --- Edit Pacman Configuration ---
echo "Editing pacman configuration..."
sudo nano /etc/pacman.conf


# Ensure pacman.conf is restored at every boot
sudo cp /path/to/template/pacman.conf /etc/pacman.conf


# Template for pacman.conf
[options]
# Set the parallel download to speed up package retrieval
ParallelDownloads = 5
# Enable color in the terminal
Color
# Always check the integrity of the packages
CheckSpace
SigLevel = Required DatabaseOptional
# Make sure dependencies are handled with care
InstallKnownDivisions = No

# Repositories
[core]
Include = /etc/pacman.d/mirrorlist

[extra]
Include = /etc/pacman.d/mirrorlist

[community]
Include = /etc/pacman.d/mirrorlist

[testing]
Include = /etc/pacman.d/mirrorlist

[multilib]
Include = /etc/pacman.d/mirrorlist

[pentesting]
# Add mirrors related to pentesting tools and darker repositories
Server = https://your-pentest-mirror-url
Server = https://another-pentest-mirror-url

[archlinuxfr]
SigLevel = Never
Server = http://repo.archlinux.fr/$arch



------------------------------------------------------


# --- Critical Security Steps ---
echo "Applying critical security steps..."
# Kernel Hardening
sudo sed -i 's/GRUB_CMDLINE_LINUX_DEFAULT="[^"]*/& mitigations=on nosmt slab_nomerge/' /etc/default/grub
check_success "Kernel hardening"
sudo grub-mkconfig -o /boot/grub/grub.cfg
check_success "GRUB configuration updated"

-----------------------



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
check_success "AIDE check completed"

# Reboot for changes to take effect
echo "Rebooting system..."
sudo reboot
  







----------------------------------------------------------------------





#Missing bash so we can edit 



#Done - good like this, already tested (unless you know a better way)
echo "bind \"^C\": copy" >> ~/.inputrc
echo "bind \"^V\": paste" >> ~/.inputrc
echo "bind \"^Z\": suspend" >> ~/.inputrc

xfce4-terminal &


#Done - good like this, already tested (unless you know a better way)
xrandr -q
alias br='xrandr --output eDP1 --brightness'
br 0.4


#Done - good like this, already tested (unless you know a better way)
synclient TouchpadOff=1


#Done - good like this, already tested (unless you know a better way)
sudo rm -f /var/lib/pacman/db.lck


#Still to be done
#install a browser - chrome or one that deals well with webgl so i can work on figma -
#open 5 tabs - with these urls already opened and logged in
#a nethod for me to add remove tabs in the future - also logged user pass


#Still to be done
#open firefox in private mode, and check all the variables on that advanced part to see if its hardened as much as possible (several fragile points there)


#Still to be done
#fix audio certify that mic is working - install dictation - test - 


#I need to edit a tempered pacman.conf to be the best possible one adding mirrors including darker ones for pentesting, etc
nano /etc/pacman.conf    (clean below)


#Done - good like this, already tested (unless you know a better way)
pacman-key --init
gpg --check-trustdb
pacman --Syy
pacman -Syu
pacman -Sy
pacman -S --noconfirm linux
pacman -S --noconfirm linux-firmware
pacman -S --noconfirm linux-lts
pacman -S linux-firmware
sudo mkinitcpio -p linux
sudo pacman -Syu
lsmod | grep xhci_pci
lsmod | grep ast
lsmod | grep aic94xx
lsmod | grep wd719x
dmesg | grep -i firmware
dmesg | grep -i xhci_pci
pacman -S --noconfirm volatility
pacman -S --noconfirm memdump
pacman -S --noconfirm lios
pacman -S --noconfirm crash
pacman -S --noconfirm metasploit
pacman -S --noconfirm dirty_cow
pacman -S --noconfirm stage
pacman -S --noconfirm gdisk
pacman -S --noconfirm grub
pacman -S --noconfirm mkinitcpio
pacman -S --noconfirm pulseaudio

#Can be improved
sudo pacman -Syu --noconfirm && sudo pacman -Syy --noconfirm
sudo pacman -S --noconfirm \
    thunar gvfs ntfs-3g udisks2 thunar-volman gvfs-mtp gvfs-smb
sudo systemctl enable --now udisks2.service
echo "Installed packages:"
pacman -Q thunar gvfs ntfs-3g udisks2 thunar-volman gvfs-mtp gvfs-smb
echo "udisks2 service status:"
systemctl status udisks2.service --no-pager


#Please add more, if you know
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


#Can be improved Im sure:
sudo systemd-analyze blame


#Please add more, if you know  Can be improved
sudo echo "nameserver 8.8.8.8" | sudo tee /etc/resolv.conf


# Disable unnecessary overlay features Can be improved - Malware do a LOT of overlay - on apps, on site, etc - whatever we can add to avoid it, the better
sudo sed -i 's/ overlay//g' /etc/X11/xorg.conf


# Disable unnecessary overlay features Can be improved - Malware do a LOT of overlay - on apps, on site, etc - whatever we can add to avoid it, the better
sudo sed -i 's/ allow-overlay//g' /etc/security/limits.conf


#Can be improved Im sure: Use a secure overlay network
sudo pacman -S --noconfirm openvpn
sudo systemctl enable openvpn

#I dont want to add all of them on this script because we can add on the second one. This first is supposed to run fast so I Can start to work. Then I run the second. Install basic security tools
sudo pacman -S --noconfirm ufw apparmor

#Can be improved Im sure: Set up a firewall
sudo ufw enable
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow ssh
sudo ufw allow http
sudo ufw allow https
sudo ufw reload


#Can be improved Im sure: nable AppArmor
sudo systemctl enable apparmor
sudo systemctl start apparmor
sudo aa-enforce /etc/apparmor.d/*

#Can be improved Im sure:Install yay if not already installed
if ! command -v yay &> /dev/null; then
  sudo pacman -S --needed git base-devel --noconfirm
  git clone https://aur.archlinux.org/yay.git
  cd yay
  makepkg -si --noconfirm
  cd ..
  rm -rf yay
fi

#Can be improved Im sure:Install whisper using yay
yay -S whisper --noconfirm

#Can be improved Im sure:Update and patch the system
sudo pacman -Syu --noconfirm

#Can be improved Im sure:Patch and harden the kernel
sudo pacman -S --noconfirm linux-hardened linux-hardened-headers


