https://snapcraft.io/install/figma-linux/arch

https://aur.archlinux.org/packages/figma-linux

https://aur.archlinux.org/packages/figma-linux-bin
https://aur.archlinux.org/packages/figma-linux-git

https://aur.archlinux.org/packages/figma-linux-dev-git

https://snapcraft.io/install/figma-linux/arch


https://github.com/Figma-Linux/figma-linux

https://github.com/Figma-Linux/figma-linux/releases



git clone https://aur.archlinux.org/snapd.git
cd snapd
makepkg -si

sudo systemctl enable --now  snapd.socket

sudo systemctl enable --now snapd.apparmor.service

sudo ln -s /var/lib/snapd/snap /snap

sudo snap install figma-linux
