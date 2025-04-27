#!/usr/bin/env python3
import os
import subprocess
import sys
import shutil
import datetime
import re

# --- Configuration ---
BASHRC_FILE = os.path.expanduser("~/.bashrc")
BACKUP_SUFFIX = datetime.datetime.now().strftime(".bak.noir.%Y%m%d_%H%M%S")
# Ensure curl and xclip are present
REQUIRED_COMMANDS = ["curl", "xclip"]

# Markers to identify the script block in .bashrc
SCRIPT_MARKER_BEGIN = "# BEGIN 0x0 UPLOADER FUNCTION (NOIR THEME)"
SCRIPT_MARKER_END = "# END 0x0 UPLOADER FUNCTION (NOIR THEME)"

# --- Helper: Hex to RGB ---
def hex_to_rgb(hex_color):
    """Converts #RRGGBB to an (R, G, B) tuple."""
    hex_color = hex_color.lstrip('#')
    if len(hex_color) != 6:
        raise ValueError(f"Invalid hex color format: {hex_color}")
    return tuple(int(hex_color[i:i+2], 16) for i in (0, 2, 4))

# --- Generate ANSI Color Codes ---
# We pre-calculate these for the Bash script string
try:
    C_GOLD = r'\e[38;2;{};{};{}m'.format(*hex_to_rgb("#c5b47f"))
    C_MUTED1 = r'\e[38;2;{};{};{}m'.format(*hex_to_rgb("#7a8383"))
    C_MUTED2 = r'\e[38;2;{};{};{}m'.format(*hex_to_rgb("#666350"))
    C_MUTED3 = r'\e[38;2;{};{};{}m'.format(*hex_to_rgb("#808c81"))
    C_ACCENT2 = r'\e[38;2;{};{};{}m'.format(*hex_to_rgb("#9c5c34"))
    C_MUTED4 = r'\e[38;2;{};{};{}m'.format(*hex_to_rgb("#444c48"))
    C_RESET = r'\e[0m'
except ValueError as e:
    print(f"Error processing hex colors: {e}", file=sys.stderr)
    sys.exit(1)

# --- The Bash Script Content ---
# Using f-string to embed the pre-calculated ANSI codes
BASH_SCRIPT_CONTENT = fr"""
# Function to upload a file to 0x0.st with a film noir themed animation
0x0() {{
  local file_path="$1"
  local filename
  local temp_output
  local pid
  local exit_status
  local url

  # --- Film Noir Animation Config ---
  # Colors (pre-calculated ANSI escapes)
  local C_GOLD='{C_GOLD}'        # Accent 1: Dark Gold / Khaki (#c5b47f)
  local C_MUTED1='{C_MUTED1}'    # Muted Tone 1: Desaturated Blue/Grey (#7a8383)
  local C_MUTED2='{C_MUTED2}'    # Muted Tone 2: Olive Drab / Grey (#666350)
  local C_MUTED3='{C_MUTED3}'    # Muted Tone 3: Desaturated Green/Grey (#808c81)
  local C_ACCENT2='{C_ACCENT2}'   # Accent 2: Muted Orange/Brown (#9c5c34)
  local C_MUTED4='{C_MUTED4}'    # Muted Tone 4: Dark Grey/Green (#444c48)
  local C_RESET='{C_RESET}'      # Reset color

  # Animation sequence characters and colors
  local anim_chars=("░" "▒" "▓" "█") # Different shades/blocks
  local anim_colors=("$C_MUTED4" "$C_MUTED1" "$C_MUTED2" "$C_MUTED3")
  local accent_colors=("$C_GOLD" "$C_ACCENT2")
  local anim_len=${{#anim_colors[@]}}
  local accent_len=${{#accent_colors[@]}}
  local accent_freq=7 # How often to flash an accent color (e.g., every 7 steps)
  local anim_sleep=0.18 # Sleep duration for a slower, moodier pace
  local i=0

  # --- Argument and File Validation ---
  if [[ -z "$file_path" ]]; then
    echo "Usage: 0x0 <filename>" >&2
    echo "Example: 0x0 my_noir_shot.png" >&2
    return 1
  fi

  if [[ ! -f "$file_path" ]]; then
    echo "Error: File not found or is not a regular file: {file_path}" >&2
    return 1
  fi

  if [[ ! -r "$file_path" ]]; then
    echo "Error: File is not readable: {file_path}" >&2
    return 1
  fi

  filename=$(basename "$file_path")

  # --- Check for curl ---
  if ! command -v curl &> /dev/null; then
      echo "Error: curl is not installed. Please install it." >&2
      # The python script should have installed this, but check anyway.
      return 1
  fi
   # --- Check for xclip ---
  if ! command -v xclip &> /dev/null; then
      echo "Error: xclip is not installed. Please install it." >&2
      # The python script should have installed this, but check anyway.
      return 1
  fi

  # --- Upload Process ---
  temp_output=$(mktemp)
  trap 'rm -f "$temp_output"; tput cnorm' EXIT INT TERM # Clean up temp file AND restore cursor

  echo -n "Transmitting '$filename' to the void... " # Themed message

  # Hide cursor for cleaner animation
  tput civis

  # Run curl in the background
  curl -s -L -F "file=@{{file_path}}" https://0x0.st > "$temp_output" &
  pid=$!

  # --- Animation Loop ---
  while kill -0 $pid 2>/dev/null; do
    local current_char_index=$(( i % ${{#anim_chars[@]}} ))
    local current_char="${{anim_chars[current_char_index]}}"
    local current_color

    # Check if it's time for an accent flash
    if [[ $(( i % accent_freq )) -eq 0 ]]; then
      local accent_index=$(( (i / accent_freq) % accent_len ))
      current_color="${{accent_colors[accent_index]}}"
    else
      # Cycle through muted colors
      local muted_index=$(( i % anim_len ))
      current_color="${{anim_colors[muted_index]}}"
    fi

    # Print color, character, reset color, then carriage return
    printf "${{current_color}}${{current_char}}${{C_RESET}}\r"
    sleep "$anim_sleep"
    ((i++))
  done

  # Restore cursor visibility
  tput cnorm
  printf " \r" # Clear the animation character

  # --- Process Results ---
  wait $pid
  exit_status=$?

  if [[ $exit_status -ne 0 ]]; then
    echo # Newline after "Transmitting..."
    echo "${{C_ACCENT2}}Signal lost. Transmission failed.${{C_RESET}} (curl status: $exit_status)" >&2
    if [[ -s "$temp_output" ]]; then
        echo "Intercepted response:" >&2
        cat "$temp_output" >&2
    fi
    return 1
  fi

  url=$(cat "$temp_output")

  if [[ "$url" =~ ^https?:// ]]; then
    echo "Done."
    echo -e "Location confirmed: ${{C_GOLD}}${{url}}${{C_RESET}}" # Use gold for URL

    # Copy to clipboard using xclip (Python script ensures it's installed)
    echo "$url" | xclip -selection clipboard
    echo "(Coordinates copied to clipboard via xclip)"

    return 0 # Success
  else
    echo # Newline
    echo "${{C_ACCENT2}}Transmission received, but coordinates garbled.${{C_RESET}}" >&2
    echo "Intercepted response:" >&2
    cat "$temp_output" >&2
    return 1
  fi
}}

# Optional: Tab completion (requires bash-completion package)
if command -v complete &> /dev/null && command -v bash-completion &> /dev/null ; then
  complete -f -o default 0x0
fi
"""

# --- Python Helper Functions (Installation, File Ops) ---

def check_command(cmd):
    """Checks if a command exists in the system's PATH."""
    return shutil.which(cmd) is not None

def install_packages(packages):
    """Attempts to install packages using apt, forcing -y."""
    if not packages:
        return True
    print(f"--- Ensuring required packages are installed: {' '.join(packages)} ---")
    print("This requires sudo privileges and will run 'apt update' and 'apt install -y'.")
    try:
        # Check if sudo is available first
        if not check_command("sudo"):
             print("Error: 'sudo' command not found. Cannot manage packages.", file=sys.stderr)
             print(f"Please install manually: apt update && apt install {' '.join(packages)}", file=sys.stderr)
             return False

        print("Running 'sudo apt update'...")
        # Use Popen to better handle potential password prompts or errors during update
        update_process = subprocess.Popen(["sudo", "apt", "update"], stdout=subprocess.PIPE, stderr=subprocess.PIPE)
        stdout, stderr = update_process.communicate()
        if update_process.returncode != 0:
            print("Warning: 'sudo apt update' failed. Trying install anyway.", file=sys.stderr)
            # You might want to print stderr here for debugging: print(stderr.decode(), file=sys.stderr)
        else:
            print("Update check successful.")

        print(f"Running 'sudo apt install -y {' '.join(packages)}'...")
        # Run install with stdout/stderr potentially visible if needed, forcing -y
        install_cmd = ["sudo", "apt", "install", "-y"] + packages
        # Using Popen again to capture output if needed, but check=True equivalent behavior
        install_process = subprocess.Popen(install_cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
        stdout, stderr = install_process.communicate()

        if install_process.returncode != 0:
             print(f"\nError during package installation (Return Code: {install_process.returncode}).", file=sys.stderr)
             print("--- APT Output ---", file=sys.stderr)
             print(stderr.decode(errors='ignore'), file=sys.stderr)
             print("------------------", file=sys.stderr)
             print("Please try installing the packages manually:", file=sys.stderr)
             print(f"  sudo apt update && sudo apt install {' '.join(packages)}", file=sys.stderr)
             return False
        else:
             print("Installation/Verification successful.")
             return True

    except Exception as e:
        print(f"An unexpected error occurred during installation: {e}", file=sys.stderr)
        return False


# --- Main Script Logic ---

def main():
    print("--- Setting up the 0x0 Noir Bash Uploader ---")

    # 1. Check & Install Dependencies (Force xclip)
    print("\n[1/6] Checking dependencies (curl, xclip)...")
    missing_packages = [cmd for cmd in REQUIRED_COMMANDS if not check_command(cmd)]

    if missing_packages:
        print(f"Missing required commands: {', '.join(missing_packages)}")
        if not install_packages(missing_packages):
            print("Dependency installation failed. Cannot proceed.", file=sys.stderr)
            sys.exit(1)
        # Re-verify after install attempt
        if any(cmd for cmd in missing_packages if not check_command(cmd)):
             print("Core dependency installation failed even after attempt. Aborting.", file=sys.stderr)
             sys.exit(1)
        print("Dependencies successfully installed.")
    else:
        print("Dependencies (curl, xclip) are present.")

    # 2. Locate .bashrc
    print(f"\n[2/6] Locating Bash configuration file: {BASHRC_FILE}")
    if not os.path.isfile(BASHRC_FILE):
        print(f"Error: {BASHRC_FILE} not found.", file=sys.stderr)
        sys.exit(1)

    # 3. Backup .bashrc
    backup_file = BASHRC_FILE + BACKUP_SUFFIX
    print(f"\n[3/6] Backing up {BASHRC_FILE} to {backup_file}")
    try:
        shutil.copy2(BASHRC_FILE, backup_file)
        print("Backup successful.")
    except Exception as e:
        print(f"Error creating backup: {e}", file=sys.stderr)
        sys.exit(1)

    # 4. Check if script already exists (using markers)
    print(f"\n[4/6] Checking if Noir 0x0 function already exists in {BASHRC_FILE}...")
    bashrc_content = ""
    try:
        with open(BASHRC_FILE, 'r') as f:
            bashrc_content = f.read()

        # Use regex to find existing blocks precisely
        pattern = re.compile(f"^{re.escape(SCRIPT_MARKER_BEGIN)}.*?^{re.escape(SCRIPT_MARKER_END)}$", re.MULTILINE | re.DOTALL)
        existing_block = pattern.search(bashrc_content)

        if existing_block:
            print("Found existing Noir 0x0 function block. Replacing it.")
            # Remove the old block before appending the new one
            bashrc_content = pattern.sub('', bashrc_content).strip()
            # Write the modified content back (overwrite mode)
            with open(BASHRC_FILE, 'w') as f:
                f.write(bashrc_content)
            print("Old block removed.")
        else:
            print("Noir 0x0 function not found. Proceeding with append.")

    except Exception as e:
        print(f"Error reading or modifying {BASHRC_FILE}: {e}", file=sys.stderr)
        print("Restoring from backup...")
        try:
             shutil.move(backup_file, BASHRC_FILE)
        except Exception as backup_err:
             print(f"FATAL: Could not restore backup: {backup_err}", file=sys.stderr)
        sys.exit(1)

    # 5. Append Script to .bashrc
    print(f"\n[5/6] Appending the Noir 0x0 function to {BASHRC_FILE}...")
    try:
        with open(BASHRC_FILE, 'a') as f:
            # Ensure there's a newline before the block if file doesn't end with one
            if not bashrc_content.endswith('\n'):
                 f.write("\n")
            f.write("\n" + SCRIPT_MARKER_BEGIN + "\n")
            f.write(BASH_SCRIPT_CONTENT.strip()) # Use strip to remove leading/trailing ws from heredoc
            f.write("\n" + SCRIPT_MARKER_END + "\n")
        print("Append successful.")
    except Exception as e:
        print(f"Error appending to {BASHRC_FILE}: {e}", file=sys.stderr)
        print("Attempting to restore from backup...")
        try:
             # Use move, which overwrites if the target exists (safer here)
             shutil.move(backup_file, BASHRC_FILE)
             print("Backup restored successfully.")
        except Exception as restore_err:
             print(f"FATAL: Could not restore backup: {restore_err}", file=sys.stderr)
             print(f"Your original .bashrc might be in {backup_file}", file=sys.stderr)
        sys.exit(1)

    # 6. Verify Append
    print(f"\n[6/6] Verifying changes in {BASHRC_FILE}...")
    try:
        with open(BASHRC_FILE, 'r') as f:
            content = f.read()
            # Check markers again after append/replace
            if SCRIPT_MARKER_BEGIN in content and SCRIPT_MARKER_END in content:
                print("Verification successful. Script markers found.")
            else:
                print("Error: Verification failed. Script markers not found after modification.", file=sys.stderr)
                print("Your original .bashrc should be available in the backup file:", backup_file, file=sys.stderr)
                sys.exit(1)
    except Exception as e:
        print(f"Error verifying {BASHRC_FILE}: {e}", file=sys.stderr)
        print("Your original .bashrc should be available in the backup file:", backup_file, file=sys.stderr)
        sys.exit(1)

    # Final Instructions
    print("\n--- Noir Setup Successfully Completed ---")
    print_final_instructions(backup_file) # Pass backup filename


def print_final_instructions(backup_filename):
    """Prints the final instructions for the user."""
    print("\n*** IMPORTANT NEXT STEPS ***")
    print(f"1. Apply the changes to your current shell session by running:")
    print(f"   source {BASHRC_FILE}")
    print("   Alternatively, simply open a new terminal window.")
    print("\n2. Test the function:")
    print("   a. Create a dummy file: echo 'Testing noir upload...' > test_upload.txt")
    print("   b. Run the upload command: 0x0 test_upload.txt")
    print("   c. It should show the themed animation and output a URL in dark gold.")
    print("   d. The URL is automatically copied to your clipboard (using xclip, which was installed if missing).")
    print("      You can paste it with middle-click or Shift+Insert/Ctrl+Shift+V.")
    print("   e. Clean up: rm test_upload.txt")
    print(f"\n-> The 'xclip' utility was checked and installed if it was missing.")
    print(f"-> If anything went wrong, your original config was backed up to: {backup_filename}")
    print(f"-> Restore it by running: mv '{backup_filename}' '{BASHRC_FILE}'")


if __name__ == "__main__":
    main()
