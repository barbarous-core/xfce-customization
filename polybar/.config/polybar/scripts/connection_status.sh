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

# Signal Handling for immediate refresh
trap "echo 'Refreshing...'" USR1

while true; do
    # 1. WiFi Status (Check all wifi devices)
    WIFI_INFO=$(nmcli -t -f active,ssid,device dev wifi | grep '^yes' | head -n 1)
    WIFI_SSID=$(echo "$WIFI_INFO" | cut -d: -f2)
    
    if [ -n "$WIFI_SSID" ]; then
        CLR_WIFI="$COLOR_ACTIVE"
        HAS_WIFI=1
    else
        CLR_WIFI="$COLOR_DIM"
        WIFI_SSID="Disconnected"
        HAS_WIFI=0
    fi

    # 2. Ethernet Status
    ETH_STATE=$(nmcli device status | grep 'ethernet' | awk '{print $3}' | grep 'connected' | wc -l)
    if [ "$ETH_STATE" -gt 0 ]; then
        CLR_ETH="$COLOR_ACTIVE"
        ETH_INFO="Connected"
        HAS_ETH=1
    else
        CLR_ETH="$COLOR_DIM"
        ETH_INFO="Disconnected"
        HAS_ETH=0
    fi

    # 3. Hotspot Status (Check for AP mode OR connection named "Hotspot")
    # Check if machine IS a hotspot
    IS_HOSTING=$(nmcli -t -f active,mode dev wifi | grep '^yes:ap' | wc -l)
    # Check if CONNECTED TO a network named "Hotspot"
    IS_CONNECTED_TO_HOTSPOT=$(nmcli -t -f NAME connection show --active | grep -i "Hotspot" | wc -l)

    if [ "$IS_HOSTING" -gt 0 ] || [ "$IS_CONNECTED_TO_HOTSPOT" -gt 0 ]; then
        CLR_HOTSPOT="$COLOR_ACTIVE"
        HOTSPOT_INFO="Active"
        HAS_HOTSPOT=1
    else
        CLR_HOTSPOT="$COLOR_DIM"
        HOTSPOT_INFO="Off"
        HAS_HOTSPOT=0
    fi

    # 4. Sound Notification Logic
    if [ $HAS_WIFI -eq 1 ] || [ $HAS_ETH -eq 1 ] || [ $HAS_HOTSPOT -eq 1 ]; then
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

    # 5. Bluetooth Status
    BT_POWERED=$(bluetoothctl show | grep "Powered: yes" | wc -l)
    BT_CONNECTED_NAME=$(bluetoothctl devices Connected | cut -d ' ' -f 3-)
    
    if [ "$BT_POWERED" -gt 0 ]; then
        if [ -n "$BT_CONNECTED_NAME" ]; then
            CLR_BT="$COLOR_BT_ACTIVE"
            BT_INFO="$BT_CONNECTED_NAME"
        else
            CLR_BT="$COLOR_ACTIVE"
            BT_INFO="On"
        fi
    else
        CLR_BT="$COLOR_DIM"
        BT_INFO="Off"
    fi

    # 6. Build Output
    ACTIVE_MODULE=$(cat "$GLOBAL_STATE_FILE" 2>/dev/null || echo "none")

    W_ICON="%{T4}${CLR_WIFI}${ICON_WIFI}${COLOR_RESET}%{T-}"
    E_ICON="%{T4}${CLR_ETH}${ICON_ETH}${COLOR_RESET}%{T-}"
    H_ICON="%{A1:nmcli device disconnect wlp0s20f3:}%{A3:~/Linux_Data/Git_Projects/xfce-customization/polybar/.config/polybar/scripts/hotspot_manager.sh:}%{T4}${CLR_HOTSPOT}${ICON_HOTSPOT}${COLOR_RESET}%{T-}%{A}%{A}"
    B_ICON="%{A1:~/Linux_Data/Git_Projects/xfce-customization/polybar/.config/polybar/scripts/toggle_bluetooth.sh:}%{T3}${CLR_BT}${ICON_BT}${COLOR_RESET}%{T-}%{A}"

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
        [ $HAS_WIFI -eq 1 ] && OUTPUT="${W_ICON} ${WIFI_SSID}"
        
        [ $HAS_ETH -eq 1 ] && [ -n "$OUTPUT" ] && OUTPUT="${OUTPUT}  "
        [ $HAS_ETH -eq 1 ] && OUTPUT="${OUTPUT}${E_ICON} Wired"
        
        [ $HAS_HOTSPOT -eq 1 ] && [ -n "$OUTPUT" ] && OUTPUT="${OUTPUT}  "
        [ $HAS_HOTSPOT -eq 1 ] && OUTPUT="${OUTPUT}${H_ICON} Hotspot"
        
        # Always show Bluetooth in expanded view so it can be toggled back on
        [ -n "$OUTPUT" ] && OUTPUT="${OUTPUT}  "
        OUTPUT="${OUTPUT}${B_ICON} ${BT_INFO}"
        
        [ -z "$OUTPUT" ] && OUTPUT="${ICON_STATUS} ${TEXT_STATUS}"
        echo "$OUTPUT"
    else
        # Collapsed View
        echo "${W_ICON} ${E_ICON} ${H_ICON} ${B_ICON}"
    fi

    sleep 2
done
