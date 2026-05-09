#!/bin/bash

# Get current workspace info
WS_COUNT=$(xfconf-query -c xfwm4 -p /general/workspace_count)
CURRENT_WS_INDEX=$(xprop -root _NET_CURRENT_DESKTOP | awk '{print $3}')
WS_NUM=$((CURRENT_WS_INDEX + 1))

# Don't delete if only 1 workspace remains
if [ "$WS_COUNT" -le 1 ]; then
    notify-send "Workspace Management" "Cannot delete: You must have at least one workspace!"
    exit 0
fi

# Get the name of the current workspace
mapfile -t NAMES < <(xfconf-query -c xfwm4 -p /general/workspace_names -v 2>/dev/null | grep -v "Value is an array" | sed 's/^[ \t]*//' | grep -v "^$")
CURRENT_NAME="${NAMES[$CURRENT_WS_INDEX]}"

# Confirmation dialog
if zenity --question --text "Are you sure you want to delete your ACTIVE workspace $WS_NUM: '$CURRENT_NAME'?" --title "Delete Active Workspace"; then
    # 1. Create a new names array without the current index
    NEW_NAMES=()
    for i in "${!NAMES[@]}"; do
        if [ "$i" -ne "$CURRENT_WS_INDEX" ]; then
            NEW_NAMES+=("${NAMES[$i]}")
        fi
    done

    # 2. Reduce the count
    NEW_COUNT=$((WS_COUNT - 1))
    xfconf-query -c xfwm4 -p /general/workspace_count -s "$NEW_COUNT"

    # 3. Update the names array with the shifted items
    xfconf-query -c xfwm4 -p /general/workspace_names -r
    CMD="xfconf-query -c xfwm4 -p /general/workspace_names -n"
    for name in "${NEW_NAMES[@]}"; do
        CMD="$CMD -t string -s \"$name\""
    done
    eval "$CMD"

    notify-send "Workspace Management" "Workspace '$CURRENT_NAME' deleted. Total is now $NEW_COUNT."
fi
