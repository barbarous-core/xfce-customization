#!/bin/bash

# Log file for debugging
LOG="/tmp/ws_notifier.log"

# Prevent multiple instances
if pgrep -f "$(basename "$0")" | grep -v $$ > /dev/null; then
    exit 0
fi

echo "Notifier started at $(date)" > "$LOG"

# Keep track of the last seen workspace
LAST_WS=$(xprop -root _NET_CURRENT_DESKTOP | awk '{print $3}')

# Simplified Rofi theme for better compatibility
THEME="window { width: 33%; height: 33%; border: 4px; border-color: #61afef; border-radius: 20px; background-color: #282a2e; } 
       textbox { font: \"JetBrainsMono Nerd Font 48\"; text-color: #c5c8c6; horizontal-align: 0.5; vertical-align: 0.5; }"

while true; do
    # Get current workspace index
    CURRENT_WS=$(xprop -root _NET_CURRENT_DESKTOP | awk '{print $3}')
    
    # If it changed, show OSD
    if [ "$CURRENT_WS" != "$LAST_WS" ]; then
        echo "Workspace changed from $LAST_WS to $CURRENT_WS" >> "$LOG"
        
        # Get the name using wmctrl but with a robust extraction method
        # We look for the line starting with our index and grab everything after the workarea geometry
        WS_NAME=$(wmctrl -d | grep "^$CURRENT_WS " | sed 's/.*WA: [0-9,]* [0-9x]*  //')
        
        # Trim whitespace
        WS_NAME=$(echo "$WS_NAME" | sed 's/^[ \t]*//;s/[ \t]*$//')

        # FINAL PROTECTION: If name contains "Value is an array" or is empty or default, use number
        if [[ "$WS_NAME" == "Value is an array"* || "$WS_NAME" == "Workspace "* || -z "$WS_NAME" ]]; then
            WS_NAME="$((CURRENT_WS + 1))"
        fi
        
        echo "Displaying OSD for: $WS_NAME" >> "$LOG"
        
        # Kill any existing OSDs first
        pkill -f "rofi -name WS_OSD" 2>/dev/null
        
        # Launch Rofi OSD with a strict 0.6-second timeout and a private PID file
        timeout 0.5s rofi -e "$WS_NAME" -name "WS_OSD" -pid /tmp/rofi_osd.pid -theme-str "$THEME" &
        
        LAST_WS=$CURRENT_WS
    fi
    
    sleep 0.2
done
