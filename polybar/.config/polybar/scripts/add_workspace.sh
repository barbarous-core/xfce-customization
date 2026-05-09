#!/bin/bash

# Configuration
# The user observed that at 19 workspaces, the centered date starts moving.
# We set the limit to 18 to keep the date perfectly centered.
MAX_WORKSPACES=18

# Get current count
CURRENT_COUNT=$(xfconf-query -c xfwm4 -p /general/workspace_count)

# If we reached the limit, stop
if [ "$CURRENT_COUNT" -ge "$MAX_WORKSPACES" ]; then
    notify-send -u critical "Workspace Limit" "Cannot add more: Reached the limit ($MAX_WORKSPACES) to keep the date centered!"
    exit 0
fi

# --- Proceed with adding workspace ---

# Ask for the name
WS_NAME=$(rofi -dmenu -p "New Workspace Name (Max $MAX_WORKSPACES):" -location 0 -width 30)
if [ $? -ne 0 ]; then exit 0; fi

# Increment count
NEW_COUNT=$((CURRENT_COUNT + 1))
xfconf-query -c xfwm4 -p /general/workspace_count -s "$NEW_COUNT"

# If no name provided, use default
if [ -z "$WS_NAME" ]; then
    WS_NAME="Workspace $NEW_COUNT"
fi

# Update names array
NAMES_FILE=$(mktemp)
xfconf-query -c xfwm4 -p /general/workspace_names -v > "$NAMES_FILE"
CMD="xfconf-query -c xfwm4 -p /general/workspace_names -n"
while read -r name; do
    CMD="$CMD -t string -s \"$name\""
done < "$NAMES_FILE"
CMD="$CMD -t string -s \"$WS_NAME\""
eval "$CMD"
rm "$NAMES_FILE"
