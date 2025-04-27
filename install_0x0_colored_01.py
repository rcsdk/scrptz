#!/usr/bin/env python3
"""
Noir-Uploader installer – Parrot / Kali / Debian

1. Ensures curl + xclip are present (auto-installs them)
2. Drops /usr/local/bin/0x0 with a palette-cycling Braille spinner
3. Backs up any previous copy, syntax-checks, self-tests
"""

import os, subprocess, shutil, sys, textwrap, datetime

INSTALL_PATH = "/usr/local/bin/0x0"
PALETTE = [
    (197, 180, 127),  #  #c5b47f  – dark gold
    (122, 131, 131),  #  #7a8383
    (102,  99,  80),  #  #666350
    (128, 140, 129),  #  #808c81
    (156,  92,  52),  #  #9c5c34  – copper accent
    ( 68,  76,  72),  #  #444c48
    (141,  77,  50),  #  #8d4d32
]
# ---------------------------------------------------------------------
BASH_SCRIPT = r'''
#!/usr/bin/env bash
# Noir-Uploader – film-noir spinner for https://0x0.st

set -euo pipefail
UPLOAD_URL="https://0x0.st"

# ─── colour palette (24-bit) ─────────────────────────
COLORS=(
  "\e[38;2;197;180;127m"  # #c5b47f
  "\e[38;2;122;131;131m"  # #7a8383
  "\e[38;2;102;99;80m"    # #666350
  "\e[38;2;128;140;129m"  # #808c81
  "\e[38;2;156;92;52m"    # #9c5c34
  "\e[38;2;68;76;72m"     # #444c48
  "\e[38;2;141;77;50m"    # #8d4d32
)
RESET="\e[0m"

FRAMES=(⣾ ⣽ ⣻ ⢿ ⡿ ⣟ ⣯ ⣷)

spinner () {
    local pid=$1 i=0
    tput civis 2>/dev/null || true
    while kill -0 "$pid" 2>/dev/null; do
        local frame=${FRAMES[i%${#FRAMES[@]}]}
        local color=${COLORS[i%${#COLORS[@]}]}
        printf "\r${color}%s Uploading… %s${RESET}" "$frame" "$CURRENT"
        ((i++))
        sleep 0.08
    done
    tput cnorm 2>/dev/null || true
}

[[ $# -eq 0 ]] && { echo -e "${COLORS[0]}Usage:${RESET} 0x0 <file1> [file2 …]"; exit 1; }

for CURRENT in "$@"; do
    if [[ ! -f $CURRENT ]]; then
        echo -e "\e[31m✘ $CURRENT – not a regular file\e[0m" >&2
        continue
    fi
    TMP=$(mktemp)
    (curl -s -F "file=@${CURRENT}" "$UPLOAD_URL" >"$TMP") &
    spinner $!
    wait
    URL=$(<"$TMP"); rm -f "$TMP"
    printf "\r\e[32m✔%s${RESET} → %s\n" " $CURRENT" "$URL"

    if command -v xclip &>/dev/null; then
        printf '%s' "$URL" | xclip -selection clipboard
        echo "   (URL copied to clipboard)"
    fi
done
'''

# ---------------------------------------------------------------------
def run(cmd, **kw):
    kw.setdefault('text', True)
    return subprocess.run(cmd, check=True, **kw)

def ensure_root():
    if os.geteuid() != 0:
        sys.exit("This installer needs sudo / root privileges.")

def have(cmd): return shutil.which(cmd) is not None

def apt_install(pkgs):
    if pkgs:
        print("📦  Installing:", *pkgs)
        run(["apt-get", "update", "-qq"])
        run(["apt-get", "install", "-y"] + pkgs)

def backup(path):
    if os.path.isfile(path):
        stamp = datetime.datetime.now().strftime("%Y%m%d-%H%M%S")
        target = f"{path}.bak.{stamp}"
        shutil.copy2(path, target)
        print("🗄  Old script →", target)

def write_script():
    with open(INSTALL_PATH, 'w') as f:
        f.write(textwrap.dedent(BASH_SCRIPT).lstrip())
    os.chmod(INSTALL_PATH, 0o755)
    print("✅  New script written to", INSTALL_PATH)

def bash_ok():
    try:
        run(["bash", "-n", INSTALL_PATH])
        return True
    except subprocess.CalledProcessError:
        print("❌  Syntax error detected, aborting.")
        return False

def self_test():
    out = subprocess.run([INSTALL_PATH], text=True, capture_output=True).stdout.strip()
    if "Usage:" in out:
        print("🧪  Self-test passed.")
    else:
        print("⚠️  Something’s off. Output was:\n", out)

def main():
    ensure_root()

    # 1. deps (curl + xclip)
    missing = [cmd for cmd in ("curl", "xclip") if not have(cmd)]
    apt_install(missing)

    # 2. deploy
    backup(INSTALL_PATH)
    write_script()
    if not bash_ok(): sys.exit(1)

    # 3. quick test
    self_test()

    # 4. finale
    print(textwrap.dedent(f"""
    ──────────────────────────────────────────────
      Noir-Uploader installed  🎷🥃
      Use it like so:

          0x0 artwork.psd
          0x0 ~/Videos/teaser.mp4

      Spinner colours cycle through:
      {[f"#{r:02x}{g:02x}{b:02x}" for r,g,b in PALETTE]}

      The final URL is copied straight to your clipboard
      (xclip).  Works flawlessly in Parrot & Kali.

      Cue the saxophone, dim the lights, upload away…
    ──────────────────────────────────────────────
    """))

if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        print("\nAborted by user.")
