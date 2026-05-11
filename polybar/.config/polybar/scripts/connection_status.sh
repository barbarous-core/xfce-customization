#!/bin/bash

# Configuration
GLOBAL_STATE_FILE="/tmp/polybar_active_module"

# Icons
ICON_WIFI=""
ICON_ETH="󰈀"
ICON_BT=""
ICON_OFFLINE="󰖪"

while true; do
    # 1. Get WiFi Info
    WIFI_SSID=$(nmcli -t -f active,ssid dev wifi | grep '^yes' | cut -d: -f2)
    if [ -n "$WIFI_SSID" ]; then
        WIFI_ICON="%{F#F0C674}%{T4}${ICON_WIFI}%{T-}%{F-}"
        WIFI_TEXT="$WIFI_SSID"
    else
        WIFI_ICON=""
        WIFI_TEXT=""
    fi

    # 2. Get Ethernet Info
    ETH_STATE=$(nmcli device status | grep 'ethernet' | awk '{print $3}')
    if [ "$ETH_STATE" == "connected" ]; then
        ETH_ICON="%{F#F0C674}%{T4}${ICON_ETH}%{T-}%{F-}"
        ETH_TEXT="Wired"
    else
        ETH_ICON=""
        ETH_TEXT=""
    fi

    # 3. Get Bluetooth Info
    BT_POWERED=$(bluetoothctl show | grep "Powered: yes" | wc -l)
    BT_CONNECTED_NAME=$(bluetoothctl devices Connected | cut -d ' ' -f 3-)
    
    if [ "$BT_POWERED" -gt 0 ]; then
        if [ -n "$BT_CONNECTED_NAME" ]; then
            BT_ICON="%{F#61afef}%{T4}${ICON_BT}%{T-}%{F-}"
            BT_TEXT="$BT_CONNECTED_NAME"
        else
            BT_ICON="%{F#707880}%{T4}${ICON_BT}%{T-}%{F-}"
            BT_TEXT="On"
        fi
    else
        BT_ICON=""
        BT_TEXT=""
    fi

    # 4. Check Global State
    ACTIVE_MODULE=$(cat "$GLOBAL_STATE_FILE" 2>/dev/null || echo "none")

    if [ -z "$WIFI_ICON" ] && [ -z "$ETH_ICON" ]; then
        ICON_STATUS="%{F#A54242}%{T4}${ICON_OFFLINE}%{T-}%{F-}"
        TEXT_STATUS="Offline"
    else
        ICON_STATUS=""
        TEXT_STATUS=""
    fi

    if [ "$ACTIVE_MODULE" == "connection" ]; then
        # Expanded View
        OUTPUT=""
        [ -n "$WIFI_ICON" ] && OUTPUT="${WIFI_ICON} ${WIFI_TEXT}"
        [ -n "$ETH_ICON" ] && [ -n "$OUTPUT" ] && OUTPUT="${OUTPUT}  "
        [ -n "$ETH_ICON" ] && OUTPUT="${OUTPUT}${ETH_ICON} ${ETH_TEXT}"
        [ -n "$BT_ICON" ] && [ -n "$OUTPUT" ] && OUTPUT="${OUTPUT}  "
        [ -n "$BT_ICON" ] && OUTPUT="${OUTPUT}${BT_ICON} ${BT_TEXT}"
        [ -n "$ICON_STATUS" ] && OUTPUT="${ICON_STATUS} ${TEXT_STATUS}"
        echo "$OUTPUT"
    else
        # Collapsed View
        OUTPUT=""
        [ -n "$WIFI_ICON" ] && OUTPUT="${WIFI_ICON}"
        [ -n "$ETH_ICON" ] && [ -n "$OUTPUT" ] && OUTPUT="${OUTPUT}  "
        [ -n "$ETH_ICON" ] && OUTPUT="${OUTPUT}${ETH_ICON}"
        [ -n "$BT_ICON" ] && [ -n "$OUTPUT" ] && OUTPUT="${OUTPUT}  "
        [ -n "$BT_ICON" ] && OUTPUT="${OUTPUT}${BT_ICON}"
        [ -n "$ICON_STATUS" ] && OUTPUT="${ICON_STATUS}"
        echo "$OUTPUT"
    fi

    sleep 2
done
