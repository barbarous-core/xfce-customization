#!/bin/bash

# Configuration
GLOBAL_STATE_FILE="/tmp/polybar_active_module"

# Colors
COLOR_ACTIVE="%{F#F0C674}"   # Primary Yellow
COLOR_BT_ACTIVE="%{F#61afef}" # Blue for BT
COLOR_DIM="%{F#707880}"      # Grey for inactive
COLOR_OFFLINE="%{F#A54242}"  # Red
COLOR_RESET="%{F-}"

# Icons
ICON_WIFI=""
ICON_ETH="󰈀"
ICON_BT=""
ICON_HOTSPOT="󰖇"

while true; do
    # 1. WiFi Status
    WIFI_SSID=$(nmcli -t -f active,ssid dev wifi | grep '^yes' | cut -d: -f2)
    if [ -n "$WIFI_SSID" ]; then
        CLR_WIFI="$COLOR_ACTIVE"
        WIFI_INFO="$WIFI_SSID"
    else
        CLR_WIFI="$COLOR_DIM"
        WIFI_INFO="Disconnected"
    fi

    # 2. Ethernet Status
    ETH_STATE=$(nmcli device status | grep 'ethernet' | awk '{print $3}')
    if [ "$ETH_STATE" == "connected" ]; then
        CLR_ETH="$COLOR_ACTIVE"
        ETH_INFO="Connected"
    else
        CLR_ETH="$COLOR_DIM"
        ETH_INFO="Disconnected"
    fi

    # 3. Hotspot Status
    HOTSPOT_ACTIVE=$(nmcli -t -f active,mode dev wifi | grep '^yes:ap' | wc -l)
    if [ "$HOTSPOT_ACTIVE" -gt 0 ]; then
        CLR_HOTSPOT="$COLOR_ACTIVE"
        HOTSPOT_INFO="Active"
    else
        CLR_HOTSPOT="$COLOR_DIM"
        HOTSPOT_INFO="Off"
    fi

    # 4. Bluetooth Status
    BT_POWERED=$(bluetoothctl show | grep "Powered: yes" | wc -l)
    BT_CONNECTED_NAME=$(bluetoothctl devices Connected | cut -d ' ' -f 3-)
    
    if [ "$BT_POWERED" -gt 0 ]; then
        if [ -n "$BT_CONNECTED_NAME" ]; then
            CLR_BT="$COLOR_BT_ACTIVE"
            BT_INFO="$BT_CONNECTED_NAME"
        else
            CLR_BT="$COLOR_ACTIVE"
            BT_INFO="On (Idle)"
        fi
    else
        CLR_BT="$COLOR_DIM"
        BT_INFO="Off"
    fi

    # 5. Build Output
    ACTIVE_MODULE=$(cat "$GLOBAL_STATE_FILE" 2>/dev/null || echo "none")

    # Icons with tags
    W_ICON="%{T4}${CLR_WIFI}${ICON_WIFI}${COLOR_RESET}%{T-}"
    E_ICON="%{T4}${CLR_ETH}${ICON_ETH}${COLOR_RESET}%{T-}"
    H_ICON="%{T4}${CLR_HOTSPOT}${ICON_HOTSPOT}${COLOR_RESET}%{T-}"
    B_ICON="%{T4}${CLR_BT}${ICON_BT}${COLOR_RESET}%{T-}"

    if [ "$ACTIVE_MODULE" == "connection" ]; then
        # Expanded View
        echo "${W_ICON} ${WIFI_INFO}  ${E_ICON} ${ETH_INFO}  ${H_ICON} ${HOTSPOT_INFO}  ${B_ICON} ${BT_INFO}"
    else
        # Collapsed View (all icons)
        echo "${W_ICON} ${E_ICON} ${H_ICON} ${B_ICON}"
    fi

    sleep 2
done
