#!/bin/bash

# Add Google Chrome repository to Pacman
echo "[google-chrome]" | sudo tee /etc/pacman.conf
echo "Server = https://dl.google.com/linux/chrome/$arch" | sudo tee -a /etc/pacman.conf
sudo pacman-key --recv-keys --keyserver keyserver.ubuntu.com BA88F2723BA7FF56
sudo pacman-key --lsign-key BA88F2723BA7FF56

# Update and upgrade the system
sudo pacman -Syu --noconfirm

# Install Google Chrome
sudo pacman -Syu google-chrome-stable --noconfirm

# Install chrome-cli
sudo pacman -S git --noconfirm
git clone https://github.com/prasmussen/chrome-cli.git
cd chrome-cli
sudo make
sudo cp chrome-cli /usr/local/bin/
cd ..
rm -rf chrome-cli

# Open specified URLs in Google Chrome
if command -v google-chrome &> /dev/null; then
  google-chrome "https://account.proton.me/login" &
  google-chrome "https://www.figma.com/login?locale=en-us" &
  google-chrome "https://auth.openai.com/authorize?audience=https%3A%2F%2Fapi.openai.com%2Fv1&client_id=TdJIcbe16WoTHtN95nyywh5E4yOo6ItG&country_code=BR&device_id=6fe36ba7-fec1-41db-9716-dd645aad1492&ext-oai-did=6fe36ba7-fec1-41db-9716-dd645aad1492&prompt=login&redirect_uri=https%3A%2F%2Fchatgpt.com%2Fapi%2Fauth%2Fcallback%2Fopenai&response_type=code&scope=openid+email+profile+offline_access+model.request+model.read+organization.read+organization.write&screen_hint=login&state=dOWxn_4hanMG8XzgAjY2fMQNW9INMGwBjujroshuVT0&flow=treatment" &
  google-chrome "https://venice.ai/chat/_xT7DNF0_-uaVdA-FVihq" &
  google-chrome "https://www.freepik.com/log-in?client_id=freepik&lang=en" &
  google-chrome "https://github.com/login?return_to=https%3A%2F%2Fgithub.com%2Fsignup%3Fnux_signup%3Dtrue" &
fi

# Install the Voice in Speech-to-Text Chrome extension
chrome-cli install pjnefijmagpdjfhhkpljicbbpicelgko
