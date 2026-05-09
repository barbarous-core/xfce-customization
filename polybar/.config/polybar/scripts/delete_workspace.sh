#!/bin/bash

# Get current workspace count
WS_COUNT=$(xfconf-query -c xfwm4 -p /general/workspace_count)

# Don't delete if only 1 workspace remains
if [ "$WS_COUNT" -le 1 ]; then
    notify-send "Workspace Management" "Cannot delete: You must have at least one workspace!"
    exit 0
fi

# Confirmation dialog
if zenity --question --text "Are you sure you want to delete the last workspace (Workspace $WS_COUNT)?" --title "Delete Workspace"; then
    # Reduce count
    xfconf-query -c xfwm4 -p /general/workspace_count -s $((WS_COUNT - 1))
    notify-send "Workspace Management" "Workspace $WS_COUNT removed."
fi
