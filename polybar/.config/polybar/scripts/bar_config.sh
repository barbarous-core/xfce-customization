#!/bin/bash

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

# Define Rofi Theme (Dynamic)
THEME="window { width: 35%; border: 0px; border-radius: 20px; background-color: $BG; } 
       listview { lines: 3; }
       element { padding: 15px; background-color: transparent; }
       element-text { font: \"JetBrainsMono Nerd Font 16\"; horizontal-align: 0; text-color: $FG; }
       element selected { background-color: $ACCENT; }
       element-text selected { text-color: $BG; }
       inputbar { enabled: false; }"


MONITOR=$1
FRIENDLY_NAME=$2

TOP_OPT="⬆️ Polybar at Top ($FRIENDLY_NAME)"
BOTTOM_OPT="⬇️ Polybar at Bottom ($FRIENDLY_NAME)"
NONE_OPT="🚫 Don't show Polybar at ($FRIENDLY_NAME)"
OPTIONS="${TOP_OPT}\n${BOTTOM_OPT}\n${NONE_OPT}"

# Show Rofi menu
CHOICE=$(echo -e "$OPTIONS" | rofi -dmenu -p "Position for $FRIENDLY_NAME" -theme-str "$THEME" -location 0 -monitor -1)

if [ "$CHOICE" == "$BOTTOM_OPT" ]; then
    echo "true"
elif [ "$CHOICE" == "$NONE_OPT" ]; then
    echo "none"
else
    echo "false"
fi

