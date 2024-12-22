
#!/bin/bash

# Install yay if not already installed
if ! command -v yay &> /dev/null; then
  sudo pacman -S --needed git base-devel --noconfirm
  git clone https://aur.archlinux.org/yay.git
  cd yay
  makepkg -si --noconfirm
  cd ..
  rm -rf yay
fi

# Install whisper using yay
yay -S whisper --noconfirm

# Update and patch the system
sudo pacman -Syu --noconfirm

# Patch and harden the kernel
sudo pacman -S --noconfirm linux-hardened linux-hardened-headers

# Install additional security tools
sudo pacman -S --noconfirm clamav rkhunter

# Scan for malware and rootkits
sudo freshclam
sudo rkhunter --propupd
sudo clamscan -r /
sudo rkhunter --checkall
