#!/bin/bash

STATE_FILE="/tmp/polybar_minimal_state"

if [ -f "$STATE_FILE" ]; then
    rm "$STATE_FILE"
    
    # Sync max bar's vertical position with mini bar
    LAST_CONF="/home/mohamed/Linux_Data/Git_Projects/xfce-customization/polybar/.config/polybar/.last_launch"
    POS_FILE="/tmp/polybar_mini_pos"
    
    if [ -f "$POS_FILE" ] && [ -f "$LAST_CONF" ]; then
        VALIGN=$(cat "$POS_FILE" | cut -d'|' -f1)
        NEW_POS="false"
        [ "$VALIGN" == "bottom" ] && NEW_POS="true"
        
        sed -i "s/^POS_H=.*/POS_H=\"$NEW_POS\"/" "$LAST_CONF"
        sed -i "s/^POS_E=.*/POS_E=\"$NEW_POS\"/" "$LAST_CONF"
    fi
else
    touch "$STATE_FILE"
    
    # Sync mini bar's vertical position with max bar
    LAST_CONF="/home/mohamed/Linux_Data/Git_Projects/xfce-customization/polybar/.config/polybar/.last_launch"
    POS_FILE="/tmp/polybar_mini_pos"
    
    if [ -f "$LAST_CONF" ]; then
        source "$LAST_CONF"
        CURRENT_POS="${POS_E:-$POS_H}"
        
        VALIGN="top"
        if [ "$CURRENT_POS" == "true" ]; then
            VALIGN="bottom"
        fi
        
        # Always spawn mini bar on the right side
        HALIGN="right"
        
        echo "$VALIGN|$HALIGN" > "$POS_FILE"
    fi
fi

# Reload Polybar with the current config
# Since launch.sh now checks for the state file, it will toggle the modules.
bash /home/mohamed/Linux_Data/Git_Projects/xfce-customization/polybar/.config/polybar/launch.sh --last
