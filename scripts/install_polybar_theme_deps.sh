#!/usr/bin/env bash
# =============================================================================
# Script to install dependencies for adi1090x/polybar-themes
# =============================================================================

set -euo pipefail

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${YELLOW}==> Checking and installing dependencies for Polybar Themes...${NC}"

# 1. Install Fedora Packages
echo -e "\n${GREEN}--> Installing system packages (polybar, rofi, calc, pipx)...${NC}"
sudo dnf install -y polybar rofi calc pipx fontconfig wget git unzip

# 2. Install Pywal (using pipx to respect Fedora's PEP-668 Python environment)
echo -e "\n${GREEN}--> Installing pywal...${NC}"
if ! command -v wal &> /dev/null; then
    pipx install pywal
    # Ensure pipx path is available
    pipx ensurepath
else
    echo "pywal is already installed."
fi

# 3. Install networkmanager_dmenu
echo -e "\n${GREEN}--> Installing networkmanager_dmenu...${NC}"
if ! command -v networkmanager_dmenu &> /dev/null; then
    mkdir -p ~/.local/bin
    curl -sSL "https://raw.githubusercontent.com/firecat53/networkmanager-dmenu/main/networkmanager_dmenu" -o ~/.local/bin/networkmanager_dmenu
    chmod +x ~/.local/bin/networkmanager_dmenu
    
    # Needs networkmanager glib module for python
    sudo dnf install -y NetworkManager-libnm python3-gobject
else
    echo "networkmanager_dmenu is already installed."
fi

# 4. Install Fonts
echo -e "\n${GREEN}--> Installing Fonts...${NC}"
FONT_DIR="$HOME/.local/share/fonts"
mkdir -p "$FONT_DIR"

# Download and copy fonts from the polybar-themes repo directly if needed,
# though the repo's setup.sh automatically copies fonts to ~/.local/share/fonts!
# We will just verify if we should run the repo's fonts setup or just remind the user.

echo "Note: The specific Icon and Text fonts (Iosevka Nerd Font, Fantasque Sans Mono, Noto Sans, Droid Sans, Terminus, Icomoon Feather, Material Icons, Waffle/Siji) are INCLUDED in the polybar-themes repository."
echo "When you run the repository's setup.sh script, it automatically installs all of these fonts for you."

# Update font cache
echo -e "\n${GREEN}--> Updating font cache...${NC}"
fc-cache -fv &> /dev/null

echo -e "\n${GREEN}==> All dependencies installed successfully!${NC}"
echo -e "${YELLOW}Next steps:${NC}"
echo "1. Restart your terminal to ensure ~/.local/bin is in your PATH."
echo "2. Run the polybar-themes installer script: cd ~/Linux_Data/Git_Projects/xfce-customization/polybar-themes-repo && ./setup.sh"
