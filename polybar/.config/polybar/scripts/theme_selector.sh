#!/bin/bash

# Configuration
THEME_DIR="/home/mohamed/Linux_Data/Git_Projects/xfce-customization/themes"
THEME_STATE_FILE="/tmp/polybar_active_theme"
ROFI_CONFIG="/home/mohamed/Linux_Data/Git_Projects/xfce-customization/rofi/.config/rofi/config.rasi"

# Check if directory exists
[ ! -d "$THEME_DIR" ] && mkdir -p "$THEME_DIR"

# 1. Get themes from directory
THEMES=$(ls -1 "$THEME_DIR")

if [ -z "$THEMES" ]; then
    # Create some dummy themes if empty
    mkdir -p "$THEME_DIR/Cyberpunk" "$THEME_DIR/Nordic" "$THEME_DIR/Premium_Gold"
    THEMES=$(ls -1 "$THEME_DIR")
fi

# 2. Open Rofi
SELECTED=$(echo "$THEMES" | rofi -dmenu -p "Select Theme" -i -config "$ROFI_CONFIG")

if [ -n "$SELECTED" ]; then
    # 3. Apply Theme (Initial logic: update state and restart bar)
    echo "$SELECTED" > "$THEME_STATE_FILE"
    
    # Optional: Here we will add logic to 'wal -i' or swap config files
    # notify-send "Theme Applied" "Switched to $SELECTED"
    
    polybar-msg cmd restart
fi
