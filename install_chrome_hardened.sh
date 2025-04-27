#!/bin/bash

# Exit immediately if a command exits with a non-zero status.
set -e
# Treat unset variables as an error when substituting.
set -u
# Prevent errors in a pipeline from being masked.
set -o pipefail

# --- Configuration ---
CHROME_POLICY_DIR="/etc/opt/chrome/policies/managed"
CHROME_POLICY_FILE="${CHROME_POLICY_DIR}/harden_chrome.json"
CHROME_REPO_KEY_URL="https://dl.google.com/linux/linux_signing_key.pub"
CHROME_REPO_KEY_PATH="/etc/apt/keyrings/google-chrome-keyring.gpg"
CHROME_REPO_SOURCE_FILE="/etc/apt/sources.list.d/google-chrome.list"
APPARMOR_PROFILE_PATH="/etc/apparmor.d/usr.bin.google-chrome"

# --- Helper Functions ---
log_info() {
    echo "[*] $1"
}

log_warn() {
    echo "[!] WARNING: $1"
}

log_error() {
    echo "[X] ERROR: $1" >&2
    exit 1
}

# --- Main Logic Functions ---

check_root() {
    if [[ $EUID -ne 0 ]]; then
       log_error "This script must be run as root. Use sudo."
    fi
}

update_system() {
    log_info "Updating system packages..."
    apt update && apt upgrade -y
}

install_dependencies() {
    log_info "Installing dependencies..."
    # software-properties-common might not be strictly needed now without add-apt-repository
    apt install -y curl wget gpg coreutils apt-transport-https
}

add_chrome_repo() {
    log_info "Adding Google Chrome repository..."

    if [[ -f "$CHROME_REPO_SOURCE_FILE" ]]; then
        log_info "Google Chrome repository source file already exists. Skipping addition."
        return
    fi

    # Download and store the GPG key correctly
    log_info "Downloading and adding Google Chrome GPG key..."
    mkdir -p "$(dirname "$CHROME_REPO_KEY_PATH")"
    curl -fsSL "$CHROME_REPO_KEY_URL" | gpg --dearmor -o "$CHROME_REPO_KEY_PATH"
    chmod 644 "$CHROME_REPO_KEY_PATH"

    # Add the repository source, referencing the key
    log_info "Adding Google Chrome repository source..."
    echo "deb [arch=amd64 signed-by=$CHROME_REPO_KEY_PATH] http://dl.google.com/linux/chrome/deb/ stable main" > "$CHROME_REPO_SOURCE_FILE"

    log_info "Updating package list after adding repo..."
    apt update
}

install_chrome() {
    if command -v google-chrome-stable &> /dev/null; then
        log_info "Google Chrome is already installed. Skipping installation."
        return
    fi

    log_info "Installing Google Chrome stable..."
    apt install -y google-chrome-stable
    log_info "Google Chrome installation complete."
}

apply_chrome_policies() {
    log_info "Applying custom Google Chrome policies..."

    mkdir -p "$CHROME_POLICY_DIR"

    log_info "Creating policy file: $CHROME_POLICY_FILE"
    cat <<EOF > "$CHROME_POLICY_FILE"
{
  "DefaultBrowserSettingEnabled": false,
  "IncognitoModeAvailability": 1, /* 0=Enabled, 1=Disabled, 2=Forced */
  "PasswordManagerEnabled": false,
  "SafeBrowsingEnabled": true,
  "SearchSuggestEnabled": false,
  "SpellCheckServiceEnabled": false,
  "SyncDisabled": true,
  "TranslateEnabled": false,
  "MetricsReportingEnabled": false,
  "AutofillAddressEnabled": false,
  "AutofillCreditCardEnabled": false,
  "RestoreOnStartup": 4, /* 1=Last session, 4=Specific pages, 5=New Tab Page */
  "RestoreOnStartupURLs": ["about:blank"], /* Use about:blank for privacy, or your preferred secure page */
  "CommandLineFlagSecurityWarningsEnabled": true,
  "HardwareAccelerationModeEnabled": false, /* Often disabled for stability/security, can impact performance */
  "BlockThirdPartyCookies": true, /* Added for better privacy */
  "ClearBrowsingDataOnExit": [
      "browsing_history",
      "download_history",
      "cookies",
      "cached_images_and_files",
      "passwords",
      "autofill",
      "site_settings",
      "hosted_app_data"
  ] /* Optional: Clears data on exit */
}
EOF
    # Note: Check Chrome Enterprise Policy List for up-to-date policy names and values:
    # https://chromeenterprise.google/policies/

    log_info "Setting permissions for policy file..."
    chmod 644 "$CHROME_POLICY_FILE"
    chown root:root "$CHROME_POLICY_FILE"
}

apply_apparmor_profile() {
    if ! command -v apparmor_parser &> /dev/null; then
        log_warn "AppArmor does not appear to be installed or 'apparmor_parser' is not in PATH. Skipping AppArmor profile application."
        return
    fi

    log_info "Applying AppArmor profile for Chrome..."
    # Slightly refined profile - removed net_admin capability
    cat <<EOF > "$APPARMOR_PROFILE_PATH"
#include <tunables/global>

profile google-chrome /usr/bin/google-chrome-stable flags=(attach_disconnected) {
  #include <abstractions/base>
  #include <abstractions/consoles>
  #include <abstractions/dbus-session>
  #include <abstractions/dbus-strict>
  #include <abstractions/dconf>
  #include <abstractions/fonts>
  #include <abstractions/freedesktop.org>
  #include <abstractions/gnome>
  #include <abstractions/nameservice>
  #include <abstractions/user-tmp>
  #include <abstractions/xdg-user-dirs>

  # Chrome specific paths
  /opt/google/chrome*/chrome rmix,
  /opt/google/chrome*/chrome-sandbox rx,
  /opt/google/chrome*/locales/** r,
  /opt/google/chrome*/nacl_helper rx,
  /opt/google/chrome*/nacl_helper_bootstrap rx,
  /opt/google/chrome*/**.pak r,
  /opt/google/chrome*/**.png r,
  /opt/google/chrome*/**.json r,
  /opt/google/chrome*/swiftshader/** r, # Software rendering
  /opt/google/chrome/lib*.so mr,

  # User directories
  owner @{HOME}/.config/google-chrome*/ r,
  owner @{HOME}/.config/google-chrome/** rwk,
  owner @{HOME}/.cache/google-chrome*/ r,
  owner @{HOME}/.cache/google-chrome/** rwk,
  owner @{HOME}/.local/share/google-chrome*/ r, # Possible location for user data
  owner @{HOME}/.local/share/google-chrome/** rwk,
  owner @{HOME}/Downloads/ r, # Allow access to Downloads
  owner @{HOME}/Downloads/** rwk,

  # System paths needed
  /dev/dri/ r,
  /dev/dri/card* rw,
  /dev/shm/ r,
  owner /dev/shm/* rwk,
  /etc/opt/chrome/policies/** r,
  /sys/devices/pci*/**/config r, # Hardware info access
  /sys/devices/system/cpu/ r,
  /sys/devices/system/cpu/cpu*/** r,
  /proc/filesystems r,
  /proc/meminfo r,
  /proc/stat r,
  /proc/sys/crypto/fips_enabled r,
  /proc/uptime r,
  /etc/lsb-release r, # OS identification
  /etc/timezone r, # Timezone info

  # Network
  network inet stream,
  network inet6 stream,
  network netlink raw,
  network netlink dgram,
  capability net_raw, # Might be needed for some protocols (e.g., ping within dev tools). Monitor if needed.

  # D-Bus (needed for desktop integration)
  # Include abstractions/dbus-session and abstractions/dbus-strict above

  # Denials (Important Hardening)
  deny /etc/passwd r,
  deny /etc/shadow r,
  deny /etc/group r,
  deny /etc/gshadow r,
  deny /etc/sudoers r,
  deny /etc/sudoers.d/ r,
  deny /root/** rwk,
  deny @{HOME}/.ssh/** rwk,

  # Deny ptrace
  deny ptrace (read, trace),

  # Allow necessary capabilities
  capability sys_admin, # Needed for sandboxing? Often required. Monitor closely.
  capability chown,     # Sometimes needed for file operations within profile dirs.
  capability setgid,    # Needed by sandbox
  capability setuid,    # Needed by sandbox

  # Allow read access to shared libraries
  /usr/lib/** rm,
  /lib/** rm,

}

# Add profile for the sandbox if needed (often handled by Chrome itself)
# profile chrome-sandbox /opt/google/chrome/chrome-sandbox {
#   # Minimal permissions for the sandbox binary
#   # ...
# }

EOF

    log_info "Reloading AppArmor profiles..."
    apparmor_parser -r "$APPARMOR_PROFILE_PATH" || log_warn "Failed to reload AppArmor profile. It might contain errors or AppArmor might not be managing Chrome."
    log_warn "The applied AppArmor profile is restrictive and MAY BREAK some Chrome features (e.g., certain web apps, plugins, file access outside Downloads). Test thoroughly!"

}

finalize() {
    log_info "Installation and hardening of Google Chrome completed."
    log_info "Applied policies will take effect on the next Chrome launch."
    log_info "Review applied AppArmor profile ($APPARMOR_PROFILE_PATH) and test Chrome functionality."
}

# --- Script Execution ---

check_root
update_system
install_dependencies
add_chrome_repo
install_chrome
apply_chrome_policies
apply_apparmor_profile # This is optional and potentially disruptive, keep the warning
finalize

exit 0
