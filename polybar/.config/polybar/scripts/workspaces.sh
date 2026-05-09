#!/bin/bash

# Configuration
BAR_START=20
WHISKER_WIDTH=70
WS_WIDTH=32
Y_OFFSET=36

# Get workspaces from xfconf (XFCE)
# Get total workspace count
WS_COUNT=$(xfconf-query -c xfwm4 -p /general/workspace_count)

# Get current workspace index using xprop (0-based)
CURRENT_WS=$(xprop -root _NET_CURRENT_DESKTOP | awk '{print $3}')

# Fallback to wmctrl if xprop fails
if [ -z "$CURRENT_WS" ]; then
    CURRENT_WS=$(wmctrl -d | grep '*' | cut -d' ' -f1)
fi

output=""

for i in $(seq 1 $WS_COUNT); do
    INDEX=$((i-1))
    X_POS=$((BAR_START + WHISKER_WIDTH + (INDEX * WS_WIDTH)))
    
    # Action tags: Left click to switch, Middle click for Rofi at X_POS
    ACTION_START="%{A1:wmctrl -s $INDEX:}%{A2:rofi -show window -location 1 -xoffset $X_POS -yoffset $Y_OFFSET:}"
    ACTION_END="%{A}%{A}"
    
    if [ "$INDEX" -eq "$CURRENT_WS" ]; then
        # Active workspace styling: Blue foreground and Blue underline
        output+="${ACTION_START}%{F#61afef}%{u#61afef}%{+u} $i %{-u}%{F-}${ACTION_END}"
    else
        # Inactive workspace styling
        output+="${ACTION_START} $i ${ACTION_END}"
    fi
done

echo "$output"
