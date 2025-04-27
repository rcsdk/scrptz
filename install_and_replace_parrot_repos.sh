#!/bin/bash

# === Configuration ===
SOURCES_LIST_FILE="/etc/apt/sources.list"
SOURCES_LIST_D_DIR="/etc/apt/sources.list.d"
# Backup location will be created inside /etc/apt/
BACKUP_TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_DIR="/etc/apt/sources.list.bak_${BACKUP_TIMESTAMP}"

# === Script Logic ===

# --- Check if running as root ---
if [ "$(id -u)" -ne 0 ]; then
  echo "Error: This script must be run as root (use sudo)." >&2
  exit 1
fi

# --- Check for lsb_release command ---
if ! command -v lsb_release &> /dev/null; then
    echo "Error: 'lsb_release' command not found." >&2
    echo "Please install it first: sudo apt update && sudo apt install lsb-release" >&2
    exit 1
fi

# --- Determine OS Codename ---
OS_CODENAME=$(lsb_release -cs)
if [ -z "$OS_CODENAME" ]; then
    echo "Error: Could not automatically determine the Parrot OS codename." >&2
    echo "Cannot proceed without the codename (e.g., 'lory', 'rolling')." >&2
    exit 1
fi
echo "Detected Parrot OS codename: $OS_CODENAME"
echo ""

# --- Define Default Parrot Sources Content ---
# Based on typical Parrot sources structure. Includes standard repos and security.
# Backports are usually optional and are commented out here by default.
# Includes non-free-firmware component which is standard on newer Debian-based systems.
DEFAULT_PARROT_SOURCES=$(cat <<EOF
#------------------------------------------------------------------------------#
# Official Parrot Security Repository (${OS_CODENAME}) #
#------------------------------------------------------------------------------#

# Main repository
deb https://deb.parrot.sh/parrot/ ${OS_CODENAME} main contrib non-free non-free-firmware
# deb-src https://deb.parrot.sh/parrot/ ${OS_CODENAME} main contrib non-free non-free-firmware

# Security updates repository
deb https://deb.parrot.sh/direct/parrot/ ${OS_CODENAME}-security main contrib non-free non-free-firmware
# deb-src https://deb.parrot.sh/direct/parrot/ ${OS_CODENAME}-security main contrib non-free non-free-firmware

# Optional Backports repository (uncomment if needed)
# deb https://deb.parrot.sh/parrot/ ${OS_CODENAME}-backports main contrib non-free non-free-firmware
# deb-src https://deb.parrot.sh/parrot/ ${OS_CODENAME}-backports main contrib non-free non-free-firmware

#------------------------------------------------------------------------------#
# End of default Parrot sources                                               #
#------------------------------------------------------------------------------#
EOF
)

# --- Confirmation Prompt ---
echo "!!! WARNING !!!"
echo "This script will attempt to reset your APT sources to the Parrot defaults for '$OS_CODENAME'."
echo "It will perform the following actions:"
echo "1. Create a backup directory: $BACKUP_DIR"
echo "2. Back up the current '$SOURCES_LIST_FILE' (if it exists) to the backup directory."
echo "3. Back up all files currently in '$SOURCES_LIST_D_DIR' (if any exist) to the backup directory."
echo "4. OVERWRITE '$SOURCES_LIST_FILE' with the default Parrot sources shown above."
echo "5. REMOVE all files ending in '.list' from '$SOURCES_LIST_D_DIR' to ensure a clean state."
echo "   (Other files in that directory, if any, will be left untouched but backed up)."
echo "6. Run 'apt update' at the end."
echo ""
read -p "ARE YOU SURE you want to proceed? (y/N): " confirmation
if [[ ! "$confirmation" =~ ^[Yy]$ ]]; then
    echo "Aborted by user."
    exit 0
fi
echo ""

# --- Create Backup Directory ---
echo "Creating backup directory: $BACKUP_DIR"
mkdir -p "$BACKUP_DIR"
if [ $? -ne 0 ]; then
    echo "Error: Failed to create backup directory '$BACKUP_DIR'." >&2
    echo "Please check permissions in /etc/apt/." >&2
    exit 1
fi

# --- Backup Existing Files ---
echo "Backing up current configuration..."

# Backup sources.list
if [ -f "$SOURCES_LIST_FILE" ]; then
    echo " -> Backing up $SOURCES_LIST_FILE to $BACKUP_DIR/"
    cp "$SOURCES_LIST_FILE" "$BACKUP_DIR/" || { echo "Error backing up $SOURCES_LIST_FILE." >&2; exit 1; }
else
    echo " -> $SOURCES_LIST_FILE does not exist, skipping backup."
fi

# Backup sources.list.d contents
if [ -d "$SOURCES_LIST_D_DIR" ] && [ "$(ls -A $SOURCES_LIST_D_DIR)" ]; then
     echo " -> Backing up contents of $SOURCES_LIST_D_DIR to $BACKUP_DIR/"
     # Copy contents (-a preserves permissions/ownership)
     cp -a "$SOURCES_LIST_D_DIR/." "$BACKUP_DIR/" || { echo "Error backing up $SOURCES_LIST_D_DIR." >&2; exit 1; }
else
    echo " -> $SOURCES_LIST_D_DIR is empty or does not exist, skipping backup."
fi
echo "Backup complete."
echo ""

# --- Overwrite sources.list ---
echo "Writing default Parrot sources to $SOURCES_LIST_FILE..."
echo "$DEFAULT_PARROT_SOURCES" > "$SOURCES_LIST_FILE"
if [ $? -ne 0 ]; then
    echo "Error: Failed to write to $SOURCES_LIST_FILE." >&2
    echo "Attempting to restore from backup..."
    if [ -f "$BACKUP_DIR/$(basename $SOURCES_LIST_FILE)" ]; then
        cp "$BACKUP_DIR/$(basename $SOURCES_LIST_FILE)" "$SOURCES_LIST_FILE"
        echo "Restored $SOURCES_LIST_FILE from backup."
    fi
    exit 1
fi
echo " -> $SOURCES_LIST_FILE overwritten successfully."
echo ""

# --- Clean sources.list.d ---
if [ -d "$SOURCES_LIST_D_DIR" ]; then
    echo "Cleaning *.list files from $SOURCES_LIST_D_DIR..."
    # Use find to safely remove only .list files within the directory
    find "$SOURCES_LIST_D_DIR/" -maxdepth 1 -type f -name '*.list' -exec echo "   -> Removing {}..." \; -exec rm -f {} \;
    if [ $? -ne 0 ]; then
        echo "Warning: Encountered an error while removing files from $SOURCES_LIST_D_DIR." >&2
        # Don't necessarily exit, but warn the user. They might need manual cleanup.
    fi
    echo " -> $SOURCES_LIST_D_DIR cleaned."
else
    echo "$SOURCES_LIST_D_DIR does not exist, skipping cleanup."
fi
echo ""

# --- Run apt update ---
echo "Running 'apt update' to apply changes..."
echo "-------------------------------------"
apt update
echo "-------------------------------------"

echo ""
echo "Parrot sources reset process finished!"
echo "Your original configuration is backed up in: $BACKUP_DIR"
echo "Please review the output of 'apt update' above for any errors."

exit 0
