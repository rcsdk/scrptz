#!/bin/bash

# Function to check the success of a command
check_success() {
    if [ $? -ne 0 ]; then
        echo "Error: $1 failed. Exiting."
        exit 1
    fi
}

# Enable debug mode
set -x

# --- Done: Keyboard Bindings ---
xfce4-terminal &
echo "bind \"^C\": copy" >> ~/.inputrc
echo "bind \"^V\": paste" >> ~/.inputrc
echo "bind \"^Z\": suspend" >> ~/.inputrc
check_success "Keyboard bindings"
xfce4-terminal &
sleep 1

# Print statement to verify keyboard bindings
echo "Keyboard bindings set"

# --- Done: Display Brightness ---
echo "Configuring display brightness..."
xrandr -q
alias br='xrandr --output eDP1 --brightness'
br 0.4
check_success "Display brightness"
sleep 1

# Print statement to verify display brightness
echo "Display brightness set to 0.4"

# --- Done: Disable Touchpad ---
echo "Disabling touchpad..."
synclient TouchpadOff=1
check_success "Touchpad disabled"

# Print statement to verify touchpad is disabled
echo "Touchpad disabled"

# ... (rest of the script remains the same)

# Test with different inputs
echo "Testing with different inputs..."
USER_NAME="test_user"
echo "User name: $USER_NAME"
