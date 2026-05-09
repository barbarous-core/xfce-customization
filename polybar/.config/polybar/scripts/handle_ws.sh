#!/bin/bash

INDEX=$1
X_POS=$2
Y_OFFSET=$3

# Get the list of windows on this workspace
WINDOWS=$(wmctrl -l | awk -v ws=$INDEX '$2 == ws {print $0}' | cut -d' ' -f5-)

# Define options with Pango markup
DELETE_OPTION="<span color='#ff5555'><b>[DELETE THIS WORKSPACE]</b></span>"
RENAME_OPTION="<span color='#98c379'><b>[RENAME THIS WORKSPACE]</b></span>"

# Show Rofi menu
CHOICE=$(echo -e "$RENAME_OPTION\n$DELETE_OPTION\n$WINDOWS" | rofi -dmenu -markup-rows -p "WS $((INDEX+1))" -location 1 -xoffset "$X_POS" -yoffset "$Y_OFFSET")

if [ "$CHOICE" = "$RENAME_OPTION" ]; then
    # Ask for the new name
    NEW_NAME=$(rofi -dmenu -p "New Name for WS $((INDEX+1)):" -location 1 -xoffset "$X_POS" -yoffset "$Y_OFFSET" -pid /tmp/rofi_rename.pid)
    
    if [ -n "$NEW_NAME" ]; then
        # Get existing names and filter out technical jargon
        mapfile -t NAMES < <(xfconf-query -c xfwm4 -p /general/workspace_names -v 2>/dev/null | grep -v "Value is an array" | sed 's/^[ \t]*//' | grep -v "^$")
        
        # Update the name at the specific index
        NAMES[$INDEX]="$NEW_NAME"
        
        # Reset the property first to ensure a clean array
        xfconf-query -c xfwm4 -p /general/workspace_names -r
        
        # Build the xfconf-query command to update the whole array
        CMD="xfconf-query -c xfwm4 -p /general/workspace_names -n"
        for name in "${NAMES[@]}"; do
            CMD="$CMD -t string -s \"$name\""
        done
        eval "$CMD"
    fi

elif [ "$CHOICE" = "$DELETE_OPTION" ]; then
    # Confirmation dialog
    if zenity --question --text "Are you sure you want to delete workspace $((INDEX+1))?" --title "Delete Workspace"; then
        WS_COUNT=$(xfconf-query -c xfwm4 -p /general/workspace_count)
        
        # 1. Get existing names
        mapfile -t NAMES < <(xfconf-query -c xfwm4 -p /general/workspace_names -v 2>/dev/null | grep -v "Value is an array" | sed 's/^[ \t]*//' | grep -v "^$")
        
        # 2. Reduce the count
        NEW_COUNT=$((WS_COUNT - 1))
        xfconf-query -c xfwm4 -p /general/workspace_count -s "$NEW_COUNT"

        # 3. Update the names array (truncate)
        xfconf-query -c xfwm4 -p /general/workspace_names -r
        CMD="xfconf-query -c xfwm4 -p /general/workspace_names -n"
        for (( i=0; i<$NEW_COUNT; i++ )); do
            CMD="$CMD -t string -s \"${NAMES[$i]}\""
        done
        eval "$CMD"
    fi

elif [ -n "$CHOICE" ]; then
    # Switch to the selected window
    wmctrl -a "$CHOICE"
fi
