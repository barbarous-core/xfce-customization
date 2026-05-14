#!/bin/bash

MINI_STATE="/tmp/polybar_minimal_state"
POS_FILE="/tmp/polybar_mini_pos"
LAST_CONF="/home/mohamed/Linux_Data/Git_Projects/xfce-customization/polybar/.config/polybar/.last_launch"

ACTION="$1"

if [ -f "$MINI_STATE" ]; then
    # --- MINI MODE ---
    if [ ! -f "$POS_FILE" ]; then
        echo "bottom|right" > "$POS_FILE"
    fi
    
    CURRENT=$(cat "$POS_FILE")
    VALIGN=$(echo "$CURRENT" | cut -d'|' -f1)
    HALIGN=$(echo "$CURRENT" | cut -d'|' -f2)
    
    case "$ACTION" in
        up)    VALIGN="top" ;;
        down)  VALIGN="bottom" ;;
        left)  HALIGN="left" ;;
        right) HALIGN="right" ;;
    esac
    
    echo "$VALIGN|$HALIGN" > "$POS_FILE"
else
    # --- MAX MODE ---
    if [ -f "$LAST_CONF" ]; then
        if [ "$ACTION" == "up" ]; then
            sed -i "s/^POS_H=.*/POS_H=\"false\"/" "$LAST_CONF"
            sed -i "s/^POS_E=.*/POS_E=\"false\"/" "$LAST_CONF"
        elif [ "$ACTION" == "down" ]; then
            sed -i "s/^POS_H=.*/POS_H=\"true\"/" "$LAST_CONF"
            sed -i "s/^POS_E=.*/POS_E=\"true\"/" "$LAST_CONF"
        fi
    fi
fi

# Re-run launch script with --last
# This will pick up the new position state.
bash "/home/mohamed/Linux_Data/Git_Projects/xfce-customization/polybar/.config/polybar/launch.sh" --last
