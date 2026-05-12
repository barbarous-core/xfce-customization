#!/bin/bash

# Default modules definitions
DEF_LEFT="jgmenu sep xworkspaces sep add-workspace sep scroll-window sep"
DEF_CENTER="date"
DEF_RIGHT="sep sys-switch sep xkeyboard sep media sep battery sep connection sep themes sep powermenu"

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





NAME=$1

# Show YAD form with checkboxes
CHOICE=$(yad --form \
    --class="PolybarDialog" \
    --title="Module Config" \
    --text="Select segments to show in $NAME" \
    --field="Left Segments:CHK" "$L_CHK" \
    --field="Center Segments:CHK" "$C_CHK" \
    --field="Right Segments:CHK" "$R_CHK" \
    --button="Cancel:1" \
    --button="Save:0" \
    --center \
    --fixed \
    --undecorated \
    --skip-taskbar \
    --css="$YAD_STYLE" \
    --fontname="JetBrainsMono Nerd Font 11")




# Exit if cancelled
[ $? -ne 0 ] && exit 1

# Parse result
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

