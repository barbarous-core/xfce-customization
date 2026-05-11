#!/bin/bash

# Configuration
STATE_FILE="/tmp/volume_toggle_state"

# Nerd Font icons via printf
ICON_HIGH=$(printf '\U000f057e')
ICON_LOW=$(printf '\U000f0580')
ICON_MUTED=$(printf '\U000f075f')
ICON_OFF=$(printf '\U000f0581')

# Toggle logic
if [ "$1" == "--toggle" ]; then
    if [ ! -f "$STATE_FILE" ] || [ "$(cat "$STATE_FILE")" == "icon" ]; then
        echo "full" > "$STATE_FILE"
    else
        echo "icon" > "$STATE_FILE"
    fi
    exit 0
fi

# Volume up/down
if [ "$1" == "--up" ]; then
    pactl set-sink-volume @DEFAULT_SINK@ +5%
    exit 0
elif [ "$1" == "--down" ]; then
    pactl set-sink-volume @DEFAULT_SINK@ -5%
    exit 0
elif [ "$1" == "--mute" ]; then
    pactl set-sink-mute @DEFAULT_SINK@ toggle
    exit 0
fi

# Initial state
[ ! -f "$STATE_FILE" ] && echo "icon" > "$STATE_FILE"
# Global State
GLOBAL_STATE_FILE="/tmp/polybar_active_module"
active_module=$(cat "$GLOBAL_STATE_FILE" 2>/dev/null || echo "none")
STATE="icon"
if [ "$active_module" == "media" ]; then
    STATE="full"
fi

# Get volume info
VOL=$(pactl get-sink-volume @DEFAULT_SINK@ 2>/dev/null | grep -oP '\d+%' | head -1 | tr -d '%')
MUTED=$(pactl get-sink-mute @DEFAULT_SINK@ 2>/dev/null | grep -oP 'yes|no')

if [ "$MUTED" == "yes" ]; then
    ICON="%{F#A54242}%{T4}${ICON_MUTED}%{T-}%{F-}"
    TEXT=" muted"
else
    if [ "$VOL" -le 50 ]; then
        ICON="%{F#F0C674}%{T4}${ICON_LOW}%{T-}%{F-}"
    else
        ICON="%{F#F0C674}%{T4}${ICON_HIGH}%{T-}%{F-}"
    fi
    TEXT=" ${VOL}%"
fi

if [ "$STATE" == "full" ]; then
    echo "$ICON$TEXT"
else
    echo "$ICON"
fi
