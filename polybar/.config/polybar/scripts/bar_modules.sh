#!/bin/bash

# Default modules definitions
DEF_LEFT="jgmenu themes sep xworkspaces sep add-workspace sep scroll-window sep"
DEF_CENTER="date"
DEF_RIGHT="sep sys-switch sep xkeyboard sep media sep battery sep connection sep powermenu"

# CONFIG DIR
CONFIG_DIR="$HOME/.config/polybar"
YAD_STYLE="$HOME/.config/yad/style.css"
NAME=$1

# Show YAD form with 3 columns for modules
CHOICE=$(yad --form \
    --class="PolybarDialog" \
    --title="Module Config" \
    --text="Choose your modules section to show" \
    --columns=3 \
    --field=" [   Start Menu | 󰏘 Theme |  Workspace 1 2 3 | 󰖯 Window Title ] :CHK"   "TRUE" \
    --field=" [ 󰃰 Time & Date ] :CHK" "TRUE" \
    --field=" [  System Monitoring | 󰌌 Keyboard | 󰕾 Media | 󰁹 Battery |   Connections |  Power ] :CHK"  "TRUE" \
    --button="Cancel:1" \
    --button="Save:0" \
    --center \
    --undecorated \
    --skip-taskbar \
    --css="$YAD_STYLE" \
    --width=600 --height=200)

# Exit if cancelled
[ $? -ne 0 ] && exit 1

# Parse result (3 checkboxes)
SHOW_LEFT=$(echo "$CHOICE"   | cut -d'|' -f1)
SHOW_CENTER=$(echo "$CHOICE" | cut -d'|' -f2)
SHOW_RIGHT=$(echo "$CHOICE"  | cut -d'|' -f3)

# Build output strings
OUT_LEFT=" ";   [ "$SHOW_LEFT"   == "TRUE" ] && OUT_LEFT="$DEF_LEFT"
OUT_CENTER=" "; [ "$SHOW_CENTER" == "TRUE" ] && OUT_CENTER="$DEF_CENTER"
OUT_RIGHT=" ";  [ "$SHOW_RIGHT"  == "TRUE" ] && OUT_RIGHT="$DEF_RIGHT"

# Output as piped format consumed by launch.sh
echo "$OUT_LEFT|$OUT_CENTER|$OUT_RIGHT"
