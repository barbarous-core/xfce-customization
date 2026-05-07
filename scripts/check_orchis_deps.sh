#!/bin/bash

# --- Color Definitions ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}=== Orchis Theme Dependency Checker ===${NC}\n"

# --- 1. Detect Distribution ---
if [ -f /etc/os-release ]; then
    . /etc/os-release
    DISTRO=$ID
else
    echo -e "${RED}Error: Cannot detect Linux distribution.${NC}"
    exit 1
fi

# --- 2. Check GTK Version (>= 3.20) ---
GTK_VERSION=$(pkg-config --modversion gtk+-3.0 2>/dev/null)
if [ -z "$GTK_VERSION" ]; then
    echo -e "${YELLOW}Warning: GTK+ 3.0 not found via pkg-config. Checking alternative methods...${NC}"
    # Fallback for systems without pkg-config dev headers
    if command -v dpkg &> /dev/null; then
        GTK_VERSION=$(dpkg -l libgtk-3-0 2>/dev/null | grep libgtk-3-0 | awk '{print $3}' | cut -d'-' -f1)
    fi
fi

if [[ ! -z "$GTK_VERSION" ]]; then
    # Simple version comparison
    if [[ $(echo -e "3.20\n$GTK_VERSION" | sort -V | head -n1) == "3.20" ]]; then
        echo -e "${GREEN}[OK] GTK version: $GTK_VERSION${NC}"
    else
        echo -e "${RED}[FAIL] GTK version $GTK_VERSION is too old (Requires >= 3.20)${NC}"
        exit 1
    fi
else
    echo -e "${YELLOW}[?] GTK version could not be determined. Assuming modern system...${NC}"
fi

# --- 3. Define Package Names based on Distro ---
case $DISTRO in
    ubuntu|debian|kali|linuxmint|pop)
        MURRINE="gtk2-engines-murrine"
        GNOME_THEMES="gnome-themes-extra"
        SASSC="sassc"
        INSTALL_CMD="sudo apt update && sudo apt install -y"
        ;;
    arch|manjaro|endeavouros)
        MURRINE="gtk-engine-murrine"
        GNOME_THEMES="gnome-themes-extra"
        SASSC="sassc"
        INSTALL_CMD="sudo pacman -S --needed --noconfirm"
        ;;
    fedora)
        MURRINE="gtk-murrine-engine"
        GNOME_THEMES="gnome-themes-extra"
        SASSC="sassc"
        INSTALL_CMD="sudo dnf install -y"
        ;;
    opensuse*|suse)
        MURRINE="gtk2-engine-murrine"
        GNOME_THEMES="gnome-themes-extra"
        SASSC="sassc"
        INSTALL_CMD="sudo zypper install -y"
        ;;
    *)
        echo -e "${RED}Unsupported distribution: $DISTRO${NC}"
        echo "Please install gnome-themes-extra, murrine engine, and sassc manually."
        exit 1
        ;;
esac

# --- 4. Check/Install Dependencies ---
MISSING_PKGS=()

check_pkg() {
    case $DISTRO in
        ubuntu|debian|kali|linuxmint|pop) dpkg -l "$1" &> /dev/null ;;
        arch|manjaro|endeavouros) pacman -Qi "$1" &> /dev/null ;;
        fedora|opensuse*|suse) rpm -q "$1" &> /dev/null ;;
    esac
}

echo -e "\n${BLUE}Checking packages...${NC}"

for pkg in "$MURRINE" "$GNOME_THEMES" "$SASSC"; do
    if check_pkg "$pkg"; then
        echo -e "${GREEN}[INSTALLED] $pkg${NC}"
    else
        echo -e "${YELLOW}[MISSING]   $pkg${NC}"
        MISSING_PKGS+=("$pkg")
    fi
done

# --- 5. Final Action ---
if [ ${#MISSING_PKGS[@]} -eq 0 ]; then
    echo -e "\n${GREEN}Success: All dependencies are met! You can now install the Orchis theme.${NC}"
else
    echo -e "\n${YELLOW}Missing dependencies found. Attempting to install...${NC}"
    echo -e "${BLUE}Command: $INSTALL_CMD ${MISSING_PKGS[*]}${NC}"
    eval "$INSTALL_CMD ${MISSING_PKGS[*]}"
    
    if [ $? -eq 0 ]; then
        echo -e "\n${GREEN}Installation complete. You can now install the Orchis theme.${NC}"
    else
        echo -e "\n${RED}Failed to install dependencies. Please check your internet connection or package manager.${NC}"
        exit 1
    fi
fi
