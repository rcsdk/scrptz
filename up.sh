#!/bin/bash

# Log file
LOG_FILE=~/setup.log

# Function to log messages
log() {
  echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

# Ensure the directory exists
SCRIPT_DIR=~/opt/google/chrome/scrptz
if [ ! -d "$SCRIPT_DIR" ]; then
  log "Directory $SCRIPT_DIR does not exist. Please clone the repository first."
  exit 1
fi

# Navigate to the script directory
cd "$SCRIPT_DIR" || exit

# Make the scripts executable
chmod +x masterscr.sh
chmod +x up.sh
chmod +x lo.sh

# Add aliases to .bashrc
ALIAS_CONTENT="

# Aliases for running scripts
alias .go='~/opt/google/chrome/scrptz/masterscr.sh'
alias .up='~/opt/google/chrome/scrptz/up.sh'
alias .lo='~/opt/google/chrome/scrptz/lo.sh'
"

# Check if the aliases already exist in .bashrc
if ! grep -q "alias .go" ~/.bashrc && ! grep -q "alias .up" ~/.bashrc && ! grep -q "alias .lo" ~/.bashrc; then
  echo "$ALIAS_CONTENT" | tee -a ~/.bashrc
  log "Aliases added to ~/.bashrc"
else
  log "Aliases already exist in ~/.bashrc"
fi

# Reload the .bashrc
source ~/.bashrc
log "Aliases have been set up and .bashrc has been reloaded."

# Pull the latest changes from GitHub
log "Pulling the latest changes from GitHub..."
git pull origin main || log "Failed to pull the latest changes from GitHub."

# Make the scripts executable again
chmod +x masterscr.sh
chmod +x up.sh
chmod +x lo.sh

log "Update complete."
