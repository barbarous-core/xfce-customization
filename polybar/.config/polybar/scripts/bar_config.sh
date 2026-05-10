#!/bin/bash

# Define Rofi Theme (Matching your workspace selector)
THEME="window { width: 35%; border: 0px; border-radius: 20px; background-color: #282a2e; } 
       listview { lines: 3; }
       element { padding: 15px; background-color: transparent; }
       element-text { font: \"JetBrainsMono Nerd Font 16\"; horizontal-align: 0; text-color: #c5c8c6; }
       element selected { background-color: #61afef; }
       element-text selected { text-color: #282a2e; }
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
