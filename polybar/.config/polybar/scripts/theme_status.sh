#!/bin/bash

# Configuration
GLOBAL_STATE_FILE="/tmp/polybar_active_module"
THEME_STATE_FILE="/tmp/polybar_active_theme"

# Default theme name if none set
[ ! -f "$THEME_STATE_FILE" ] && echo "Default" > "$THEME_STATE_FILE"

# Icons
ICON_THEME="󰏘"
# Fetch primary color from polybar colors.ini
PRIMARY_COLOR=$(grep "^primary =" "$HOME/.config/polybar/colors.ini" | cut -d' ' -f3 || echo "#F0C674")
COLOR_THEME="%{F$PRIMARY_COLOR}"
COLOR_RESET="%{F-}"

while true; do
    ACTIVE_MODULE=$(cat "$GLOBAL_STATE_FILE" 2>/dev/null || echo "none")
    CURRENT_THEME=$(cat "$THEME_STATE_FILE" 2>/dev/null || echo "Default")

    THEME_ICON="%{T4}${COLOR_THEME}${ICON_THEME}${COLOR_RESET}%{T-}"

    if [ "$ACTIVE_MODULE" == "themes" ]; then
        # Expanded View
        echo "${THEME_ICON} ${CURRENT_THEME}"
    else
        # Collapsed View
        echo "${THEME_ICON}"
    fi

    sleep 2
done
