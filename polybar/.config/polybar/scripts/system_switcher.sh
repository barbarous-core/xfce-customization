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

# Adjusted length for tighter fit
FIXED_LEN=15
COUNTER=0
CURRENT_FRAME=0
BLINK_STATE=0

# --- SIMULATION MODE ---
# 0: Off, 1: Danger, 2: Warning
SIMULATE=0

while true; do
    # --- 1. Gather all data ---
    RAM_INFO=$(free -h | grep Mem)
    RAM_USAGE=$(free | grep Mem | awk '{print int($3/$2 * 100.0)}')
    TOTAL_RAM=$(echo "$RAM_INFO" | awk '{print $2}' | sed 's/Gi/GB/')
    
    CPU_USAGE=$(top -bn1 | grep "Cpu(s)" | sed "s/.*, *\([0-9.]*\)%* id.*/\1/" | awk '{print int(100 - $1)}')
    
    TEMP_PATH=$(grep -l "x86_pkg_temp" /sys/class/thermal/thermal_zone*/type | sed 's/type/temp/' | head -n1)
    [ -z "$TEMP_PATH" ] && TEMP_PATH="/sys/class/thermal/thermal_zone0/temp"
    TEMP=$(cat "$TEMP_PATH" 2>/dev/null || echo 0)
    TEMP_C=$((TEMP / 1000))
    
    FS_INFO=$(df -h / | awk 'NR==2')
    FS_USAGE_RAW=$(echo "$FS_INFO" | awk '{print $5}' | sed 's/%//')
    FS_TOTAL=$(echo "$FS_INFO" | awk '{print $2}' | sed 's/G/GB/')

    # --- SIMULATION OVERRIDE ---
    if [ "$SIMULATE" -eq 1 ]; then
        CPU_USAGE=99; TEMP_C=95; RAM_USAGE=95; FS_USAGE_RAW=95
    elif [ "$SIMULATE" -eq 2 ]; then
        CPU_USAGE=75; TEMP_C=65; RAM_USAGE=75; FS_USAGE_RAW=75
    fi

    # --- 2. Check for Danger/Warning States ---
    DANGER_MODULE=-1
    if [ "$CPU_USAGE" -ge 90 ] || [ "$TEMP_C" -ge 80 ]; then DANGER_MODULE=1
    elif [ "$RAM_USAGE" -ge 90 ]; then DANGER_MODULE=0
    elif [ "$FS_USAGE_RAW" -ge 90 ]; then DANGER_MODULE=2
    fi

    if [ "$DANGER_MODULE" -ne -1 ]; then
        CURRENT_FRAME=$DANGER_MODULE; COUNTER=0
    else
        ((COUNTER++))
        if [ "$COUNTER" -ge 10 ]; then COUNTER=0; ((CURRENT_FRAME=(CURRENT_FRAME+1)%3)); fi
    fi

    ((BLINK_STATE=(BLINK_STATE+1)%2))

    # --- 4. Render current frame ---
    case $CURRENT_FRAME in
        0) # Memory
            if [ "$RAM_USAGE" -ge 90 ]; then
                [ "$BLINK_STATE" -eq 0 ] && TEXT_COLOR="$COLOR_DANGER" || TEXT_COLOR="$COLOR_RESET"
                ICON_CLR="$COLOR_DANGER"
            elif [ "$RAM_USAGE" -ge 70 ]; then
                TEXT_COLOR="$COLOR_WARN"; ICON_CLR="$COLOR_WARN"
            else
                TEXT_COLOR="$COLOR_RESET"; ICON_CLR="$COLOR_SAFE"
            fi
            ICON="%{T4}${ICON_CLR}${ICON_RAM_CHAR}${COLOR_RESET}%{T-}"
            
            # --- Move 36% near icon ---
            # We use left-aligned padding for the percentage, and then add the total
            TEXT=" ${RAM_USAGE}% ($TOTAL_RAM)"
            PADDED=$(printf "%-${FIXED_LEN}s" "$TEXT")
            echo "${ICON}${TEXT_COLOR}${PADDED}${COLOR_RESET}"
            ;;

        1) # CPU & Temp
            if [ "$CPU_USAGE" -ge 90 ] || [ "$TEMP_C" -ge 80 ]; then
                [ "$BLINK_STATE" -eq 0 ] && TEXT_COLOR="$COLOR_DANGER" || TEXT_COLOR="$COLOR_RESET"
            elif [ "$CPU_USAGE" -ge 70 ] || [ "$TEMP_C" -ge 60 ]; then
                TEXT_COLOR="$COLOR_WARN"
            else
                TEXT_COLOR="$COLOR_RESET"
            fi
            
            if [ "$CPU_USAGE" -ge 90 ]; then CLR_CPU="$COLOR_DANGER"; elif [ "$CPU_USAGE" -ge 70 ]; then CLR_CPU="$COLOR_WARN"; else CLR_CPU="$COLOR_SAFE"; fi
            if [ "$TEMP_C" -ge 80 ]; then CLR_TEMP="$COLOR_DANGER"; elif [ "$TEMP_C" -ge 60 ]; then CLR_TEMP="$COLOR_WARN"; else CLR_TEMP="$COLOR_SAFE"; fi

            ICON_CPU="%{T4}${CLR_CPU}${ICON_CPU_CHAR}${COLOR_RESET}%{T-}"
            ICON_TEMP="%{T4}${CLR_TEMP}${ICON_TEMP_CHAR}${COLOR_RESET}%{T-}"
            
            # Left-aligned for CPU text
            CPU_INFO=" ${CPU_USAGE}%  ${ICON_TEMP}${TEXT_COLOR} ${TEMP_C}°C"
            PADDED_CPU=$(printf "%-${FIXED_LEN}s" "$CPU_INFO")
            echo "${ICON_CPU}${TEXT_COLOR}${PADDED_CPU}${COLOR_RESET}"
            ;;

        2) # Filesystem
            if [ "$FS_USAGE_RAW" -ge 90 ]; then
                [ "$BLINK_STATE" -eq 0 ] && TEXT_COLOR="$COLOR_DANGER" || TEXT_COLOR="$COLOR_RESET"
                ICON_CLR="$COLOR_DANGER"
            elif [ "$FS_USAGE_RAW" -ge 70 ]; then
                TEXT_COLOR="$COLOR_WARN"; ICON_CLR="$COLOR_WARN"
            else
                TEXT_COLOR="$COLOR_RESET"; ICON_CLR="$COLOR_SAFE"
            fi
            ICON="%{T4}${ICON_CLR}${ICON_FS_CHAR}${COLOR_RESET}%{T-}"
            
            TEXT=" / ${FS_USAGE_RAW}% ($FS_TOTAL)"
            PADDED=$(printf "%-${FIXED_LEN}s" "$TEXT")
            echo "${ICON}${TEXT_COLOR}${PADDED}${COLOR_RESET}"
            ;;
    esac

    sleep 0.5
done
