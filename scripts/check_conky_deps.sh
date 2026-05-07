#!/bin/bash

# --- Color Definitions ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}=== Conky Theme Dependency Checker ===${NC}\n"

# --- 1. Detect Distribution ---
if [ -f /etc/os-release ]; then
    . /etc/os-release
    DISTRO=$ID
else
    echo -e "${RED}Error: Cannot detect Linux distribution.${NC}"
    exit 1
fi

# --- 2. Define Package Maps ---
case $DISTRO in
    fedora)
        PKGS=("conky" "python3" "vnstat" "iproute2" "moc" "lm_sensors")
        INSTALL_CMD="sudo dnf install -y"
        ;;
    ubuntu|debian|kali|linuxmint|pop)
        PKGS=("conky-all" "python3" "vnstat" "iproute2" "mocp" "lm-sensors")
        INSTALL_CMD="sudo apt update && sudo apt install -y"
        ;;
    arch|manjaro|endeavouros)
        PKGS=("conky" "python" "vnstat" "iproute2" "moc" "lm_sensors")
        INSTALL_CMD="sudo pacman -S --needed --noconfirm"
        ;;
    *)
        echo -e "${RED}Unsupported distro. Please install Conky, Python3, vnstat, iproute2, mocp, and lm-sensors manually.${NC}"
        exit 1
        ;;
esac

# --- 3. Check Commands & Versions ---
MISSING_PKGS=()

check_conky() {
    if ! command -v conky &> /dev/null; then
        echo -e "${RED}[MISSING] Conky is not installed.${NC}"
        return 1
    fi
    
    VERSION=$(conky --version | head -n 1 | awk '{print $2}')
    FEATURES=$(conky --version)
    
    echo -ne "Conky $VERSION: "
    if [[ $(echo -e "1.10\n$VERSION" | sort -V | head -n1) == "1.10" ]] && echo "$FEATURES" | grep -iq "Lua" && echo "$FEATURES" | grep -iq "Cairo"; then
        echo -e "${GREEN}[OK] (Lua + Cairo found)${NC}"
        return 0
    else
        echo -e "${RED}[FAIL] (Requires >= 1.10 with Lua + Cairo)${NC}"
        return 1
    fi
}

check_cmd() {
    if command -v "$1" &> /dev/null; then
        echo -e "${GREEN}[OK] $1 is installed.${NC}"
        return 0
    else
        echo -e "${YELLOW}[MISSING] $1${NC}"
        return 1
    fi
}

# Run Checks
echo -e "${BLUE}Checking Requirements...${NC}"
check_conky || MISSING_PKGS+=("${PKGS[0]}")
check_cmd "python3" || MISSING_PKGS+=("${PKGS[1]}")
check_cmd "vnstat" || MISSING_PKGS+=("${PKGS[2]}")
check_cmd "ip" || MISSING_PKGS+=("${PKGS[3]}")

echo -e "\n${BLUE}Checking Optional components...${NC}"
# Special check for moc/mocp
if command -v mocp &> /dev/null || command -v moc &> /dev/null; then
    echo -e "${GREEN}[OK] MOC (Music Player) is installed.${NC}"
else
    echo -e "${YELLOW}[MISSING] MOC (Music Player)${NC}"
    MISSING_PKGS+=("${PKGS[4]}")
fi

check_cmd "sensors" || MISSING_PKGS+=("${PKGS[5]}")

# --- 4. Final Action ---
if [ ${#MISSING_PKGS[@]} -eq 0 ]; then
    echo -e "\n${GREEN}Everything is ready! You can now run your Conky themes.${NC}"
else
    echo -e "\n${YELLOW}Some dependencies are missing. Attempting to install...${NC}"
    echo -e "${BLUE}Packages: ${MISSING_PKGS[*]}${NC}"
    
    $INSTALL_CMD "${MISSING_PKGS[@]}"
    
    if [ $? -eq 0 ]; then
        echo -e "\n${GREEN}Installation successful!${NC}"
        # Start vnstat daemon if just installed
        if [[ " ${MISSING_PKGS[*]} " == *" vnstat "* ]]; then
            echo -e "${BLUE}Starting vnStat service...${NC}"
            sudo systemctl enable --now vnstat
        fi
        echo -e "${GREEN}All requirements met.${NC}"
    else
        echo -e "\n${RED}Failed to install dependencies.${NC}"
    fi
fi
