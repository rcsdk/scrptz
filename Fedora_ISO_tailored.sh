#!/bin/bash
# ============================================
# FEDORA LIVE ISO HARDENING SCRIPT (FIXED)
# ============================================
# Fixed issues:
# 1. Added mandatory repository configuration
# 2. Improved error handling
# 3. Added debug logging

# Verify root
if [ "$(id -u)" -ne 0 ]; then
  echo "This script must be run as root" >&2
  exit 1
fi

# Initialize variables
ISO_NAME="Fedora-Secure-Live"
WORK_DIR="/tmp/fedora-secure"
KS_FILE="${WORK_DIR}/secure-live.ks"
LOG_FILE="/var/log/secure-iso-build.log"

# Cleanup old files
rm -rf "${WORK_DIR}"
mkdir -p "${WORK_DIR}" || {
  echo "Failed to create working directory" >&2
  exit 1
}

# Create proper kickstart file
create_kickstart() {
  cat > "${KS_FILE}" << 'EOL'
# Minimal Secure Fedora Live ISO
lang en_US.UTF-8
keyboard us
timezone UTC
selinux --enforcing
firewall --enabled --service=ssh

# REQUIRED REPOSITORIES
repo --name=fedora --mirrorlist=https://mirrors.fedoraproject.org/mirrorlist?repo=fedora-$releasever&arch=$basearch
repo --name=updates --mirrorlist=https://mirrors.fedoraproject.org/mirrorlist?repo=updates-released-f$releasever&arch=$basearch

# Disk layout
clearpart --all --initlabel

# Security packages
%packages
@core
firewalld
fail2ban
wireguard-tools
dnscrypt-proxy
-aic94xx-firmware
-atmel-firmware
-b43-openfwwf
-bfa-firmware
-ipw2100-firmware
-ipw2200-firmware
-ivtv-firmware
-libertas-usb8388-firmware
-ql2100-firmware
-ql2200-firmware
-ql23xx-firmware
-ql2400-firmware
-ql2500-firmware
-zd1211-firmware
%end

# Post-install hardening
%post
# Kernel hardening
echo "kernel.kptr_restrict=2" >> /etc/sysctl.d/99-security.conf
echo "net.ipv4.tcp_syncookies=1" >> /etc/sysctl.d/99-security.conf

# Disable risky services
systemctl mask avahi-daemon cups bluetooth ModemManager

# Secure defaults
chmod 750 /etc/sudoers.d
chmod 600 /etc/crontab

# Create verification checksums
sha256sum /etc/fail2ban/jail.* > /etc/fail2ban/checksums.sha256
%end
EOL
}

# Build the ISO
build_iso() {
  echo "Building ISO (this may take 10-20 minutes)..."
  
  # Clear old log
  > "${LOG_FILE}"
  
  livecd-creator \
    --config="${KS_FILE}" \
    --fslabel="${ISO_NAME}" \
    --cache=/var/cache/live \
    --logfile="${LOG_FILE}" || {
    echo -e "\nISO build failed. Last 20 lines of log:"
    tail -20 "${LOG_FILE}"
    exit 1
  }

  # Add security features
  isohybrid "${ISO_NAME}.iso"
  implantisomd5 "${ISO_NAME}.iso"
}

# Main execution
echo "Starting Fedora Secure Live ISO creation..."
create_kickstart
build_iso

echo -e "\nSuccessfully created hardened ISO: ${ISO_NAME}.iso"
echo "Size: $(du -h ${ISO_NAME}.iso | cut -f1)"
echo "SHA256: $(sha256sum ${ISO_NAME}.iso)"
echo "Verification: checkisomd5 ${ISO_NAME}.iso"
