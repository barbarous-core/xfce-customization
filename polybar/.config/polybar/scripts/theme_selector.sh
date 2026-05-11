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
    notify-send "Themes" "Themes folder is empty. Add a folder with colors.ini to /themes/ to get started."
    exit 0
fi

# 2. Open Rofi
SELECTED=$(echo "$THEMES" | rofi -dmenu -p "Select Theme" -i -config "$ROFI_CONFIG")

if [ -n "$SELECTED" ]; then
    # 3. Apply Theme
    echo "$SELECTED" > "$THEME_STATE_FILE"
    
    # Copy the colors.ini to the polybar config folder
    cp "$THEME_DIR/$SELECTED/colors.ini" "/home/mohamed/Linux_Data/Git_Projects/xfce-customization/polybar/.config/polybar/colors.ini"
    
    # Sync colors to terminal and other apps using Pywal
    /home/mohamed/.local/bin/wal -n -q -f "$THEME_DIR/$SELECTED/colors.json"

    # Update Jgmenu colors
    BG=$(grep "background =" "$THEME_DIR/$SELECTED/colors.ini" | cut -d' ' -f3)
    FG=$(grep "foreground =" "$THEME_DIR/$SELECTED/colors.ini" | cut -d' ' -f3)
    PRI=$(grep "primary =" "$THEME_DIR/$SELECTED/colors.ini" | cut -d' ' -f3)
    ALT=$(grep "background-alt =" "$THEME_DIR/$SELECTED/colors.ini" | cut -d' ' -f3)

    sed -i "s/color_menu_bg = .*/color_menu_bg = $BG 100/" ~/.config/jgmenu/jgmenurc
    sed -i "s/color_menu_bg_to = .*/color_menu_bg_to = $BG 100/" ~/.config/jgmenu/jgmenurc
    sed -i "s/color_menu_border = .*/color_menu_border = $PRI 100/" ~/.config/jgmenu/jgmenurc
    sed -i "s/color_norm_fg = .*/color_norm_fg = $FG 100/" ~/.config/jgmenu/jgmenurc
    sed -i "s/color_sel_fg = .*/color_sel_fg = $PRI 100/" ~/.config/jgmenu/jgmenurc
    sed -i "s/color_sel_bg = .*/color_sel_bg = $ALT 100/" ~/.config/jgmenu/jgmenurc
    sed -i "s/color_sel_border = .*/color_sel_border = $ALT 100/" ~/.config/jgmenu/jgmenurc

    # Restart Polybar to apply colors
    polybar-msg cmd restart
fi
