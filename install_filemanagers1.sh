#!/bin/bash

# Set the package manager to use
PACKAGE_MANAGER="apt-get"

# Install the required packages
echo "Installing required packages..."
$PACKAGE_MANAGER update -y
$PACKAGE_MANAGER install -y nemo caja dolphin spacefm pcmanfm thunar kitty

# Configure Nemo
echo "Configuring Nemo..."
mkdir -p ~/.local/share/nemo/actions
cat > ~/.local/share/nemo/actions/run_script_in_kitty.nemo-action <<EOF
[Nemo Action]
Name=Run in Kitty
Comment=Run the script in Kitty
Exec=kitty -e %f
Icon=utilities-terminal
Selection=Any
Extensions=sh;py
EOF

cat > ~/.local/share/nemo/actions/run_script_in_root_terminal.nemo-action <<EOF
[Nemo Action]
Name=Run in Root Terminal
Comment=Run the script in Root Terminal
Exec=sudo -i kitty -e %f
Icon=utilities-terminal
Selection=Any
Extensions=sh;py
EOF

# Configure Caja
echo "Configuring Caja..."
mkdir -p ~/.config/caja/actions
cat > ~/.config/caja/actions/run_script_in_kitty.caja-action <<EOF
[Caja Action]
Name=Run in Kitty
Comment=Run the script in Kitty
Exec=kitty -e %f
Icon=utilities-terminal
Selection=Any
Extensions=sh;py
EOF

cat > ~/.config/caja/actions/run_script_in_root_terminal.caja-action <<EOF
[Caja Action]
Name=Run in Root Terminal
Comment=Run the script in Root Terminal
Exec=sudo -i kitty -e %f
Icon=utilities-terminal
Selection=Any
Extensions=sh;py
EOF

# Configure Dolphin
echo "Configuring Dolphin..."
mkdir -p ~/.local/share/kde4/services/ServiceMenus
cat > ~/.local/share/kde4/services/ServiceMenus/run_script_in_kitty.desktop <<EOF
[Desktop Entry]
Type=Service
Name=Run in Kitty
Comment=Run the script in Kitty
Exec=kitty -e %f
Icon=utilities-terminal
X-KDE-ServiceTypes=KonqPopupMenu/Plugin
Actions=Run
EOF

cat > ~/.local/share/kde4/services/ServiceMenus/run_script_in_root_terminal.desktop <<EOF
[Desktop Entry]
Type=Service
Name=Run in Root Terminal
Comment=Run the script in Root Terminal
Exec=sudo -i kitty -e %f
Icon=utilities-terminal
X-KDE-ServiceTypes=KonqPopupMenu/Plugin
Actions=Run
EOF

# Configure SpaceFM
echo "Configuring SpaceFM..."
mkdir -p ~/.config/spacefm/actions
cat > ~/.config/spacefm/actions/run_script_in_kitty.spacefm-action <<EOF
[SpaceFM Action]
Name=Run in Kitty
Comment=Run the script in Kitty
Exec=kitty -e %f
Icon=utilities-terminal
Selection=Any
Extensions=sh;py
EOF

cat > ~/.config/spacefm/actions/run_script_in_root_terminal.spacefm-action <<EOF
[SpaceFM Action]
Name=Run in Root Terminal
Comment=Run the script in Root Terminal
Exec=sudo -i kitty -e %f
Icon=utilities-terminal
Selection=Any
Extensions=sh;py
EOF

# Configure PCManFM
echo "Configuring PCManFM..."
mkdir -p ~/.config/pcmanfm/actions
cat > ~/.config/pcmanfm/actions/run_script_in_kitty.pcmanfm-action <<EOF
[PCManFM Action]
Name=Run in Kitty
Comment=Run the script in Kitty
Exec=kitty -e %f
Icon=utilities-terminal
Selection=Any
Extensions=sh;py
EOF

cat > ~/.config/pcmanfm/actions/run_script_in_root_terminal.pcmanfm-action <<EOF
[PCManFM Action]
Name=Run in Root Terminal
Comment=Run the script in Root Terminal
Exec=sudo -i kitty -e %f
Icon=utilities-terminal
Selection=Any
Extensions=sh;py
EOF

# Configure Thunar
echo "Configuring Thunar..."
mkdir -p ~/.config/Thunar/actions
cat > ~/.config/Thunar/actions/run_script_in_kitty.thunar-action <<EOF
[Thunar Action]
Name=Run in Kitty
Comment=Run the script in Kitty
Exec=kitty -e %f
Icon=utilities-terminal
Selection=Any
Extensions=sh;py
EOF

cat > ~/.config/Thunar/actions/run_script_in_root_terminal.thunar-action <<EOF
[Thunar Action]
Name=Run in Root Terminal
Comment=Run the script in Root Terminal
Exec=sudo -i kitty -e %f
Icon=utilities-terminal
Selection=Any
Extensions=sh;py
EOF

# Make the scripts executable
echo "Making scripts executable..."
chmod +x ~/.local/share/nemo/actions/run_script_in_kitty.nemo-action
chmod +x ~/.local/share/nemo/actions/run_script_in_root_terminal.nemo-action
chmod +x ~/.config/caja/actions/run_script_in_kitty.caja-action
chmod +x ~/.config/caja/actions/run_script_in_root_terminal.caja-action
chmod +x ~/.local/share/kde4/services/ServiceMenus/run_script_in_kitty.desktop
chmod +x ~/.local/share/kde4/services/ServiceMenus/run_script_in_root_terminal.desktop
chmod +x ~/.config/spacefm/actions/run_script_in_kitty.spacefm-action
chmod +x ~/.config/spacefm/actions/run_script_in_root_terminal.spacefm-action
chmod +x ~/.config/pcmanfm/actions/run_script_in_kitty.pcmanfm-action
chmod +x ~/.config/pcmanfm/actions/run_script_in_root_terminal.pcmanfm-action
chmod +x ~/.config/Thunar/actions/run_script_in_kitty.thunar-action
chmod +x ~/.config/Thunar/actions/run_script_in_root_terminal.thunar-action

# Restart the file managers to apply the changes
echo "Restarting file managers..."
if [ -n "$DISPLAY" ]; then
  nemo &
  caja &
  dolphin &
  spacefm &
  pcmanfm &
  thunar &
fi

echo "Configuration complete!"
