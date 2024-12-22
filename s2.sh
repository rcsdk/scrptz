#!/bin/bash

# Install Google Chrome
sudo pacman -S google-chrome

# Run Google Chrome without sandboxing
google-chrome --no-sandbox &

# Open multiple URLs in different tabs
xdotool search --class "Google Chrome" windowfocus
xdotool key --delay 100 Ctrl+t
xdotool type --delay 100 "https://www.figma.com/login?locale=en-us"
xdotool key --delay 100 Return

xdotool key --delay 100 Ctrl+t
xdotool type --delay 100 "https://auth.openai.com/authorize?audience=https%3A%2F%2Fapi.openai.com%2Fv1&client_id=TdJIcbe16WoTHtN95nyywh5E4yOo6ItG&country_code=BR&device_id=6fe36ba7-fec1-41db-9716-dd645aad1492&ext-oai-did=6fe36ba7-fec1-41db-9716-dd645aad1492&prompt=login&redirect_uri=https%3A%2F%2Fchatgpt.com%2Fapi%2Fauth%2Fcallback%2Fopenai&response_type=code&scope=openid+email+profile+offline_access+model.request+model.read+organization.read+organization.write&screen_hint=login&state=dOWxn_4hanMG8XzgAjY2fMQNW9INMGwBjujroshuVT0&flow=treatment"
xdotool key --delay 100 Return

xdotool key --delay 100 Ctrl+t
xdotool type --delay 100 "https://venice.ai/chat/_xT7DNF0_-uaVdA-FVihq"
xdotool key --delay 100 Return

xdotool key --delay 100 Ctrl+t
xdotool type --delay 100 "https://www.freepik.com/log-in?client_id=freepik&lang=en"
xdotool key --delay 100 Return

xdotool key --delay 100 Ctrl+t
xdotool type --delay 100 "https://github.com/login?return_to=https%3A%2F%2Fgithub.com%2Fsignup%3Fnux_signup%3Dtrue"
xdotool key --delay 100 Return
