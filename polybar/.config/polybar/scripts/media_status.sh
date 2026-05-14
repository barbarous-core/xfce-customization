#!/bin/bash

# Configuration
GLOBAL_STATE_FILE="/tmp/polybar_active_module"

# Icons
ICON_VOL_HIGH=$(printf '\U000f057e')
ICON_VOL_LOW=$(printf '\U000f0580')
ICON_VOL_MUTED=$(printf '\U000f075f')
ICON_MIC_ON=$(printf '\uf130')
ICON_MIC_OFF=$(printf '\uf131')

# Fetch theme colors
PRIMARY_COLOR=$(grep "^primary =" "$HOME/.config/polybar/colors.ini" | cut -d' ' -f3 || echo "#F0C674")
ALERT_COLOR=$(grep "^alert =" "$HOME/.config/polybar/colors.ini" | cut -d' ' -f3 || echo "#A54242")
COLOR_PRIMARY="%{F$PRIMARY_COLOR}"
COLOR_ALERT="%{F$ALERT_COLOR}"
COLOR_RESET="%{F-}"

while true; do
    # 1. Get Volume Info
    VOL_RAW=$(pactl get-sink-volume @DEFAULT_SINK@ 2>/dev/null)
    VOL_INFO=$(echo "$VOL_RAW" | grep -oP '\d+%' | head -1 | tr -d '%')
    VOL_MUTED=$(pactl get-sink-mute @DEFAULT_SINK@ 2>/dev/null | grep -oP 'yes|no')
    
    [ -z "$VOL_INFO" ] && VOL_INFO=0
    [ -z "$VOL_MUTED" ] && VOL_MUTED="no"

    if [ "$VOL_MUTED" == "yes" ]; then
        VOL_ICON="${COLOR_ALERT}%{T4}${ICON_VOL_MUTED}%{T-}${COLOR_RESET}"
        VOL_TEXT="Muted"
    else
        if [ "$VOL_INFO" -le 50 ]; then
            VOL_ICON="${COLOR_PRIMARY}%{T4}${ICON_VOL_LOW}%{T-}${COLOR_RESET}"
        else
            VOL_ICON="${COLOR_PRIMARY}%{T4}${ICON_VOL_HIGH}%{T-}${COLOR_RESET}"
        fi
        VOL_TEXT="${VOL_INFO}%"
    fi

    # Wrap Volume Icon in Action Tag (Left click to mute/unmute sink)
    VOL_BTN="%{A1:pactl set-sink-mute @DEFAULT_SINK@ toggle:}${VOL_ICON}%{A}"

    # 2. Get Mic Info
    MIC_MUTED=$(pactl get-source-mute @DEFAULT_SOURCE@ 2>/dev/null | grep -oP 'yes|no')
    [ -z "$MIC_MUTED" ] && MIC_MUTED="no"

    if [ "$MIC_MUTED" == "yes" ]; then
        MIC_ICON="${COLOR_ALERT}%{T4}${ICON_MIC_OFF}%{T-}${COLOR_RESET}"
        MIC_TEXT="Muted"
    else
        MIC_ICON="${COLOR_PRIMARY}%{T4}${ICON_MIC_ON}%{T-}${COLOR_RESET}"
        MIC_TEXT="Active"
    fi

    # Wrap Mic Icon in Action Tag (Left click to mute/unmute source)
    MIC_BTN="%{A1:pactl set-source-mute @DEFAULT_SOURCE@ toggle:}${MIC_ICON}%{A}"

    # 3. Check Global State
    ACTIVE_MODULE=$(cat "$GLOBAL_STATE_FILE" 2>/dev/null || echo "none")

    if [ "$ACTIVE_MODULE" == "media" ]; then
        # Expanded View
        if [ "$IS_MINIMAL" == "true" ]; then
            OUTPUT="${VOL_BTN} ${VOL_TEXT}"
        else
            OUTPUT="${VOL_BTN} ${VOL_TEXT}  ${MIC_BTN} ${MIC_TEXT}"
        fi
        echo "$OUTPUT"
    else
        # Collapsed View
        if [ "$IS_MINIMAL" == "true" ]; then
            OUTPUT="${VOL_BTN}"
        else
            OUTPUT="${VOL_BTN}  ${MIC_BTN}"
        fi
        echo "$OUTPUT"
    fi

    sleep 1
done
