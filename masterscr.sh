#!/bin/bash

# Log file
LOG_FILE=~/setup.log

# Function to log messages
log() {
  echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

# Function to handle errors
handle_error() {
  log "Error occurred: $1"
  notify-send "Setup Failed" "Error occurred: $1"
  exit 1
}

# Ensure required tools are installed
if ! command -v git &> /dev/null; then
  log "Git is not installed. Installing Git..."
  sudo pacman -S --noconfirm git || handle_error "Failed to install Git"
else
  log "Git is already installed."
fi

if ! command -v wget &> /dev/null; then
  log "wget is not installed. Installing wget..."
  sudo pacman -S --noconfirm wget || handle_error "Failed to install wget"
else
  log "wget is already installed."
fi

if ! command -v tmux &> /dev/null; then
  log "tmux is not installed. Installing tmux..."
  sudo pacman -S --noconfirm tmux || handle_error "Failed to install tmux"
else
  log "tmux is already installed."
fi

if ! command -v xfce4-terminal &> /dev/null; then
  log "xfce4-terminal is not installed. Installing xfce4-terminal..."
  sudo pacman -S --noconfirm xfce4-terminal || handle_error "Failed to install xfce4-terminal"
else
  log "xfce4-terminal is already installed."
fi

# Ensure the directory exists
SCRIPT_DIR=~/opt/google/chrome/scrptz
if [ ! -d "$SCRIPT_DIR" ]; then
  log "Directory $SCRIPT_DIR does not exist. Please clone the repository first."
  handle_error "Directory $SCRIPT_DIR does not exist."
fi

# Navigate to the script directory
cd "$SCRIPT_DIR" || handle_error "Failed to navigate to $SCRIPT_DIR"

# Make the scripts executable
chmod +x masterscr.sh
chmod +x up.sh
chmod +x lo.sh || handle_error "Failed to make scripts executable."

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

# Run s1.sh on second monitor
log "Running s1.sh on second monitor..."
xrandr | grep " connected" | awk '{print $1}' | tail -n 1 | xargs -I {} xfce4-terminal --display=:0 --geometry=1920x1080+1920+0 -x bash -c "./s1.sh; exec bash" &

# Run s2.sh on second monitor
log "Running s2.sh on second monitor..."
xrandr | grep " connected" | awk '{print $1}' | tail -n 1 | xargs -I {} xfce4-terminal --display=:0 --geometry=1920x1080+1920+0 -x bash -c "./s2.sh; exec bash" &

# Run s3.sh in a tmux session
log "Running s3.sh in a tmux session..."
tmux new-session -d -s setup-session 'bash -c "cd ~/opt/google/chrome/scrptz
