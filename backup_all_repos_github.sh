#!/bin/bash

# === Configuration ===
# Directory where backups will be stored - UPDATED FOR YOUR REQUEST
BACKUP_PARENT_DIR="/home/rc/Backups/Github"
# Optional: Specify GitHub username (gh usually figures this out, but can be explicit)
# GITHUB_USER="your_github_username"

# === Script Logic ===

sudo apt update && sudo apt install git gh zip


# Set date format for backup filename/directory
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")

# Construct backup directory path for this run (temporary location for clones)
BACKUP_DIR="${BACKUP_PARENT_DIR}/github_clone_temp_${TIMESTAMP}"

# Construct final zip file name
ZIP_FILENAME="${BACKUP_PARENT_DIR}/github_backup_${TIMESTAMP}.zip"

# --- Helper Functions ---
check_command() {
  if ! command -v "$1" &> /dev/null; then
    echo "Error: Required command '$1' not found."
    echo "Please install it (e.g., 'sudo apt update && sudo apt install $1') and ensure it's in your PATH."
    exit 1
  fi
}

# --- Prerequisites Check ---
echo "Checking prerequisites..."
check_command git
check_command gh
check_command zip
echo "Prerequisites met."
echo ""

# --- Authentication Check (gh handles actual auth, this is a sanity check) ---
echo "Verifying gh authentication..."
if ! gh auth status &> /dev/null; then
  echo "Error: gh CLI is not authenticated."
  echo "Please run 'gh auth login' to authenticate."
  exit 1
fi
echo "gh authenticated."
echo ""

# --- Main Backup Process ---
echo "Starting GitHub backup..."
echo "Backup target directory: ${BACKUP_PARENT_DIR}"

# Create the parent backup directory if it doesn't exist
# The -p flag ensures parent directories are created if needed,
# and it doesn't error if the directory already exists.
mkdir -p "$BACKUP_PARENT_DIR"
if [ $? -ne 0 ]; then
    echo "Error: Could not create or access backup directory: $BACKUP_PARENT_DIR"
    echo "Please check permissions for user '$(whoami)'."
    exit 1
fi

# Create a temporary directory for cloning inside the parent dir
echo "Creating temporary clone directory: $BACKUP_DIR"
mkdir -p "$BACKUP_DIR"
if [ $? -ne 0 ]; then
    echo "Error: Could not create temporary clone directory: $BACKUP_DIR"
    exit 1
fi

# Change into the temporary clone directory
cd "$BACKUP_DIR" || exit 1 # Exit if cd fails

echo "Fetching list of repositories..."
# Get list of repository clone URLs (HTTPS) for the authenticated user
# Increase limit if you have > 1000 repos.
# Use --jq '.[] | .sshUrl' if you prefer SSH cloning (requires SSH key setup)
repo_urls=$(gh repo list --limit 1000 --json url --jq '.[] | .url')

if [ -z "$repo_urls" ]; then
    echo "Error: Could not fetch repository list or no repositories found."
    # Clean up the empty temp dir before exiting
    cd "$BACKUP_PARENT_DIR" || exit 1
    rmdir "$(basename "$BACKUP_DIR")"
    exit 1
fi

echo "Found repositories. Starting cloning process (using --mirror)..."
echo "---------------------------------------------"

cloned_count=0
failed_count=0

# Loop through each repository URL and clone it as a mirror
while IFS= read -r repo_url; do
    # Extract a safe directory name from the URL
    repo_name=$(basename "$repo_url" .git)
    echo "Cloning '$repo_name' from $repo_url ..."
    # Use --mirror for a complete bare backup (all branches, tags, refs)
    if git clone --mirror "$repo_url" "$repo_name.git"; then
        echo " -> Successfully cloned '$repo_name'."
        cloned_count=$((cloned_count + 1))
    else
        echo " !> Failed to clone '$repo_name'."
        failed_count=$((failed_count + 1))
    fi
    echo "---------------------------------------------"
done <<< "$repo_urls"


echo "Cloning complete. Cloned: $cloned_count, Failed: $failed_count"
echo ""

# Change back to the parent directory BEFORE zipping
cd "$BACKUP_PARENT_DIR" || exit 1

# Create the zip file
echo "Creating zip archive: $ZIP_FILENAME ..."
# We zip the temporary directory (using its basename)
if zip -r "$ZIP_FILENAME" "$(basename "$BACKUP_DIR")"; then
    echo "Successfully created zip file: $ZIP_FILENAME"

    # Clean up the temporary directory IF zipping was successful
    echo "Cleaning up temporary directory: $(basename "$BACKUP_DIR") ..."
    rm -rf "$(basename "$BACKUP_DIR")"
    echo "Cleanup complete."
else
    echo "Error: Failed to create zip file."
    echo "The cloned repositories remain in: $BACKUP_DIR"
    exit 1
fi

echo ""
echo "GitHub backup process finished!"
exit 0
