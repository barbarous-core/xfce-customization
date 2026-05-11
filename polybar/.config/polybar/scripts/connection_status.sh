#!/bin/bash

# Configuration
GLOBAL_STATE_FILE="/tmp/polybar_active_module"
SOUND_DIR="/usr/share/sounds/freedesktop/stereo"

# Icons
ICON_WIFI=""
ICON_ETH="󰈀"
ICON_BT=""
ICON_HOTSPOT="󱜠"
ICON_OFFLINE="󰖪"

# Colors
COLOR_ACTIVE="%{F#F0C674}"
COLOR_BT_ACTIVE="%{F#61afef}"
COLOR_DIM="%{F#707880}"
COLOR_OFFLINE="%{F#A54242}"
COLOR_RESET="%{F-}"

# State Tracking
PREV_NET_STATE="none"

while true; do
    # 1. WiFi Status
    WIFI_SSID=$(nmcli -t -f active,ssid dev wifi | grep '^yes' | cut -d: -f2)
    if [ -n "$WIFI_SSID" ]; then
        CLR_WIFI="$COLOR_ACTIVE"
        WIFI_INFO="$WIFI_SSID"
        HAS_WIFI=1
    else
        CLR_WIFI="$COLOR_DIM"
        WIFI_INFO="Disconnected"
        HAS_WIFI=0
    fi

    # 2. Ethernet Status
    ETH_STATE=$(nmcli device status | grep 'ethernet' | awk '{print $3}')
    if [ "$ETH_STATE" == "connected" ]; then
        CLR_ETH="$COLOR_ACTIVE"
        ETH_INFO="Connected"
        HAS_ETH=1
    else
        CLR_ETH="$COLOR_DIM"
        ETH_INFO="Disconnected"
        HAS_ETH=0
    fi

    # 3. Sound Notification Logic
    if [ $HAS_WIFI -eq 1 ] || [ $HAS_ETH -eq 1 ]; then
        CURR_NET_STATE="online"
    else
        CURR_NET_STATE="offline"
    fi

    if [ "$PREV_NET_STATE" != "none" ] && [ "$CURR_NET_STATE" != "$PREV_NET_STATE" ]; then
        if [ "$CURR_NET_STATE" == "online" ]; then
            paplay "$SOUND_DIR/network-connectivity-established.oga" &
        else
            paplay "$SOUND_DIR/network-connectivity-lost.oga" &
        fi
    fi
    PREV_NET_STATE="$CURR_NET_STATE"

    # 4. Hotspot Status
    HOTSPOT_ACTIVE=$(nmcli -t -f active,mode dev wifi | grep '^yes:ap' | wc -l)
    if [ "$HOTSPOT_ACTIVE" -gt 0 ]; then
        CLR_HOTSPOT="$COLOR_ACTIVE"
        HOTSPOT_INFO="Active"
    else
        CLR_HOTSPOT="$COLOR_DIM"
        HOTSPOT_INFO="Off"
    fi

    # 5. Bluetooth Status
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

    # 6. Build Output
    ACTIVE_MODULE=$(cat "$GLOBAL_STATE_FILE" 2>/dev/null || echo "none")

    W_ICON="%{T4}${CLR_WIFI}${ICON_WIFI}${COLOR_RESET}%{T-}"
    E_ICON="%{T4}${CLR_ETH}${ICON_ETH}${COLOR_RESET}%{T-}"
    H_ICON="%{T4}${CLR_HOTSPOT}${ICON_HOTSPOT}${COLOR_RESET}%{T-}"
    B_ICON="%{T3}${CLR_BT}${ICON_BT}${COLOR_RESET}%{T-}"

    if [ "$CURR_NET_STATE" == "offline" ]; then
        ICON_STATUS="%{F#A54242}%{T4}${ICON_OFFLINE}%{T-}%{F-}"
        TEXT_STATUS="Offline"
    else
        ICON_STATUS=""
        TEXT_STATUS=""
    fi

    if [ "$ACTIVE_MODULE" == "connection" ]; then
        # Expanded View
        OUTPUT=""
        [ -n "$WIFI_SSID" ] && OUTPUT="${W_ICON} ${WIFI_INFO}"
        [ "$ETH_STATE" == "connected" ] && [ -n "$OUTPUT" ] && OUTPUT="${OUTPUT}  "
        [ "$ETH_STATE" == "connected" ] && OUTPUT="${OUTPUT}${E_ICON} Wired"
        [ "$HOTSPOT_ACTIVE" -gt 0 ] && [ -n "$OUTPUT" ] && OUTPUT="${OUTPUT}  "
        [ "$HOTSPOT_ACTIVE" -gt 0 ] && OUTPUT="${OUTPUT}${H_ICON} Hotspot"
        [ "$BT_POWERED" -gt 0 ] && [ -n "$OUTPUT" ] && OUTPUT="${OUTPUT}  "
        [ "$BT_POWERED" -gt 0 ] && OUTPUT="${OUTPUT}${B_ICON} ${BT_INFO}"
        [ -z "$OUTPUT" ] && OUTPUT="${ICON_STATUS} ${TEXT_STATUS}"
        echo "$OUTPUT"
    else
        # Collapsed View (all icons)
        echo "${W_ICON} ${E_ICON} ${H_ICON} ${B_ICON}"
    fi

    sleep 2
done
