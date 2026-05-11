#!/bin/bash

# Configuration
WS_INDEX=$1
X_POS=$2
Y_OFFSET=$3
COLORS_FILE="/home/mohamed/Linux_Data/Git_Projects/xfce-customization/polybar/.config/polybar/colors.ini"

# Get colors from colors.ini
BG=$(grep "background =" "$COLORS_FILE" | cut -d' ' -f3)
FG=$(grep "foreground =" "$COLORS_FILE" | cut -d' ' -f3)
PRIMARY=$(grep "primary =" "$COLORS_FILE" | cut -d' ' -f3)
ALERT=$(grep "alert =" "$COLORS_FILE" | cut -d' ' -f3)

# Options
RENAME_OPTION="<span color='#98c379'><b>[RENAME THIS WORKSPACE]</b></span>"
DELETE_OPTION="<span color='$ALERT'><b>[DELETE THIS WORKSPACE]</b></span>"

# Rofi Theme (Dynamic)
THEME="window { width: 33%; border: 2px; border-color: $PRIMARY; border-radius: 20px; background-color: $BG; } 
       listview { lines: 10; }
       element { padding: 15px; border-radius: 12px; }
       element-text { font: \"JetBrainsMono Nerd Font 18\"; horizontal-align: 0.5; text-color: $FG; }
       element selected { background-color: $PRIMARY; }
       element-text selected { text-color: $BG; }"

# Get open windows on this workspace
WINDOWS=$(wmctrl -l | awk -v ws="$WS_INDEX" '$2 == ws { $1=$2=$3=""; print $0 }' | sed 's/^ *//')

# Build the list
LIST="$RENAME_OPTION\n$DELETE_OPTION"
if [ -n "$WINDOWS" ]; then
    LIST="$LIST\n$WINDOWS"
fi

# Show Rofi
SELECTED=$(echo -e "$LIST" | rofi -dmenu -p "Workspace $WS_INDEX" -theme-str "$THEME" -location 1 -xoffset "$X_POS" -yoffset "$Y_OFFSET")

if [ "$SELECTED" == "$RENAME_OPTION" ]; then
    bash /home/mohamed/Linux_Data/Git_Projects/xfce-customization/polybar/.config/polybar/scripts/rename_workspace.sh "$WS_INDEX"
elif [ "$SELECTED" == "$DELETE_OPTION" ]; then
    bash /home/mohamed/Linux_Data/Git_Projects/xfce-customization/polybar/.config/polybar/scripts/delete_workspace.sh "$WS_INDEX"
elif [ -n "$SELECTED" ]; then
    # Focus the selected window
    wmctrl -a "$SELECTED"
fi
