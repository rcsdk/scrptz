#!/bin/bash

# Navigate to the existing repository directory
cd ~/opt/google/chrome/scrptz || exit

# Stash the local changes
git stash

# Pull the latest changes from GitHub
git pull origin main

# Apply the stashed changes
git stash pop

chmod +x ~/up.sh

