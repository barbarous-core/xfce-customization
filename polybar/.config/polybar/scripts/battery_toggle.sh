#!/bin/bash

# Check if it's already running
if pgrep -x "xfce4-power-manager-settings" > /dev/null; then
    # If running, kill it
    killall xfce4-power-manager-settings
else
    # Launch it in the background
    xfce4-power-manager-settings &
    
    # Wait for the window to appear
    win_id=""
    for i in {1..20}; do
        win_id=$(wmctrl -l | awk '/Power Manager/ {print $1}')
        if [ -n "$win_id" ]; then
            break
        fi
        sleep 0.1
    done
    
    if [ -n "$win_id" ]; then
        # Remove decorations
        xprop -id "$win_id" -f _MOTIF_WM_HINTS 32c -set _MOTIF_WM_HINTS "2, 0, 0, 0, 0"
        
        # Get screen width
        screen_width=$(cat /sys/class/drm/card*-*/modes | head -n 1 | cut -d 'x' -f 1)
        if [ -z "$screen_width" ]; then
            screen_width=1920
        fi
        
        # Move window
        # Target X coordinate. The window is usually ~600px wide. Position it on the right under polybar.
        target_x=$(( screen_width - 650 ))
        target_y=40
        
        wmctrl -i -r "$win_id" -e 0,$target_x,$target_y,-1,-1
    fi
fi
