#!/bin/bash

# Get current workspace count and names
WS_COUNT=$(xfconf-query -c xfwm4 -p /general/workspace_count)

# Don't delete if only 1 workspace remains
if [ "$WS_COUNT" -le 1 ]; then
    notify-send "Workspace Management" "Cannot delete: You must have at least one workspace!"
    exit 0
fi

# Confirmation dialog
if zenity --question --text "Are you sure you want to delete the last workspace (Workspace $WS_COUNT)?" --title "Delete Workspace"; then
    # 1. Get existing names and remove the last one
    mapfile -t NAMES < <(xfconf-query -c xfwm4 -p /general/workspace_names -v 2>/dev/null | grep -v "Value is an array" | sed 's/^[ \t]*//' | grep -v "^$")
    
    # 2. Reduce the count
    NEW_COUNT=$((WS_COUNT - 1))
    xfconf-query -c xfwm4 -p /general/workspace_count -s "$NEW_COUNT"

    # 3. Update the names array (remove the last item)
    xfconf-query -c xfwm4 -p /general/workspace_names -r
    CMD="xfconf-query -c xfwm4 -p /general/workspace_names -n"
    # Only add back up to the NEW_COUNT items
    for (( i=0; i<$NEW_COUNT; i++ )); do
        CMD="$CMD -t string -s \"${NAMES[$i]}\""
    done
    eval "$CMD"

    notify-send "Workspace Management" "Workspace removed. Total is now $NEW_COUNT."
fi
