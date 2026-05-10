#!/usr/bin/env bash

# Configuration
SOUND_LOW="/usr/share/sounds/freedesktop/stereo/window-attention.oga"
SOUND_PLUG="/usr/share/sounds/freedesktop/stereo/power-plug.oga"
SOUND_UNPLUG="/usr/share/sounds/freedesktop/stereo/power-unplug.oga"
SOUND_FULL="/usr/share/sounds/freedesktop/stereo/complete.oga"
BATTERY="/sys/class/power_supply/BAT0"
LAST_PLAY=0
LAST_PLAY_FULL=0
LAST_STATUS=$(cat "$BATTERY/status" 2>/dev/null | tr -d '[:space:]')
LOG_FILE="/tmp/battery.log"

# Check for sound player
if ! command -v paplay >/dev/null 2>&1; then
    echo "paplay not found. Sound alerts will not work." > "$LOG_FILE"
fi

echo "$(date): Battery monitor started. Current status: $LAST_STATUS" >> "$LOG_FILE"

while true; do
    if [ -d "$BATTERY" ]; then
        CAP=$(cat "$BATTERY/capacity" | tr -d '[:space:]')
        STATUS=$(cat "$BATTERY/status" | tr -d '[:space:]')
        NOW=$(date +%s)
        
        # Detect Plug/Unplug events
        if [ "$STATUS" != "$LAST_STATUS" ]; then
            echo "$(date): Status changed from $LAST_STATUS to $STATUS" >> "$LOG_FILE"
            if [ "$STATUS" == "Charging" ]; then
                echo "$(date): Playing plug sound" >> "$LOG_FILE"
                paplay --volume=45875 "$SOUND_PLUG" 2>> "$LOG_FILE"
            elif [ "$STATUS" == "Discharging" ]; then
                echo "$(date): Playing unplug sound" >> "$LOG_FILE"
                paplay --volume=45875 "$SOUND_UNPLUG" 2>> "$LOG_FILE"
            fi
            LAST_STATUS="$STATUS"
        fi
        
        # Alert if Full
        if [ "$STATUS" == "Full" ] || [ "$CAP" -eq 100 ]; then
            ELAPSED_FULL=$((NOW - LAST_PLAY_FULL))
            if [ "$ELAPSED_FULL" -ge 180 ]; then
                echo "$(date): Battery is FULL" >> "$LOG_FILE"
                paplay --volume=45875 "$SOUND_FULL" 2>> "$LOG_FILE"
                notify-send -i battery-full "Battery Full" "Please disconnect the charger to save battery health."
                LAST_PLAY_FULL=$NOW
            fi
        else
            LAST_PLAY_FULL=0
        fi
        
        # Only alert if discharging
        if [ "$STATUS" == "Discharging" ]; then
            INTERVAL=0
            LEVEL=""
            
            if [ "$CAP" -le 10 ]; then
                INTERVAL=60
                LEVEL="CRITICAL"
            elif [ "$CAP" -le 20 ]; then
                INTERVAL=120
                LEVEL="LOW"
            elif [ "$CAP" -le 30 ]; then
                INTERVAL=300
                LEVEL="WARNING"
            fi
            
            if [ "$INTERVAL" -gt 0 ]; then
                ELAPSED=$((NOW - LAST_PLAY))
                if [ "$ELAPSED" -ge "$INTERVAL" ]; then
                    # Play sound
                    echo "$(date): Low battery alert ($CAP%)" >> "$LOG_FILE"
                    paplay --volume=45875 "$SOUND_LOW" 2>> "$LOG_FILE"
                    
                    # Send notification
                    notify-send -u critical -i battery-caution \
                        "Battery $LEVEL ($CAP%)" \
                        "Please connect your charger. Next alert in $((INTERVAL / 60)) min."
                    
                    LAST_PLAY=$NOW
                fi
            fi
        else
            # Reset if charging
            LAST_PLAY=0
        fi
    fi
    
    # Check every 30 seconds
    sleep 30
done
