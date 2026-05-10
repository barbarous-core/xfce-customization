#!/bin/bash

# Function to get microphone status
get_mic_status() {
    pactl get-source-mute @DEFAULT_SOURCE@ | awk '{print $2}'
}

case "$1" in
    --toggle)
        pactl set-source-mute @DEFAULT_SOURCE@ toggle
        ;;
    *)
        status=$(get_mic_status)
        if [ "$status" = "yes" ]; then
            # Muted icon (Red)
            echo "%{F#A54242}%{T4}%{T-}%{F-}"
        else
            # Unmuted icon (Primary theme color)
            echo "%{F#F0C674}%{T4}%{T-}%{F-}"
        fi
        ;;
esac
