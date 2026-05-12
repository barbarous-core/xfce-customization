#!/bin/bash

# Configuration
GLOBAL_STATE_FILE="/tmp/polybar_active_module"
IFACE="wlp0s20f0u3"
ICON="%{F#F0C674}%{T4}%{T-}%{F-}"

# Toggle logic (now handled by toggle_module.sh, but keeping for compatibility)
if [ "$1" == "--toggle" ]; then
    ~/Linux_Data/Git_Projects/xfce-customization/polybar/.config/polybar/scripts/toggle_module.sh wifi
    exit 0
fi

while true; do
    ACTIVE_MODULE=$(cat "$GLOBAL_STATE_FILE" 2>/dev/null || echo "none")

    if [ "$ACTIVE_MODULE" == "wifi" ]; then
        # Calculate speed over 1 second
        if [ -d "/sys/class/net/$IFACE" ]; then
            R1=$(cat /sys/class/net/$IFACE/statistics/rx_bytes 2>/dev/null || echo 0)
            T1=$(cat /sys/class/net/$IFACE/statistics/tx_bytes 2>/dev/null || echo 0)
            sleep 1
            R2=$(cat /sys/class/net/$IFACE/statistics/rx_bytes 2>/dev/null || echo 0)
            T2=$(cat /sys/class/net/$IFACE/statistics/tx_bytes 2>/dev/null || echo 0)
            
            RX_SPEED=$(( (R2 - R1) / 1024 ))
            TX_SPEED=$(( (T2 - T1) / 1024 ))
            
            echo "$ICON ↓ ${RX_SPEED}KB/s ↑ ${TX_SPEED}KB/s"
        else
            echo "%{F#A54242}%{T4}󰖪%{T-}%{F-} Offline"
            sleep 1
        fi
    else
        echo "$ICON"
        sleep 2
    fi
done
