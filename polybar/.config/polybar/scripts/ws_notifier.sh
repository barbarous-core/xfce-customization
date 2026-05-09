#!/bin/bash

# Log file for debugging
LOG="/tmp/ws_notifier.log"
echo "Notifier started at $(date)" > "$LOG"

# Keep track of the last seen workspace
LAST_WS=$(xprop -root _NET_CURRENT_DESKTOP | awk '{print $3}')

# Simplified Rofi theme for better compatibility
THEME="window { width: 33%; height: 33%; border: 4px; border-color: #61afef; border-radius: 20px; background-color: #282a2e; } 
       textbox { font: \"JetBrainsMono Nerd Font 48\"; text-color: #c5c8c6; horizontal-align: 0.5; vertical-align: 0.5; }"

while true; do
    # Get current workspace
    CURRENT_WS=$(xprop -root _NET_CURRENT_DESKTOP | awk '{print $3}')
    
    # If it changed, show OSD
    if [ "$CURRENT_WS" != "$LAST_WS" ]; then
        echo "Workspace changed from $LAST_WS to $CURRENT_WS" >> "$LOG"
        
        # Get the name using a simpler method
        WS_NAME=$(wmctrl -d | grep "^$CURRENT_WS " | sed 's/.*  //')
        
        # If name is default or empty, use "Workspace N"
        if [[ "$WS_NAME" == "Workspace "* || -z "$WS_NAME" ]]; then
            WS_NAME="Workspace $((CURRENT_WS + 1))"
        fi
        
        echo "Displaying OSD for: $WS_NAME" >> "$LOG"
        
        # Kill any existing OSDs first
        pkill -f "rofi -name WS_OSD" 2>/dev/null
        
        # Launch Rofi OSD and capture its PID
        rofi -e "$WS_NAME" -name "WS_OSD" -theme-str "$THEME" &
        ROFI_PID=$!
        
        # Start a background timer to kill THIS specific PID after 2 seconds
        (sleep 2 && kill $ROFI_PID 2>/dev/null) &
        
        LAST_WS=$CURRENT_WS
    fi
    
    sleep 0.2
done
