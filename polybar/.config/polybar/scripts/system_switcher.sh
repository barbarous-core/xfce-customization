#!/bin/bash

# Theme Colors
COLOR_SAFE="%{F#70af1e}"    # Green
COLOR_WARN="%{F#f0c674}"    # Orange/Yellow
COLOR_DANGER="%{F#A54242}"  # Red
COLOR_RESET="%{F-}"

# Icons
ICON_RAM_CHAR=$(echo -e "\uefc5")
ICON_CPU_CHAR=""
ICON_TEMP_CHAR=""
ICON_FS_CHAR="󰋊"

# Tightened fixed length to 15 to remove the gap before the separator
FIXED_LEN=15
COUNTER=0
CURRENT_FRAME=0
BLINK_STATE=0

while true; do
    ((COUNTER++))
    if [ "$COUNTER" -ge 10 ]; then
        COUNTER=0
        ((CURRENT_FRAME=(CURRENT_FRAME+1)%3))
    fi

    ((BLINK_STATE=(BLINK_STATE+1)%2))

    case $CURRENT_FRAME in
        0) # --- Memory ---
            RAM_INFO=$(free -h | grep Mem)
            RAM_USAGE=$(free | grep Mem | awk '{print int($3/$2 * 100.0)}')
            TOTAL_RAM=$(echo "$RAM_INFO" | awk '{print $2}' | sed 's/Gi/GB/')
            
            if [ "$RAM_USAGE" -ge 90 ]; then
                [ "$BLINK_STATE" -eq 0 ] && TEXT_COLOR="$COLOR_DANGER" || TEXT_COLOR="$COLOR_RESET"
                ICON="%{T4}${COLOR_DANGER}${ICON_RAM_CHAR}${COLOR_RESET}%{T-}"
            elif [ "$RAM_USAGE" -ge 70 ]; then
                TEXT_COLOR="$COLOR_RESET"
                ICON="%{T4}${COLOR_WARN}${ICON_RAM_CHAR}${COLOR_RESET}%{T-}"
            else
                TEXT_COLOR="$COLOR_RESET"
                ICON="%{T4}${COLOR_SAFE}${ICON_RAM_CHAR}${COLOR_RESET}%{T-}"
            fi
            
            TEXT=" ${RAM_USAGE}% ($TOTAL_RAM)"
            PADDED=$(printf "%${FIXED_LEN}s" "$TEXT")
            echo "${ICON}${TEXT_COLOR}${PADDED}${COLOR_RESET}"
            ;;

        1) # --- CPU & Temp ---
            CPU_USAGE=$(top -bn1 | grep "Cpu(s)" | sed "s/.*, *\([0-9.]*\)%* id.*/\1/" | awk '{print int(100 - $1)}')
            TEMP=$(cat /sys/class/thermal/thermal_zone0/temp 2>/dev/null || echo 0)
            TEMP_C=$((TEMP / 1000))
            
            # --- Color Logic for CPU ---
            if [ "$CPU_USAGE" -ge 90 ]; then
                CLR_CPU="$COLOR_DANGER"
            elif [ "$CPU_USAGE" -ge 70 ]; then
                CLR_CPU="$COLOR_WARN"
            else
                CLR_CPU="$COLOR_SAFE"
            fi

            # --- Color Logic for Temperature ---
            if [ "$TEMP_C" -ge 80 ]; then
                CLR_TEMP="$COLOR_DANGER"
            elif [ "$TEMP_C" -ge 60 ]; then
                CLR_TEMP="$COLOR_WARN"
            else
                CLR_TEMP="$COLOR_SAFE"
            fi

            # --- Blinking Danger Logic ---
            IS_DANGER=0
            [ "$CPU_USAGE" -ge 90 ] && IS_DANGER=1
            [ "$TEMP_C" -ge 80 ] && IS_DANGER=1

            if [ "$IS_DANGER" -eq 1 ] && [ "$BLINK_STATE" -eq 0 ]; then
                TEXT_COLOR="$COLOR_DANGER"
            else
                TEXT_COLOR="$COLOR_RESET"
            fi

            ICON_CPU="%{T4}${CLR_CPU}${ICON_CPU_CHAR}${COLOR_RESET}%{T-}"
            ICON_TEMP="%{T4}${CLR_TEMP}${ICON_TEMP_CHAR}${COLOR_RESET}%{T-}"
            
            # Print with aligned padding
            echo "${ICON_CPU}${TEXT_COLOR} ${CPU_USAGE}%  ${ICON_TEMP}${TEXT_COLOR} ${TEMP_C}°C   ${COLOR_RESET}"
            ;;

        2) # --- Filesystem ---
            FS_INFO=$(df -h / | awk 'NR==2')
            FS_USAGE_RAW=$(echo "$FS_INFO" | awk '{print $5}' | sed 's/%//')
            FS_TOTAL=$(echo "$FS_INFO" | awk '{print $2}' | sed 's/G/GB/')
            
            if [ "$FS_USAGE_RAW" -ge 90 ]; then
                [ "$BLINK_STATE" -eq 0 ] && TEXT_COLOR="$COLOR_DANGER" || TEXT_COLOR="$COLOR_RESET"
                ICON="%{T4}${COLOR_DANGER}${ICON_FS_CHAR}${COLOR_RESET}%{T-}"
            elif [ "$FS_USAGE_RAW" -ge 70 ]; then
                TEXT_COLOR="$COLOR_RESET"
                ICON="%{T4}${COLOR_WARN}${ICON_FS_CHAR}${COLOR_RESET}%{T-}"
            else
                TEXT_COLOR="$COLOR_RESET"
                ICON="%{T4}${COLOR_SAFE}${ICON_FS_CHAR}${COLOR_RESET}%{T-}"
            fi
            
            TEXT=" / ${FS_USAGE_RAW}% ($FS_TOTAL)"
            PADDED=$(printf "%${FIXED_LEN}s" "$TEXT")
            echo "${ICON}${TEXT_COLOR}${PADDED}${COLOR_RESET}"
            ;;
    esac

    sleep 0.5
done
