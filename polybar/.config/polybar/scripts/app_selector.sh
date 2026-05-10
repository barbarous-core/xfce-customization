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

TERM_LIST=$(filter_apps "${TERMS[@]}")
BROWSER_LIST=$(filter_apps "${BROWSERS[@]}")
FILE_LIST=$(filter_apps "${FILES[@]}")

# Show YAD form
RESULT=$(yad --form --title="Default Applications" --width=450 --center \
    --text="Select your preferred <span foreground='#61afef' weight='bold'>Default Applications</span>" \
    --field="  Terminal:CB" "$TERM_LIST" \
    --field="  Browser:CB" "$BROWSER_LIST" \
    --field="  File Manager:CB" "$FILE_LIST" \
    --button="OK:0" --button="Cancel:1" \
    --window-icon="preferences-desktop-default-applications" \
    --fontname="JetBrainsMono Nerd Font 10")

# Exit if cancelled
[ $? -ne 0 ] && exit 1

# Output result (format: term|browser|file|)
echo "$RESULT"
