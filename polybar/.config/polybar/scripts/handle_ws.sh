#!/bin/bash

INDEX=$1
X_POS=$2
Y_OFFSET=$3

# Get the list of windows on this workspace
WINDOWS=$(wmctrl -l | awk -v ws=$INDEX '$2 == ws {print $0}' | cut -d' ' -f5-)

# Show Rofi menu with a Red Delete option at the top
DELETE_OPTION="<span color='#ff5555'><b>[DELETE THIS WORKSPACE]</b></span>"
CHOICE=$(echo -e "$DELETE_OPTION\n$WINDOWS" | rofi -dmenu -markup-rows -p "WS $((INDEX+1))" -location 1 -xoffset "$X_POS" -yoffset "$Y_OFFSET")

if [ "$CHOICE" = "$DELETE_OPTION" ]; then
    # Confirmation dialog
    if zenity --question --text "Are you sure you want to delete workspace $((INDEX+1))?" --title "Delete Workspace"; then
        # Delete the workspace using XFCE command
        WS_COUNT=$(xfconf-query -c xfwm4 -p /general/workspace_count)
        xfconf-query -c xfwm4 -p /general/workspace_count -s $((WS_COUNT - 1))
    fi
elif [ -n "$CHOICE" ]; then
    # Switch to the selected window
    wmctrl -a "$CHOICE"
fi
