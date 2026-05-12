#!/bin/bash

# Define lists of potential applications
TERMS=("xfce4-terminal" "gnome-terminal" "alacritty" "kitty" "xterm" "tilix" "konsole")
BROWSERS=("firefox" "google-chrome" "brave-browser" "chromium" "microsoft-edge" "opera")
FILES=("thunar" "nautilus" "pcmanfm" "dolphin" "nemo")

# Function to filter available apps on the system
filter_apps() {
    local list=("$@")
    local filtered=""
    for app in "${list[@]}"; do
        if command -v "$app" >/dev/null 2>&1; then
            filtered+="$app!"
        fi
    done
    echo "${filtered%?}"
}

# CONFIG DIR
CONFIG_DIR="$HOME/.config/polybar"
COLORS_CONF="$CONFIG_DIR/colors.ini"

# Extract colors from colors.ini
BG=$(grep "^background =" "$COLORS_CONF" | cut -d' ' -f3)
FG=$(grep "^foreground =" "$COLORS_CONF" | cut -d' ' -f3)
ACCENT=$(grep "^primary =" "$COLORS_CONF" | cut -d' ' -f3)

[ -z "$BG" ] && BG="#1c1c1c"
[ -z "$FG" ] && FG="#ecf0f1"
[ -z "$ACCENT" ] && ACCENT="#3498db"

# Extract radius from config.ini
RADIUS=$(grep "^radius =" "$CONFIG_DIR/config.ini" | cut -d' ' -f3)
[ -z "$RADIUS" ] && RADIUS="12"

# Path to centralized YAD CSS
YAD_STYLE="$HOME/.config/yad/style.css"


TERM_LIST=$(filter_apps "${TERMS[@]}")
BROWSER_LIST=$(filter_apps "${BROWSERS[@]}")
FILE_LIST=$(filter_apps "${FILES[@]}")

# Show YAD form with dropdowns
CHOICE=$(yad --form \
    --class="PolybarDialog" \
    --title="App Preference" \
    --text="Select preferred applications" \
    --field="Terminal:CB" "$TERM_LIST" \
    --field="Browser:CB" "$BROWSER_LIST" \
    --field="File Manager:CB" "$FILE_LIST" \
    --button="Save:0" \
    --center \
    --fixed \
    --undecorated \
    --skip-taskbar \
    --css="$YAD_STYLE" \
    --fontname="JetBrainsMono Nerd Font 11")

# Exit if cancelled
[ $? -ne 0 ] && exit 1

# Output result
echo "$CHOICE"

