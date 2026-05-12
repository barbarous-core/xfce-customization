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
CONFIG_DIR="/home/mohamed/Linux_Data/Git_Projects/xfce-customization/polybar/.config/polybar"
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

CSS="
window, #yad-dialog-window {
    background-color: $BG;
    color: $FG;
    font-family: 'JetBrainsMono Nerd Font';
    border: none;
    border-radius: 0px;
}
label {
    font-size: 11pt;
    margin: 10px;
    text-shadow: none;
}
button {
    background: transparent;
    color: $ACCENT;
    border: none;
    box-shadow: none;
    text-shadow: none;
    font-size: 11pt;
    padding: 10px;
    margin: 5px;
    outline: none;
}
button:hover {
    background: transparent;
    color: $FG;
}
"









TERM_LIST=$(filter_apps "${TERMS[@]}")
BROWSER_LIST=$(filter_apps "${BROWSERS[@]}")
FILE_LIST=$(filter_apps "${FILES[@]}")

# Show YAD form
RESULT=$(yad --form --title="Default Applications" --width=450 --center \
    --class="PolybarDialog" \
    --text="Select your preferred <span foreground='$ACCENT' weight='bold'>Default Applications</span>" \
    --field="  Terminal:CB" "$TERM_LIST" \
    --field="  Browser:CB" "$BROWSER_LIST" \
    --field="  File Manager:CB" "$FILE_LIST" \
    --button="OK:0" --button="Cancel:1" \
    --window-icon="preferences-desktop-default-applications" \
    --undecorated --skip-taskbar \
    --css=<(echo "$CSS") \
    --fontname="JetBrainsMono Nerd Font 10")

# Exit if cancelled
[ $? -ne 0 ] && exit 1

# Output result (format: term|browser|file|)
echo "$RESULT"
