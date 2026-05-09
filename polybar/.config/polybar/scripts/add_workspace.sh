#!/bin/bash

# Configuration
MAX_WORKSPACES=18

# Get current count
CURRENT_COUNT=$(xfconf-query -c xfwm4 -p /general/workspace_count)

# If we reached the limit, stop
if [ "$CURRENT_COUNT" -ge "$MAX_WORKSPACES" ]; then
    notify-send -u critical "Workspace Limit" "Cannot add more: Reached the limit ($MAX_WORKSPACES) to keep the date centered!"
    exit 0
fi

# Ask for the name
WS_NAME=$(rofi -dmenu -p "New Workspace Name:" -location 0 -width 30)
if [ $? -ne 0 ]; then exit 0; fi

# Increment count
NEW_COUNT=$((CURRENT_COUNT + 1))
xfconf-query -c xfwm4 -p /general/workspace_count -s "$NEW_COUNT"

# If no name provided, use default
if [ -z "$WS_NAME" ]; then
    WS_NAME="Workspace $NEW_COUNT"
fi

# Get existing names and filter out technical jargon
mapfile -t NAMES < <(xfconf-query -c xfwm4 -p /general/workspace_names -v | grep -v "Value is an array" | sed 's/^[ \t]*//' | grep -v "^$")

# Reset the property first to ensure a clean array
xfconf-query -c xfwm4 -p /general/workspace_names -r

# Build the command to update the whole array
CMD="xfconf-query -c xfwm4 -p /general/workspace_names -n"
for name in "${NAMES[@]}"; do
    CMD="$CMD -t string -s \"$name\""
done
# Add the new name
CMD="$CMD -t string -s \"$WS_NAME\""

# Execute the command
eval "$CMD"
