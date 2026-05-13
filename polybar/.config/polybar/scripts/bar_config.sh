#!/bin/bash

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

# Define Rofi Theme (Dynamic)
THEME="window { width: 35%; border: 0px; border-radius: 0px; background-color: $BG; } 
       mainbox { border: 0px; }
       listview { lines: 3; border: 0px; scrollbar: false; }
       element { padding: 10px; background-color: transparent; }
       element-text { font: \"JetBrainsMono Nerd Font 11\"; horizontal-align: 0; text-color: $FG; }
       element selected { background-color: transparent; }
       element-text selected { text-color: $ACCENT; }
       inputbar { enabled: true; padding: 10px; background-color: $BG; border: 0px; }
       prompt { text-color: $FG; font: \"JetBrainsMono Nerd Font 11\"; }
       entry { enabled: false; }"





MONITOR=$1
FRIENDLY_NAME=$2

TOP_OPT="⬆️ Polybar at Top"
BOTTOM_OPT="⬇️ Polybar at Bottom"
NONE_OPT="🚫 Don't show Polybar"
OPTIONS="${TOP_OPT}\n${BOTTOM_OPT}\n${NONE_OPT}"

# Show Rofi menu
CHOICE=$(echo -e "$OPTIONS" | rofi -dmenu -p "Where position in screen? ($FRIENDLY_NAME)" -theme-str "$THEME" -location 0 -monitor -1)

if [ "$CHOICE" == "$BOTTOM_OPT" ]; then
    echo "true"
elif [ "$CHOICE" == "$NONE_OPT" ]; then
    echo "none"
else
    echo "false"
fi


