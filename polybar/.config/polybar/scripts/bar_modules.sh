#!/bin/bash

# Default modules definitions
DEF_LEFT="jgmenu sep xworkspaces sep add-workspace sep scroll-window sep"
DEF_CENTER="date"
DEF_RIGHT="sep sys-switch sep xkeyboard sep media sep battery sep connection sep themes sep powermenu"

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









NAME=$1

# Show YAD form with checkboxes
# 1: Left, 2: Center, 3: Right, 4: Disable
RESULT=$(yad --form --title="Modules for $NAME" --center \
    --class="PolybarDialog" \
    --text="Select sections to show on <span foreground='$ACCENT' weight='bold'>$NAME</span>" \
    --field="  Show Left Section (Menu & Workspaces):CHK" TRUE \
    --field="  Show Center Section (Clock & Date):CHK" TRUE \
    --field="  Show Right Section (System Indicators):CHK" TRUE \
    --button="OK:0" --width=450 --height=260 \
    --window-icon="preferences-desktop-display" \
    --undecorated --skip-taskbar \
    --css=<(echo "$CSS") \
    --fontname="JetBrainsMono Nerd Font 10")

# Exit if cancelled
[ $? -ne 0 ] && exit 1

# Parse result
SHOW_LEFT=$(echo $RESULT | cut -d'|' -f1)
SHOW_CENTER=$(echo $RESULT | cut -d'|' -f2)
SHOW_RIGHT=$(echo $RESULT | cut -d'|' -f3)

# Build strings
OUT_LEFT=" "
[ "$SHOW_LEFT" == "TRUE" ] && OUT_LEFT="$DEF_LEFT"

OUT_CENTER=" "
[ "$SHOW_CENTER" == "TRUE" ] && OUT_CENTER="$DEF_CENTER"

OUT_RIGHT=" "
[ "$SHOW_RIGHT" == "TRUE" ] && OUT_RIGHT="$DEF_RIGHT"

# Output as piped format
echo "$OUT_LEFT|$OUT_CENTER|$OUT_RIGHT"

