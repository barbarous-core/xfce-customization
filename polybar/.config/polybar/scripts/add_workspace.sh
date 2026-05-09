#!/bin/bash

# Configuration
MAX_WORKSPACES=18
LOG="/tmp/add_workspace.log"
echo "Add script started at $(date)" > "$LOG"

# 1. Calculate actual number of current workspaces
CURRENT_COUNT=$(xfconf-query -c xfwm4 -p /general/workspace_count)
echo "Starting count: $CURRENT_COUNT" >> "$LOG"

# If we reached the limit, stop
if [ "$CURRENT_COUNT" -ge "$MAX_WORKSPACES" ]; then
    notify-send -u critical "Workspace Limit" "Cannot add more: Reached the limit ($MAX_WORKSPACES)!"
    exit 0
fi

# Get existing names early for duplicate checking
mapfile -t EXISTING_NAMES < <(xfconf-query -c xfwm4 -p /general/workspace_names -v 2>/dev/null | grep -v "Value is an array" | sed 's/^[ \t]*//' | grep -v "^$")

# Define Categories
OPTIONS="🌐 Web\n Code\n Term\n Chat\n Media\n⚙️ System"

# 2. Select name and check for duplicates
while true; do
    # Clean up Rofi PID
    rm -f /tmp/rofi_add.pid
    
    # Launch Rofi
    WS_NAME=$(echo -e "$OPTIONS" | rofi -dmenu -p "Enter UNIQUE Name:" -location 0 -width 40 -monitor -1 -pid /tmp/rofi_add.pid)

    # If cancelled, exit
    if [ $? -ne 0 ]; then
        exit 0
    fi

    # If empty, use index as name
    if [ -z "$WS_NAME" ]; then
        WS_NAME="$((CURRENT_COUNT + 1))"
    fi

    # Check if name already exists
    DUPLICATE=false
    for name in "${EXISTING_NAMES[@]}"; do
        if [ "$name" == "$WS_NAME" ]; then
            DUPLICATE=true
            break
        fi
    done

    if [ "$DUPLICATE" = true ]; then
        notify-send -u normal "Duplicate Name" "Workspace '$WS_NAME' already exists. Please choose another name."
        # Loop continues to show Rofi again
    else
        # Success! Unique name found
        break
    fi
done

# 3. Final count calculation (Original + 1)
NEW_COUNT=$((CURRENT_COUNT + 1))
xfconf-query -c xfwm4 -p /general/workspace_count -s "$NEW_COUNT"

# Update the names array in XFCE
xfconf-query -c xfwm4 -p /general/workspace_names -r
CMD="xfconf-query -c xfwm4 -p /general/workspace_names -n"
for name in "${EXISTING_NAMES[@]}"; do
    CMD="$CMD -t string -s \"$name\""
done
# Add the new unique name
CMD="$CMD -t string -s \"$WS_NAME\""

eval "$CMD"
echo "Successfully added: $WS_NAME. New total: $NEW_COUNT" >> "$LOG"
