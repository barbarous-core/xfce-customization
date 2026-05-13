#!/bin/bash

# Initial count of connected monitors
LAST_COUNT=$(xrandr --query | grep " connected" | wc -l)

while true; do
    sleep 5
    CURRENT_COUNT=$(xrandr --query | grep " connected" | wc -l)
    
    if [ "$CURRENT_COUNT" -ne "$LAST_COUNT" ]; then
        # Detect if it was a removal or a connection
        if [ "$CURRENT_COUNT" -lt "$LAST_COUNT" ]; then
            # REMOVAL: Automatically adjust to remaining screens
            echo "[$(date)] Monitor Removed. Auto-reloading..." >> /tmp/monitor_watcher.log
            notify-send "Monitor Removed" "Adjusting Polybar layout..."
            bash "$HOME/.config/polybar/launch.sh" --last
        else
            # CONNECTION: Show the reload dialog to allow manual configuration
            echo "[$(date)] Monitor Connected. Opening reload menu..." >> /tmp/monitor_watcher.log
            notify-send "Monitor Connected" "New screen detected. Open reload menu?"
            export DISPLAY=:0
            bash "$HOME/.config/polybar/scripts/reload_polybar.sh"
        fi
        
        # Exit this instance as a new one will be started by the reload process
        exit 0
    fi
done
