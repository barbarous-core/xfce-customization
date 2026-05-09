#!/bin/bash

# Configuration
MAX_WORKSPACES=18
LOG="/tmp/add_workspace.log"
echo "Add script started at $(date)" > "$LOG"

# 1. Calculate actual number of current workspaces
CURRENT_COUNT=$(xfconf-query -c xfwm4 -p /general/workspace_count)

# If we reached exactly 10, show the productivity warning
if [ "$CURRENT_COUNT" -eq 10 ]; then
    zenity --warning --text "You reach productivity workspaces limitation but u can add up to 18 workspaces" --title "Productivity Limitation" --width 300
fi

# If we reached the final limit, stop
if [ "$CURRENT_COUNT" -ge "$MAX_WORKSPACES" ]; then
    notify-send -u critical "Workspace Limit" "Cannot add more: Reached the limit ($MAX_WORKSPACES)!"
    exit 0
fi

# 2. Prepare the Categories with "Used" detection
CATEGORIES=("🌐 Web" " Code" " Terminal" " Chat" "🎨 Design" "🎬 Video" " Office" " PKM")
mapfile -t EXISTING_NAMES < <(xfconf-query -c xfwm4 -p /general/workspace_names -v 2>/dev/null | grep -v "Value is an array" | sed 's/^[ \t]*//' | grep -v "^$")

OPTIONS=""
for cat in "${CATEGORIES[@]}"; do
    FOUND=false
    for exist in "${EXISTING_NAMES[@]}"; do
        if [ "$exist" == "$cat" ]; then
            FOUND=true
            break
        fi
    done
    
    if [ "$FOUND" = true ]; then
        # Add a greyed out version with [USED] tag
        OPTIONS+="${cat} <span color='#707880' size='small'>(Used)</span>\n"
    else
        OPTIONS+="${cat}\n"
    fi
done

# 3. Select name and check for duplicates
while true; do
    rm -f /tmp/rofi_add.pid
    
    # Launch Rofi with Pango markup support
    WS_NAME=$(echo -e "$OPTIONS" | rofi -dmenu -markup-rows -p "Select Category or Type Name:" -location 0 -width 40 -monitor -1 -pid /tmp/rofi_add.pid)

    # If cancelled, exit
    if [ $? -ne 0 ]; then
        exit 0
    fi

    # Strip the (Used) tag if the user clicked a used one
    WS_NAME=$(echo "$WS_NAME" | sed 's/ <span.*//')

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
    else
        break
    fi
done

# 4. Final count calculation (Original + 1)
NEW_COUNT=$((CURRENT_COUNT + 1))
xfconf-query -c xfwm4 -p /general/workspace_count -s "$NEW_COUNT"

# Update the names array in XFCE
xfconf-query -c xfwm4 -p /general/workspace_names -r
CMD="xfconf-query -c xfwm4 -p /general/workspace_names -n"
for name in "${EXISTING_NAMES[@]}"; do
    CMD="$CMD -t string -s \"$name\""
done
CMD="$CMD -t string -s \"$WS_NAME\""

eval "$CMD"
echo "Successfully added: $WS_NAME. New total: $NEW_COUNT" >> "$LOG"
