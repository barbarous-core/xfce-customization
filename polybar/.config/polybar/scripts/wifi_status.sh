#!/bin/bash

# Configuration
STATE_FILE="/tmp/wifi_toggle_state"
IFACE="wlp0s20f0u3"
ICON="%{F#F0C674}%{T4}%{T-}%{F-}"

# Toggle logic
if [ "$1" == "--toggle" ]; then
    if [ ! -f "$STATE_FILE" ] || [ "$(cat "$STATE_FILE")" == "icon" ]; then
        echo "full" > "$STATE_FILE"
    else
        echo "icon" > "$STATE_FILE"
    fi
    # Refresh polybar to show change immediately
    polybar-msg cmd restart >/dev/null 2>&1
    exit 0
fi

# Initial state if not exists
[ ! -f "$STATE_FILE" ] && echo "icon" > "$STATE_FILE"
STATE=$(cat "$STATE_FILE")

if [ "$STATE" == "full" ]; then
    # Calculate speed over 1 second
    if [ -f "/sys/class/net/$IFACE/statistics/rx_bytes" ]; then
        R1=$(cat /sys/class/net/$IFACE/statistics/rx_bytes)
        T1=$(cat /sys/class/net/$IFACE/statistics/tx_bytes)
        sleep 1
        R2=$(cat /sys/class/net/$IFACE/statistics/rx_bytes)
        T2=$(cat /sys/class/net/$IFACE/statistics/tx_bytes)
        
        RX_SPEED=$(( (R2 - R1) / 1024 ))
        TX_SPEED=$(( (T2 - T1) / 1024 ))
        
        echo "$ICON ↓ ${RX_SPEED}KB/s ↑ ${TX_SPEED}KB/s "
    else
        echo "%{F#A54242}󰖪 %{F-} Offline"
    fi
else
    echo "$ICON"
fi
