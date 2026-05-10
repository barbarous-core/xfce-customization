#!/bin/bash

# Prevent multiple instances or double-triggers
LOCKFILE="/tmp/open_kb_settings.lock"
if [ -e "$LOCKFILE" ]; then
    WID=$(wmctrl -l | grep "Keyboard" | awk '{print $1}' | tail -n1)
    [ -n "$WID" ] && wmctrl -i -a $WID
    exit 0
fi

touch "$LOCKFILE"
trap 'rm -f "$LOCKFILE"' EXIT

# Start the settings window
xfce4-keyboard-settings &

# Wait and reposition multiple times to fight window managers that reposition on map
for i in {1..30}; do
    WID=$(wmctrl -l | grep "Keyboard" | awk '{print $1}' | tail -n1)
    
    if [ -n "$WID" ]; then
        # Get screen width
        SCREEN_WIDTH=$(xwininfo -root | grep "Width:" | awk '{print $2}')
        [ -z "$SCREEN_WIDTH" ] && SCREEN_WIDTH=1920
        
        # Get window width
        WIN_WIDTH=$(xwininfo -id $WID | grep "Width:" | awk '{print $2}')
        [ -z "$WIN_WIDTH" ] && WIN_WIDTH=650
        
        # Calculate X position. 
        # We want it roughly under the keyboard module. 
        # Keyboard module is in modules-right, which starts roughly at 2/3 of the bar.
        # Let's try placing it at 75% of screen width minus half window width.
        X_POS=$(( (SCREEN_WIDTH * 80 / 100) - (WIN_WIDTH / 2) ))
        
        # Ensure it doesn't go off screen
        [ $((X_POS + WIN_WIDTH)) -gt $SCREEN_WIDTH ] && X_POS=$((SCREEN_WIDTH - WIN_WIDTH - 20))
        [ $X_POS -lt 0 ] && X_POS=20
        
        Y_POS=50
        
        # Force move and resize (0 means default gravity)
        wmctrl -i -r $WID -e 0,$X_POS,$Y_POS,-1,-1
        wmctrl -i -a $WID
        
        # If we found it and moved it, we keep checking for a bit to ensure it sticks
        sleep 0.1
    else
        sleep 0.2
    fi
done

sleep 1
rm -f "$LOCKFILE"
