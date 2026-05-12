#!/bin/bash

# 1. Detect mouse location and the window under the cursor
eval "$(xdotool getmouselocation --shell)"
M_X=$X
M_Y=$Y

# 2. Get the monitor name and its local coordinates
# We need to know where the monitor starts so we can calculate relative positions
MONITOR_INFO=$(xrandr --query | grep " connected" | while read -r line; do
    NAME=$(echo "$line" | cut -d' ' -f1)
    GEOM=$(echo "$line" | grep -oE '[0-9]+x[0-9]+\+[0-9]+\+[0-9]+')
    W=$(echo "$GEOM" | cut -d'x' -f1)
    H=$(echo "$GEOM" | cut -d'x' -f2 | cut -d'+' -f1)
    OFF_X=$(echo "$GEOM" | cut -d'+' -f2)
    OFF_Y=$(echo "$GEOM" | cut -d'+' -f3)
    
    if [ "$M_X" -ge "$OFF_X" ] && [ "$M_X" -le "$((OFF_X + W))" ] && \
       [ "$M_Y" -ge "$OFF_Y" ] && [ "$M_Y" -le "$((OFF_Y + H))" ]; then
        echo "$NAME|$OFF_X|$OFF_Y|$H"
        break
    fi
done)

IFS='|' read -r MON_NAME MON_OFF_X MON_OFF_Y MON_HEIGHT <<< "$MONITOR_INFO"

# 3. Find Polybar geometry
if ! xwininfo -id "$WINDOW" 2>/dev/null | grep -q -i "polybar"; then
    BAR_WIN=$(xdotool search --class "polybar")
    for WIN in $BAR_WIN; do
        eval "$(xdotool getwindowgeometry --shell "$WIN")"
        if [ "$M_X" -ge "$X" ] && [ "$M_X" -le "$((X + WIDTH))" ] && \
           [ "$M_Y" -ge "$Y" ] && [ "$M_Y" -le "$((Y + HEIGHT))" ]; then
            WINDOW=$WIN
            break
        fi
    done
fi

eval "$(xdotool getwindowgeometry --shell "$WINDOW")"
BAR_Y=$Y
BAR_HEIGHT=$HEIGHT

if [ -z "$BAR_HEIGHT" ]; then BAR_HEIGHT=32; BAR_Y=$MON_OFF_Y; fi

# 4. Calculate relative coordinates
# Since we are setting 'monitor' in jgmenu, X and Y must be RELATIVE to that monitor.
GAP=8
NEW_X=5 # 5px from the left edge of the active monitor
NEW_Y=$((BAR_HEIGHT + GAP))

# Determine if top or bottom relative to monitor
MON_LOCAL_Y=$((BAR_Y - MON_OFF_Y))

if [ "$MON_LOCAL_Y" -lt 100 ]; then
    ALIGN_V="top"
else
    ALIGN_V="bottom"
fi

# 5. Update jgmenurc
CONFIG="$HOME/.config/jgmenu/jgmenurc"
sed -i --follow-symlinks "s/^menu_margin_x = .*/menu_margin_x = $NEW_X/" "$CONFIG"
sed -i --follow-symlinks "s/^menu_margin_y = .*/menu_margin_y = $NEW_Y/" "$CONFIG"
sed -i --follow-symlinks "s/^menu_valign = .*/menu_valign = $ALIGN_V/" "$CONFIG"
sed -i --follow-symlinks "s/^#\?\s\?monitor = .*/monitor = $MON_NAME/" "$CONFIG"

# 6. Show the menu
pkill -x jgmenu
jgmenu
