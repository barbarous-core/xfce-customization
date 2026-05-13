#!/bin/bash

# Default modules definitions
DEF_LEFT="jgmenu sep xworkspaces sep add-workspace sep scroll-window sep"
DEF_CENTER="date"
DEF_RIGHT="sep sys-switch sep xkeyboard sep media sep battery sep connection sep themes sep powermenu"

# CONFIG DIR
CONFIG_DIR="$HOME/.config/polybar"
COLORS_CONF="$CONFIG_DIR/colors.ini"
# Path to centralized YAD CSS
YAD_STYLE="$HOME/.config/yad/style.css"

NAME=$1

# Calculate 80% of the screen width
SCREEN_WIDTH=$(xrandr --current | grep '*' | awk '{print $1}' | cut -d 'x' -f1 | head -n 1)
[ -z "$SCREEN_WIDTH" ] && SCREEN_WIDTH=1920
WIN_WIDTH=$((SCREEN_WIDTH * 2 / 3))

# Show YAD form with checkboxes horizontally
CHOICE=$(yad --form \
    --class="PolybarDialog" \
    --title="Module Config" \
    --text="Select segments to show in $NAME" \
    --image="$HOME/.config/polybar/preview.png" \
    --width="$WIN_WIDTH" \
    --field="Left Segments:CHK" "TRUE" \
    --field="Center Segments:CHK" "TRUE" \
    --field="Right Segments:CHK" "TRUE" \
    --button="Cancel:1" \
    --button="Save:0" \
    --center \
    --undecorated \
    --skip-taskbar \
    --css="$YAD_STYLE" \
    --fontname="JetBrainsMono Nerd Font 11")




# Exit if cancelled
[ $? -ne 0 ] && exit 1

# Parse result (field 1 = IMG, so checkboxes start at f2)
SHOW_LEFT=$(echo "$CHOICE" | cut -d'|' -f1)
SHOW_CENTER=$(echo "$CHOICE" | cut -d'|' -f2)
SHOW_RIGHT=$(echo "$CHOICE" | cut -d'|' -f3)

# Build strings
OUT_LEFT=" "
[ "$SHOW_LEFT" == "TRUE" ] && OUT_LEFT="$DEF_LEFT"

OUT_CENTER=" "
[ "$SHOW_CENTER" == "TRUE" ] && OUT_CENTER="$DEF_CENTER"

OUT_RIGHT=" "
[ "$SHOW_RIGHT" == "TRUE" ] && OUT_RIGHT="$DEF_RIGHT"

# Output as piped format
echo "$OUT_LEFT|$OUT_CENTER|$OUT_RIGHT"

