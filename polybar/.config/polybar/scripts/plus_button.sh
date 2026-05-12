#!/bin/bash

# Configuration
COLORS_FILE="$HOME/.config/polybar/colors.ini"

# Get colors from colors.ini
PRIMARY_COLOR=$(grep "primary =" "$COLORS_FILE" | cut -d' ' -f3)
DISABLED_COLOR=$(grep "disabled =" "$COLORS_FILE" | cut -d' ' -f3)

# Get current workspace count
WS_COUNT=$(xfconf-query -c xfwm4 -p /general/workspace_count)

# Only show "Add" if we have fewer than 10 workspaces
if [ "$WS_COUNT" -lt 10 ]; then
    echo "%{F$PRIMARY_COLOR}󰐕%{F-}"
else
    echo "%{F$DISABLED_COLOR}󰐕%{F-}"
fi
