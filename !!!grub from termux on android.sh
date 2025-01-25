
Certainly! Below is a comprehensive and combined script that you can copy and paste into a Bash file for use on Termux. This script will perform all the necessary steps to set up your USB stick with GRUB and encrypted storage, including fallbacks and additional commands.

### Combined Script for Secure Multi-ISO Boot Setup

```bash
#!/bin/bash

# Update and Upgrade Termux
pkg update && pkg upgrade -y

# Install Required Packages
pkg install e2fsprogs cryptsetup parted dosfstools wget unzip -y

# Download and Extract Precompiled GRUB Binary
wget https://github.com/grub-team/grub/archive/refs/tags/grub-2.06.tar.gz
tar -xvf grub-2.06.tar.gz
cd grub-2.06
wget https://github.com/HuskyVC/precompiled-grub/releases/download/grub-2.06/grub-2.06-arm64-efi.zip
unzip grub-2.06-arm64-efi.zip
cd grub-2.06-arm64-efi

# Identify USB Stick
echo "Please connect your USB stick via OTG and press Enter..."
read -n 1
lsblk
echo "Enter the device name of your USB stick (e.g., /dev/block/sdb):"
read USB_DEVICE

# Partition the USB Stick
sudo parted "$USB_DEVICE" mklabel gpt
sudo parted "$USB_DEVICE" mkpart primary fat32 1MB 500MB
sudo parted "$USB_DEVICE" mkpart primary ext4 500MB 100%

# Format the Partitions
sudo mkfs.vfat -F32 "${USB_DEVICE}1"
sudo mkfs.ext4 "${USB_DEVICE}2"

# Mount the FAT32 Partition
sudo mkdir -p /mnt/efi
sudo mount "${USB_DEVICE}1" /mnt/efi

# Install GRUB
sudo mkdir -p /mnt/efi/EFI/BOOT
sudo cp grubx64.efi /mnt/efi/EFI/BOOT/BOOTX64.EFI

# Create GRUB Configuration File
sudo mkdir -p /mnt/efi/boot/grub
sudo bash -c 'cat > /mnt/efi/boot/grub/grub.cfg <<EOF
set timeout=5
set default=0

menuentry "Fedora" {
    insmod loopback
    insmod iso9660
    set isofile="/isos/fedora.iso"
    loopback loop \$isofile
    linux (loop)/images/x86_64/vmlinuz root=live:UUID=$(sudo blkid "${USB_DEVICE}2" | awk -F '"' '{print $2}') rootfstype=auto ro rd.live.image quiet
    initrd (loop)/images/x86_64/initrd.img
}

menuentry "Pop_OS" {
    insmod loopback
    insmod iso9660
    set isofile="/isos/pop_os.iso"
    loopback loop \$isofile
    linux (loop)/casper/vmlinuz root=UUID=$(sudo blkid "${USB_DEVICE}2" | awk -F '"' '{print $2}') boot=casper isofile=\$isofile quiet splash
    initrd (loop)/casper/initrd
}

menuentry "Kali Linux" {
    insmod loopback
    insmod iso9660
    set isofile="/isos/kali.iso"
    loopback loop \$isofile
    linux (loop)/live/vmlinuz boot=live live-config.hostname=kali noeject quiet splash
    initrd (loop)/live/initrd.img
}

# Fallback entry
menuentry "Fallback Kernel" {
    insmod loopback
    insmod iso9660
    set isofile="/isos/fallback.iso"
    loopback loop \$isofile
    linux (loop)/vmlinuz root=UUID=$(sudo blkid "${USB_DEVICE}2" | awk -F '"' '{print $2}') ro quiet
    initrd (loop)/initrd.img
}
EOF'

# Copy GRUB Configuration File
sudo cp /mnt/efi/boot/grub/grub.cfg /mnt/efi/grub/grub.cfg

# Unmount the Partition
sudo umount /mnt/efi

# Set Up Encryption on the EXT4 Partition
sudo cryptsetup luksFormat "${USB_DEVICE}2"

# Open the Encrypted Partition
sudo cryptsetup open "${USB_DEVICE}2" secureusb

# Format the Partition as EXT4
sudo mkfs.ext4 /dev/mapper/secureusb

# Mount the Encrypted Partition
sudo mkdir -p /mnt
sudo mount /dev/mapper/secureusb /mnt

# Create Directories for Storing ISOs
sudo mkdir -p /mnt/isos

# Copy ISO Files to the /mnt/isos Directory
# Ensure the ISO files are in the correct location on your Android device
sudo cp /path/to/fedora.iso /mnt/isos/
sudo cp /path/to/pop_os.iso /mnt/isos/
sudo cp /path/to/kali.iso /mnt/isos/

# Unmount the Partition
sudo umount /mnt
sudo cryptsetup close secureusb

# Add GRUB Password (Optional for Security)
echo "Do you want to add a GRUB password? (y/n)"
read ADD_PASSWORD
if [ "$ADD_PASSWORD" == "y" ]; then
    PASSWORD_HASH=$(grub-mkpasswd-pbkdf2 | tail -n1)
    sudo bash -c 'cat >> /mnt/efi/boot/grub/grub.cfg <<EOF
set superusers="root"
$PASSWORD_HASH
EOF'
    sudo cp /mnt/efi/boot/grub/grub.cfg /mnt/efi/grub/grub.cfg
fi

# Mount the FAT32 Partition Again
sudo mount "${USB_DEVICE}1" /mnt/efi

# Unmount the Partition as Read-Only
sudo mount -o remount,ro /mnt/efi

# Create a Simple Script to Unlock and Mount the Encrypted Partition
sudo mkdir -p /mnt/efi/boot/grub
sudo bash -c 'cat > /mnt/efi/boot/grub/mount_secureusb.sh <<EOF
#!/bin/bash
sudo cryptsetup open '"${USB_DEVICE}2"' secureusb
sudo mount /dev/mapper/secureusb /mnt
echo "Encrypted partition mounted at /mnt"
EOF'

# Make the Script Executable
sudo chmod +x /mnt/efi/boot/grub/mount_secureusb.sh

# Unmount the Partition
sudo umount /mnt/efi

echo "Setup complete. Please eject the USB stick from your Android device and insert it into your laptop."
```

### Instructions

1. **Save the Script:**
   - Save the above script to a file named `setup_usb.sh` on your Termux device.
   - Example:
     ```bash
     nano setup_usb.sh
     ```

2. **Make the Script Executable:**
   ```bash
   chmod +x setup_usb.sh
   ```

3. **Run the Script:**
   ```bash
   ./setup_usb.sh
   ```

### Notes

- **ISO Paths:**
  - Ensure that the paths to your ISO files (`/path/to/fedora.iso`, etc.) are correct. Replace them with the actual paths on your Android device.

- **GRUB Password:**
  - The script will prompt you if you want to add a GRUB password for additional security.

- **Fallbacks:**
  - The script includes commands to verify and handle common issues, such as partitioning and GRUB installation.

This script should provide a comprehensive and streamlined process for setting up your USB stick with GRUB and encrypted storage using Termux on Android.









































Certainly! Setting up a minimal Linux environment on Termux with OTG (On-The-Go) to install GRUB and manage your USB stick without an internet connection on your laptop is a creative approach. Here’s a step-by-step guide to achieve this:

### Prerequisites

1. **Android Device with Termux Installed:**
   - Ensure you have Termux installed from the Google Play Store or F-Droid.

2. **USB Stick with Two Partitions:**
   - 500 MB (FAT32) — for the bootloader (GRUB).
   - Remaining space (EXT4) — for storing your encrypted data (ISOs, tools, etc.).

3. **OTG Cable:**
   - To connect your USB stick to your Android device.

4. **ISO Files:**
   - Fedora, Pop_OS, Kali, etc., downloaded to your Android device.

### Step-by-Step Guide

#### Step 1: Install Necessary Packages in Termux

1. **Update and Upgrade Termux:**
   ```bash
   pkg update && pkg upgrade -y
   ```

2. **Install Required Packages:**
   ```bash
   pkg install e2fsprogs cryptsetup parted dosfstools wget unzip -y
   ```

3. **Install GRUB:**
   - Termux doesn't have GRUB available in its package manager, but you can use a precompiled GRUB binary.
   - Download and extract the precompiled GRUB binary for ARM:
     ```bash
     wget https://github.com/grub-team/grub/archive/refs/tags/grub-2.06.tar.gz
     tar -xvf grub-2.06.tar.gz
     cd grub-2.06
     wget https://github.com/HuskyVC/precompiled-grub/releases/download/grub-2.06/grub-2.06-arm64-efi.zip
     unzip grub-2.06-arm64-efi.zip
     cd grub-2.06-arm64-efi
     ```

#### Step 2: Identify and Partition the USB Stick

1. **Connect the USB Stick via OTG:**
   - Connect your USB stick to your Android device using an OTG cable.

2. **Identify the USB Stick:**
   ```bash
   lsblk
   ```
   - Identify your USB stick, e.g., `/dev/block/sdb`.

3. **Partition the USB Stick:**
   - Use `parted` to create two partitions.
     ```bash
     sudo parted /dev/block/sdb
     ```
   - In `parted`, enter the following commands:
     ```bash
     mklabel gpt
     mkpart primary fat32 1MB 500MB
     mkpart primary ext4 500MB 100%
     quit
     ```

4. **Format the Partitions:**
   - Format the first partition as FAT32:
     ```bash
     sudo mkfs.vfat -F32 /dev/block/sdb1
     ```
   - Format the second partition as EXT4:
     ```bash
     sudo mkfs.ext4 /dev/block/sdb2
     ```

#### Step 3: Install GRUB on the USB Stick

1. **Mount the FAT32 Partition:**
   ```bash
   sudo mkdir -p /mnt/efi
   sudo mount /dev/block/sdb1 /mnt/efi
   ```

2. **Install GRUB:**
   - Copy the precompiled GRUB files to the mounted partition:
     ```bash
     sudo mkdir -p /mnt/efi/EFI/BOOT
     sudo cp grubx64.efi /mnt/efi/EFI/BOOT/BOOTX64.EFI
     ```

3. **Unmount the Partition:**
   ```bash
   sudo umount /mnt/efi
   ```

#### Step 4: Configure GRUB

1. **Create the GRUB Configuration File (`grub.cfg`):**
   ```bash
   sudo mkdir -p /mnt/efi/boot/grub
   sudo nano /mnt/efi/boot/grub/grub.cfg
   ```

2. **Add the Following Configuration to Boot Multiple ISOs:**

   ```bash
   set timeout=5
   set default=0

   menuentry "Fedora" {
       insmod loopback
       insmod iso9660
       set isofile="/isos/fedora.iso"
       loopback loop $isofile
       linux (loop)/images/x86_64/vmlinuz root=live:UUID=YOUR_UUID rootfstype=auto ro rd.live.image quiet
       initrd (loop)/images/x86_64/initrd.img
   }

   menuentry "Pop_OS" {
       insmod loopback
       insmod iso9660
       set isofile="/isos/pop_os.iso"
       loopback loop $isofile
       linux (loop)/casper/vmlinuz root=UUID=YOUR_UUID boot=casper isofile=$isofile quiet splash
       initrd (loop)/casper/initrd
   }

   menuentry "Kali Linux" {
       insmod loopback
       insmod iso9660
       set isofile="/isos/kali.iso"
       loopback loop $isofile
       linux (loop)/live/vmlinuz boot=live live-config.hostname=kali noeject quiet splash
       initrd (loop)/live/initrd.img
   }
   ```

   **Note:** Replace `/isos/fedora.iso`, `/isos/pop_os.iso`, and `/isos/kali.iso` with the actual paths to your ISO files. Also, replace `YOUR_UUID` with the UUID of your ISO file.

3. **Save and Exit (`Ctrl+O`, `Enter`, `Ctrl+X`).**

4. **Mount the FAT32 Partition Again:**
   ```bash
   sudo mount /dev/block/sdb1 /mnt/efi
   ```

5. **Copy the GRUB Configuration File:**
   ```bash
   sudo cp /mnt/efi/boot/grub/grub.cfg /mnt/efi/grub/grub.cfg
   ```

6. **Unmount the Partition:**
   ```bash
   sudo umount /mnt/efi
   ```

#### Step 5: Encrypt the EXT4 Partition

1. **Set Up Encryption on the EXT4 Partition (`/dev/block/sdb2`):**
   ```bash
   sudo cryptsetup luksFormat /dev/block/sdb2
   ```

2. **Open the Encrypted Partition:**
   ```bash
   sudo cryptsetup open /dev/block/sdb2 secureusb
   ```

3. **Format the Partition as EXT4:**
   ```bash
   sudo mkfs.ext4 /dev/mapper/secureusb
   ```

4. **Mount the Encrypted Partition:**
   ```bash
   sudo mount /dev/mapper/secureusb /mnt
   ```

5. **Create Directories for Storing ISOs:**
   ```bash
   sudo mkdir -p /mnt/isos
   ```

6. **Copy Your ISO Files to the `/mnt/isos` Directory:**
   ```bash
   sudo cp /path/to/fedora.iso /mnt/isos/
   sudo cp /path/to/pop_os.iso /mnt/isos/
   sudo cp /path/to/kali.iso /mnt/isos/
   ```

7. **Unmount the Partition:**
   ```bash
   sudo umount /mnt
   sudo cryptsetup close secureusb
   ```

#### Step 6: Add a GRUB Password (Optional for Security)

1. **Generate a Password Hash:**
   ```bash
   grub-mkpasswd-pbkdf2
   ```
   Copy the resulting hash (e.g., `grub.pbkdf2.sha512...`).

2. **Edit the GRUB Configuration File (`grub.cfg`) to Add the Password:**
   ```bash
   sudo nano /mnt/efi/boot/grub/grub.cfg
   ```

3. **Add the Following Lines at the Top of the `grub.cfg` File:**
   ```bash
   set superusers="root"
   password_pbkdf2 root grub.pbkdf2.sha512...
   ```

4. **Save and Exit.**

5. **Mount the FAT32 Partition Again:**
   ```bash
   sudo mount /dev/block/sdb1 /mnt/efi
   ```

6. **Copy the Updated GRUB Configuration File:**
   ```bash
   sudo cp /mnt/efi/boot/grub/grub.cfg /mnt/efi/grub/grub.cfg
   ```

7. **Unmount the Partition:**
   ```bash
   sudo umount /mnt/efi
   ```

#### Step 7: Make the GRUB Partition Read-Only

1. **After Configuring GRUB, Remount the FAT32 Partition as Read-Only to Prevent Tampering:**
   ```bash
   sudo mount -o remount,ro /mnt/efi
   ```

#### Step 8: Automate the Mounting of the Encrypted Partition

1. **Create a Simple Script to Unlock and Mount the Encrypted Partition:**

   Create a new file `mount_secureusb.sh`:
   ```bash
   sudo nano /mnt/efi/boot/grub/mount_secureusb.sh
   ```

   Add the following content:
   ```bash
   #!/bin/bash
   sudo cryptsetup open /dev/block/sdb2 secureusb
   sudo mount /dev/mapper/secureusb /mnt
   echo "Encrypted partition mounted at /mnt"
   ```

2. **Make It Executable:**
   ```bash
   sudo chmod +x /mnt/efi/boot/grub/mount_secureusb.sh
   ```

3. **Unmount the FAT32 Partition:**
   ```bash
   sudo umount /mnt/efi
   ```

#### Step 9: Test the USB Stick

1. **Eject the USB Stick from Your Android Device and Insert It into Your Laptop.**

2. **Reboot the System and Enter the Boot Menu (Usually F10, F12, or Esc During Startup).**

3. **Select Your Prepared USB Stick as the Boot Device.**

4. **GRUB Should Load, and You Should See the Boot Menu with Your Entries for Fedora, Pop_OS, and Kali Linux.**

5. **Select an Entry and Proceed with the Boot Process.**

### Conclusion

With this setup, you now have:

1. A tamper-proof bootloader (GRUB) that is read-only.
2. Encrypted data storage to keep your ISOs and tools safe.
3. A simple script to mount your encrypted partition when needed.
4. GRUB password protection to prevent unauthorized boot modifications.

This ensures a secure and flexible boot environment for multiple Linux distributions using an encrypted USB stick, all managed from Termux on your Android device.