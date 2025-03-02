#!/bin/bash

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo "Please run this script as root (sudo)."
    exit 1
fi

# Function to wait for the apt lock release
wait_for_apt_lock() {
    while ! apt update; do
        echo "Apt lock detected. Identifying and terminating the process holding the lock..."
        LOCK_PID=$(lsof /var/lib/apt/lists/lock | awk 'NR==2 {print $2}')
        if [ -n "$LOCK_PID" ]; then
            echo "Killing process $LOCK_PID holding the lock..."
            kill -9 "$LOCK_PID"
        else
            echo "No process found holding the lock. Retrying..."
        fi
        sleep 5
    done
}

# Update system and install basic tools
echo "Updating system and installing tools (wget, curl, etc.)..."
wait_for_apt_lock
apt upgrade -y
apt install -y wget curl xfce4-whiskermenu-plugin

# Install Super Productivity
echo "Installing Super Productivity..."
SP_VERSION="8.0.1"  # Check https://github.com/johannesjo/super-productivity/releases
wget -O super-productivity.deb "https://github.com/johannesjo/super-productivity/releases/download/v${SP_VERSION}/super-productivity_${SP_VERSION}_amd64.deb"
if [ -f super-productivity.deb ]; then
    dpkg -i super-productivity.deb
    apt install -f -y
    rm super-productivity.deb
else
    echo "Failed to download Super Productivity. Check the URL or internet connection."
fi

# Install Joplin Notes via AppImage
echo "Installing Joplin Notes..."
JOPLIN_VERSION="3.0.13"  # Check https://github.com/laurent22/joplin/releases
wget -O joplin.AppImage "https://github.com/laurent22/joplin/releases/download/v${JOPLIN_VERSION}/Joplin-${JOPLIN_VERSION}-x86_64.AppImage"
if [ -f joplin.AppImage ]; then
    chmod +x joplin.AppImage
    mkdir -p /opt/joplin
    mv joplin.AppImage /opt/joplin/
    cat <<EOF >/usr/share/applications/joplin.desktop
[Desktop Entry]
Name=Joplin
Exec=/opt/joplin/joplin.AppImage
Type=Application
Icon=text-editor
Terminal=false
Categories=Office;
EOF
else
    echo "Failed to download Joplin. Check the URL or internet connection."
fi

# Install Obsidian via AppImage
echo "Installing Obsidian..."
OBSIDIAN_VERSION="1.5.8"  # Check https://obsidian.md/download
wget -O obsidian.AppImage "https://github.com/obsidiansmd/obsidian-releases/releases/download/v${OBSIDIAN_VERSION}/Obsidian-${OBSIDIAN_VERSION}-x86_64.AppImage"
if [ -f obsidian.AppImage ]; then
    chmod +x obsidian.AppImage
    mkdir -p /opt/obsidian
    mv obsidian.AppImage /opt/obsidian/
    cat <<EOF >/usr/share/applications/obsidian.desktop
[Desktop Entry]
Name=Obsidian
Exec=/opt/obsidian/obsidian.AppImage
Type=Application
Icon=accessories-text-editor
Terminal=false
Categories=Office;
EOF
else
    echo "Failed to download Obsidian. Check the URL or internet connection."
fi

# Install Variety Wallpaper Manager
echo "Installing Variety..."
wait_for_apt_lock
apt install -y variety || {
    echo "Adding Variety PPA for latest version..."
    add-apt-repository ppa:variety/stable -y
    wait_for_apt_lock
    apt install -y variety
}

# Install Sticky Notes
echo "Installing Sticky Notes..."
STICKY_VERSION="1.0"  # Check https://github.com/linuxmint/sticky for the latest version
wget -O sticky.deb "http://packages.linuxmint.com/pool/main/s/sticky/sticky_${STICKY_VERSION}_all.deb"
if [ -f sticky.deb ]; then
    dpkg -i sticky.deb
    apt install -f -y
    rm sticky.deb
else
    echo "Failed to download Sticky. Check the URL or internet connection."
fi

# --- Ensure Whisker Menu Works (10 Checks) ---
echo "Ensuring Whisker Menu functionality..."

# 1. Verify Whisker Menu is installed
if ! dpkg -l | grep -q xfce4-whiskermenu-plugin; then
    echo "Whisker Menu not installed. Installing now..."
    wait_for_apt_lock
    apt install -y xfce4-whiskermenu-plugin
fi

# 2. Check XFCE panel availability
if ! pgrep -f xfce4-panel > /dev/null; then
    echo "XFCE panel not running. Starting it..."
    xfce4-panel &
fi

# 3. Add Whisker Menu to panel (if not already present)
if ! xfce4-panel --list | grep -q "whiskermenu"; then
    echo "Adding Whisker Menu to panel..."
    xfce4-panel --add=whiskermenu &
fi

# 4. Remove conflicting default Applications Menu
if xfconf-query -c xfce4-panel -p /plugins/plugin-ids | grep -q "applicationsmenu"; then
    echo "Removing default Applications Menu..."
    xfconf-query -c xfce4-panel -p /plugins/plugin-ids -r
    xfce4-panel --restart
fi

# 5. Update desktop database
echo "Updating desktop database..."
update-desktop-database

# 6. Verify XFCE session is running
if ! pgrep -f xfce4-session > /dev/null; then
    echo "Warning: XFCE session not detected. Please ensure you're in an XFCE environment."
fi

# 7. Check permissions for menu files
echo "Checking menu file permissions..."
chmod -R a+r /usr/share/applications

# 8. Regenerate XFCE config if needed
if [ ! -d ~/.config/xfce4 ]; then
    echo "Regenerating XFCE config..."
    mkdir -p ~/.config/xfce4
    xfce4-panel --restart
fi

# 9. Restart XFCE panel
echo "Restarting XFCE panel..."
xfce4-panel --restart &

# 10. Prompt for session refresh
echo "If menu changes don’t appear, please log out and log back in."

# Create custom 'My Apps' menu category
echo "Creating custom menu category 'My Apps'..."
mkdir -p /usr/share/desktop-directories
cat <<EOF >/usr/share/desktop-directories/my-apps.directory
[Desktop Entry]
Name=My Apps
Icon=applications-other
Type=Directory
EOF

# Update .menu file for XFCE Whisker Menu
MENU_FILE="/etc/xdg/menus/xfce-applications.menu"
if [ -f "$MENU_FILE" ]; then
    sed -i '/<Menu>/a \ \ \ \ <Menu>\n\ \ \ \ \ \ \ \ <Name>My Apps</Name>\n\ \ \ \ \ \ \ \ <Directory>my-apps.directory</Directory>\n\ \ \ \ </Menu>' "$MENU_FILE"
fi

# Assign apps to My Apps category
for app in joplin obsidian super-productivity variety sticky; do
    if [ -f "/usr/share/applications/${app}.desktop" ]; then
        sed -i 's/Categories=.*/Categories=My Apps;/' "/usr/share/applications/${app}.desktop"
    fi
done

# Final menu update
update-desktop-database

echo "Installation complete!"
echo "Check the Whisker Menu for a 'My Apps' category containing Super Productivity, Joplin, Obsidian, Variety, and Sticky."
echo "If the category doesn't appear, log out and log back in."
