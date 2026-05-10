#!/bin/bash

# Default modules definitions
DEF_LEFT="jgmenu sep xworkspaces sep add-workspace sep scroll-window sep"
DEF_CENTER="date"
DEF_RIGHT="sep sys-switch sep xkeyboard sep pulseaudio mic sep battery sep powermenu"

NAME=$1

# Show YAD form with checkboxes
# 1: Left, 2: Center, 3: Right, 4: Disable
RESULT=$(yad --form --title="Modules for $NAME" --center \
    --text="Select sections to show on <span foreground='#3498db' weight='bold'>$NAME</span>" \
    --field="  Show Left Section (Menu & Workspaces):CHK" TRUE \
    --field="  Show Center Section (Clock & Date):CHK" TRUE \
    --field="  Show Right Section (System Indicators):CHK" TRUE \
    --field="  Don't show Polybar on this screen" FALSE \
    --button="OK:0" --width=450 --height=300 \
    --window-icon="preferences-desktop-display" \
    --fontname="JetBrainsMono Nerd Font 10")

# Exit if cancelled
[ $? -ne 0 ] && exit 1

# Parse result
SHOW_LEFT=$(echo $RESULT | cut -d'|' -f1)
SHOW_CENTER=$(echo $RESULT | cut -d'|' -f2)
SHOW_RIGHT=$(echo $RESULT | cut -d'|' -f3)
DISABLE_BAR=$(echo $RESULT | cut -d'|' -f4)

if [ "$DISABLE_BAR" == "TRUE" ]; then
    echo "DISABLED"
    exit 0
fi

# Build strings
OUT_LEFT=" "
[ "$SHOW_LEFT" == "TRUE" ] && OUT_LEFT="$DEF_LEFT"

OUT_CENTER=" "
[ "$SHOW_CENTER" == "TRUE" ] && OUT_CENTER="$DEF_CENTER"

OUT_RIGHT=" "
[ "$SHOW_RIGHT" == "TRUE" ] && OUT_RIGHT="$DEF_RIGHT"

# Output as piped format
echo "$OUT_LEFT|$OUT_CENTER|$OUT_RIGHT"
