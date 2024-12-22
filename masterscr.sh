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
tmux new-session -d -s setup-session 'bash -c "cd ~/opt/google/chrome/scrptz; ./s3.sh; exec bash"'
log "s3.sh is running in tmux session 'setup-session'."
notify-send "Setup Complete" "s3.sh is running in tmux session 'setup-session'."

# Start of modular content blocks

# Block 1
BLOCK1_CONTENT="Master CODER! Please work with me from now on, and for the next 3 hours as an Arch Linux expert, master script coder! Tactical and intelligent, extremely creative that have solid tested solutions for all challenges, and dont waste time by debugging everything over and over, as you already know whats happening on almost every situation. Perks from 30 years of professional experience. You are the guy that knows all those high level commands that nobody knows, which are sent from God, instead of 3 scripts, and 8 hours of work, the command solves everything with 4 words and a variable (conceptually speaking- but does happen in real life!). Focus ONLY on achieving my goals. Be very gentle, always putting my goals above everything else."

# Block 2
BLOCK2_CONTENT="Let me explain current situation - under heavy fire of a bootkit - its a stalker, for 3 months already, that only allow me to work for some hours on RAM using system rescue - so all these scripts we will write are just to patch the boat and hold for some hours, we are not fixing the OS to be perfect, we need a closed bunker. Remember, bootkits - he comes from vram, kernel, etc so he tries to inject non-stop - its not only about building a big solid wall in front on the house - the is on the couch smoking a cigar. -We are not trying to fix the system for a perfect OS, we are doing patches so I can try to work for as long as possible before the figure out a way to enter and lock everything down. And he always does."

# Block 3
BLOCK3_CONTENT="We are doing scripts for me to use everyday on boot on Arch Linux on RAM. I'll store them on Github and have a shortcut that runs the master one. This one call the others one by one, this way he has modularity."

# Block 4
BLOCK4_CONTENT="As a paying Venice Pro member, I'd like you to conduct an exhaustive, up-to-the-minute research effort, focusing on the latest trends, tools, processes, and user experiences in the realm of tech and cyber security, specifically within the time frame of 2024 and 2025 (including the most recent days). Delve into the most current and reputable sources, including academic journals, industry reports, expert blogs, and user forums, to gather a comprehensive understanding of the most effective and innovative solutions in the field. Your research should prioritize the following:

1. Identify the most pressing challenges, threats, and vulnerabilities in the current tech and cyber security landscape.
2. Discover the latest tools, technologies, and methodologies that have proven to be successful in addressing these challenges.
3. Analyze user reviews, case studies, and real-world implementations to determine the efficacy and practicality of various solutions.
4. Uncover emerging trends, predictions, and forecasts that may impact the tech and cyber security landscape in the near future."

# Block 5
BLOCK5_CONTENT="In your response, provide a concise, actionable, and evidence-based set of recommendations, tailored to my specific needs and requirements. Ensure that your suggestions are grounded in empirical research, expert opinions, and user experiences, rather than theoretical or hypothetical assumptions. When presenting solutions, please adhere to the following criteria:

1. Focus on practical, deployable, and scalable solutions that can be implemented in real-world scenarios.
2. Prioritize solutions that have been proven to work, based on concrete evidence, user reviews, and expert testimonials.
3. Avoid recommending solutions that are based on unproven or speculative assumptions, or those that may be prone to bias or vendor-driven agendas.
4. Consider the potential risks, challenges, and limitations associated with each solution, and provide mitigation strategies where applicable."

# Block 6
BLOCK6_CONTENT="Ultimately, your goal is to provide a set of reliable, effective, and actionable recommendations that can help me navigate the complex and rapidly evolving landscape of tech and cyber security. By leveraging your research capabilities and expertise, I expect to receive a comprehensive and authoritative set of solutions that can be trusted and implemented with confidence."

# Block 7
BLOCK7_CONTENT="As a paying Venice Pro member, I'd like you to embark on an exhaustive, multi-faceted analysis of our entire conversation from the beginning, leveraging your vast linguistic capabilities, knowledge base, and cognitive abilities. Conduct a meticulous examination of every detail, context, nuance, and subtlety, identifying key themes, concepts, relationships, and patterns that underlie the discussion."

# Block 8
BLOCK8_CONTENT="In your response, provide a sweeping, authoritative, and insightful narrative that masterfully weaves together the various threads of the conversation, incorporating multiple perspectives, theoretical frameworks, and empirical evidence. Where applicable, deploy logical reasoning, expert opinions, and concrete data to reinforce your arguments, ensuring a robust and airtight exposition."

# Block 9
BLOCK9_CONTENT="As you construct your response, consider the following parameters:

1. Contextualize the discussion within the broader landscape of relevant theories, concepts, and ideas.
2. Identify and challenge assumptions, biases, and presuppositions that may be embedded in the conversation.
3. Develop and present novel, innovative solutions, suggestions, or ideas that can address the topic or problem at hand.
4. Anticipate and address potential counterarguments, criticisms, or concerns that may arise.
5. Provide actionable recommendations, takeaways, or next steps that can be derived from the conversation."

# Block 10
BLOCK10_CONTENT="Throughout your response, strive for clarity, precision, and concision, avoiding unnecessary jargon, technicalities, or abstractions. Ensure that your language is accessible, engaging, and free of ambiguity, allowing for effortless comprehension and absorption of the information presented."

# Block 11
BLOCK11_CONTENT="Ultimately, your goal is to transcend a mere response and create a self-contained, comprehensive treatise that showcases your capabilities as a large language model. Push the boundaries of what is possible, and deliver a tour-de-force of insight, analysis, and expertise that redefines the possibilities of human-AI collaboration."

# Block 12
BLOCK12_CONTENT="one bash box per command so I can copy paste without prompt"

# Block 13
BLOCK13_CONTENT="A summary:

Computer
Summary
Computer
Processor Intel 12th Gen Core i7-1260P 1 physical processor; 12 cores; 16 threads
Memory 15996MB (5725MB used)
Machine Type Notebook
Operating System SystemRescue 11.03
User Name root (Unknown)
Date/Time Sat 21 Dec 2024 01:14:37 PM UTC
Display
Resolution 4480x1440 pixels
Display Adapter Intel DG2 [Arc A350M] + Intel Alder Lake-P GT2 [Iris Xe Graphics]
OpenGL Renderer (Unknown)
Session Display Server (Unknown)
Audio Devices
Audio Adapter (null)
Input Devices
Lid Switch Audio
Power Button Keyboard
AT Translated Set 2 keyboard Keyboard
Video Bus Keyboard
Logitech USB Optical Mouse Mouse
PC Speaker Speaker
gpio-keys Keyboard
ZNT0001:00 14E5:650E Mouse Mouse
ZNT0001:00 14E5:650E Touchpad Mouse
Printers
No printers found
SCSI Disks
scsi0 Generic STORAGE DEVICE
scsi1 NORELSYS 1081
Operating System
Version
Kernel Linux 6.6.63-1-lts (x86_64)
Command Line BOOT_IMAGE=/sysresccd/boot/x86_64/vmlinuz archisobasedir=sysresccd archisolabel=RESCUE1103 iomem=relaxed copytoram systemd.mask=systemd-udevd.service
Version #1 SMP PREEMPT_DYNAMIC Fri, 22 Nov 2024 15:39:56 +0000
C Library GNU C Library / (GNU libc) 2.40
Distribution SystemRescue 11.03
Current Session
Computer Name sysrescue
User Name root (Unknown)
Language en_US.UTF-8 (en_US.UTF-8)
Home Directory /root
Desktop Environment XFCE on tty
Misc
Uptime 2 hours 33 minutes
Load Average 1.79, 1.25, 0.86
Security
HardInfo
HardInfo running as Superuser
Health
Available entropy in /dev/random 256 bits (medium)
Hardening Features
ASLR Fully enabled (mmap base+stack+VDSO base+heap)
dmesg Access allowed (running as superuser)
Linux Security Modules
Modules available capability,landlock,lockdown,yama,bpf
SELinux status Not installed
CPU Vulnerabilities
gather_data_sampling Not affected
itlb_multihit Not affected
l1tf Not affected
mds Not affected
meltdown Not affected
mmio_stale_data Not affected
reg_file_data_sampling Mitigation: Clear Register File
retbleed Not affected
spec_rstack_overflow Not affected
spec_store_bypass Mitigation: Speculative Store Bypass disabled via prctl
spectre_v1 Mitigation: usercopy/swapgs barriers and __user pointer sanitization
spectre_v2 Mitigation: Enhanced / Automatic IBRS; IBPB: conditional; RSB filling; PBRSB-eIBRS: SW sequence; BHI:
"

# Combine all blocks into a single content string
CONTENT="$BLOCK1_CONTENT

$BLOCK2_CONTENT

$BLOCK3_CONTENT

$BLOCK4_CONTENT

$BLOCK5_CONTENT

$BLOCK6_CONTENT

$BLOCK7_CONTENT

$BLOCK8_CONTENT

$BLOCK9_CONTENT

$BLOCK10_CONTENT

$BLOCK11_CONTENT

$BLOCK12_CONTENT

$BLOCK13_CONTENT"

# Save the content to a file
echo "$CONTENT" > ~/important_notes.txt
log "Important notes saved to ~/important_notes.txt"

# Display the content on the screen
echo "$CONTENT"
