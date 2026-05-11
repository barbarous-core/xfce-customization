#!/bin/bash

# Configuration
STATE_FILE="/tmp/sys_switch_toggle_state"

# Toggle logic
if [ "$1" == "--toggle" ]; then
    if [ ! -f "$STATE_FILE" ] || [ "$(cat "$STATE_FILE")" == "full" ]; then
        echo "icon" > "$STATE_FILE"
    else
        echo "full" > "$STATE_FILE"
    fi
    exit 0
fi

# Initial state (default: hide text)
echo "icon" > "$STATE_FILE"

# Theme Colors
COLOR_SAFE="%{F#70af1e}"    # Green
COLOR_WARN="%{F#f0c674}"    # Orange/Yellow
COLOR_DANGER="%{F#A54242}"  # Red
COLOR_RESET="%{F-}"

# Icons
ICON_RAM_CHAR=$(echo -e "\uefc5")
ICON_CPU_CHAR=$(echo -e "\uf4bc")
ICON_TEMP_CHAR=$(echo -e "\uf2c7")
ICON_FS_CHAR=$(echo -e "\U000f02ca")

COUNTER=0
CURRENT_FRAME=0
BLINK_STATE=0
SIMULATE=0

# --- Cache thermal zone path once (no need to grep sysfs every iteration) ---
TEMP_PATH=$(grep -l "x86_pkg_temp" /sys/class/thermal/thermal_zone*/type 2>/dev/null | head -n1)
if [ -n "$TEMP_PATH" ]; then
    TEMP_PATH="${TEMP_PATH%type}temp"
else
    TEMP_PATH="/sys/class/thermal/thermal_zone0/temp"
fi

# --- Initialize CPU measurement from /proc/stat (replaces top -bn1) ---
read -r _ PREV_USER PREV_NICE PREV_SYSTEM PREV_IDLE PREV_IOWAIT PREV_IRQ PREV_SOFTIRQ _ < /proc/stat
PREV_TOTAL=$((PREV_USER + PREV_NICE + PREV_SYSTEM + PREV_IDLE + PREV_IOWAIT + PREV_IRQ + PREV_SOFTIRQ))
PREV_IDLE_ALL=$((PREV_IDLE + PREV_IOWAIT))

while true; do
    # --- 1. Gather all data (no sed, no top, minimal forks) ---

    # RAM: read /proc/meminfo directly instead of free + grep + awk + sed
    while IFS=': ' read -r key val _; do
        case "$key" in
            MemTotal)  MEM_TOTAL_KB=$val ;;
            MemAvailable) MEM_AVAIL_KB=$val ;;
        esac
    done < /proc/meminfo
    MEM_USED_KB=$((MEM_TOTAL_KB - MEM_AVAIL_KB))
    if [ "$MEM_TOTAL_KB" -gt 0 ]; then
        RAM_USAGE_VAL=$((MEM_USED_KB * 100 / MEM_TOTAL_KB))
    else
        RAM_USAGE_VAL=0
    fi
    # Format total RAM in GB using bash arithmetic (no sed needed)
    MEM_TOTAL_GB=$(( (MEM_TOTAL_KB + 524288) / 1048576 ))
    TOTAL_RAM="${MEM_TOTAL_GB} GB"

    # CPU: read /proc/stat (replaces top -bn1 which was spawning a huge process)
    read -r _ CUR_USER CUR_NICE CUR_SYSTEM CUR_IDLE CUR_IOWAIT CUR_IRQ CUR_SOFTIRQ _ < /proc/stat
    CUR_TOTAL=$((CUR_USER + CUR_NICE + CUR_SYSTEM + CUR_IDLE + CUR_IOWAIT + CUR_IRQ + CUR_SOFTIRQ))
    CUR_IDLE_ALL=$((CUR_IDLE + CUR_IOWAIT))
    DIFF_TOTAL=$((CUR_TOTAL - PREV_TOTAL))
    DIFF_IDLE=$((CUR_IDLE_ALL - PREV_IDLE_ALL))
    if [ "$DIFF_TOTAL" -gt 0 ]; then
        CPU_USAGE_VAL=$(( (DIFF_TOTAL - DIFF_IDLE) * 100 / DIFF_TOTAL ))
    else
        CPU_USAGE_VAL=0
    fi
    PREV_TOTAL=$CUR_TOTAL
    PREV_IDLE_ALL=$CUR_IDLE_ALL

    # Temperature: just read the cached path (no grep/sed)
    TEMP=$(cat "$TEMP_PATH" 2>/dev/null || echo 0)
    TEMP_C_VAL=$((TEMP / 1000))

    # Filesystem: use awk only, no sed (single process instead of awk+sed chain)
    read -r FS_USAGE_VAL FS_TOTAL <<< "$(df -h / | awk 'NR==2 { gsub(/%/,"",$5); gsub(/G$/," GB",$2); print $5, $2 }')"

    if [ "$SIMULATE" -eq 1 ]; then
        CPU_USAGE_VAL=99; TEMP_C_VAL=95; RAM_USAGE_VAL=95; FS_USAGE_VAL=95
    elif [ "$SIMULATE" -eq 2 ]; then
        CPU_USAGE_VAL=5; TEMP_C_VAL=45; RAM_USAGE_VAL=75; FS_USAGE_VAL=75
    fi

    # --- 2. Check for Danger/Warning States ---
    DANGER_MODULE=-1
    if [ "$CPU_USAGE_VAL" -ge 90 ] || [ "$TEMP_C_VAL" -ge 80 ]; then DANGER_MODULE=1
    elif [ "$RAM_USAGE_VAL" -ge 90 ]; then DANGER_MODULE=0
    elif [ "$FS_USAGE_VAL" -ge 90 ]; then DANGER_MODULE=2
    fi

    if [ "$DANGER_MODULE" -ne -1 ]; then
        CURRENT_FRAME=$DANGER_MODULE; COUNTER=0
    else
        ((COUNTER++))
        if [ "$COUNTER" -ge 10 ]; then COUNTER=0; ((CURRENT_FRAME=(CURRENT_FRAME+1)%3)); fi
    fi

    ((BLINK_STATE=(BLINK_STATE+1)%2))

    # --- 4. Read toggle state ---
    STATE=$(cat "$STATE_FILE")

    # --- 5. Render current frame ---
    case $CURRENT_FRAME in
        0) # Memory
            RAM_USAGE=$(printf "%2d%%" "$RAM_USAGE_VAL")
            if [ "$RAM_USAGE_VAL" -ge 90 ]; then
                [ "$BLINK_STATE" -eq 0 ] && TEXT_COLOR="$COLOR_DANGER" || TEXT_COLOR="$COLOR_RESET"
                ICON_CLR="$COLOR_DANGER"
            elif [ "$RAM_USAGE_VAL" -ge 70 ]; then
                TEXT_COLOR="$COLOR_WARN"; ICON_CLR="$COLOR_WARN"
            else
                TEXT_COLOR="$COLOR_RESET"; ICON_CLR="$COLOR_SAFE"
            fi
            ICON="%{T4}${ICON_CLR}${ICON_RAM_CHAR}${COLOR_RESET}%{T-}"
            if [ "$STATE" == "full" ]; then
                echo "${ICON}${TEXT_COLOR} ${RAM_USAGE} ($TOTAL_RAM)${COLOR_RESET}"
            else
                echo "${ICON}"
            fi
            ;;

        1) # CPU & Temp
            CPU_USAGE=$(printf "%2d%%" "$CPU_USAGE_VAL")
            TEMP_C=$(printf "%2d°C" "$TEMP_C_VAL")
            
            if [ "$CPU_USAGE_VAL" -ge 90 ] || [ "$TEMP_C_VAL" -ge 80 ]; then
                [ "$BLINK_STATE" -eq 0 ] && TEXT_COLOR="$COLOR_DANGER" || TEXT_COLOR="$COLOR_RESET"
            elif [ "$CPU_USAGE_VAL" -ge 70 ] || [ "$TEMP_C_VAL" -ge 60 ]; then
                TEXT_COLOR="$COLOR_WARN"
            else
                TEXT_COLOR="$COLOR_RESET"
            fi
            
            if [ "$CPU_USAGE_VAL" -ge 90 ]; then CLR_CPU="$COLOR_DANGER"; elif [ "$CPU_USAGE_VAL" -ge 70 ]; then CLR_CPU="$COLOR_WARN"; else CLR_CPU="$COLOR_SAFE"; fi
            if [ "$TEMP_C_VAL" -ge 80 ]; then CLR_TEMP="$COLOR_DANGER"; elif [ "$TEMP_C_VAL" -ge 60 ]; then CLR_TEMP="$COLOR_WARN"; else CLR_TEMP="$COLOR_SAFE"; fi

            ICON_CPU="%{T4}${CLR_CPU}${ICON_CPU_CHAR}${COLOR_RESET}%{T-}"
            ICON_TEMP="%{T4}${CLR_TEMP}${ICON_TEMP_CHAR}${COLOR_RESET}%{T-}"
            if [ "$STATE" == "full" ]; then
                echo "${ICON_CPU}${TEXT_COLOR} ${CPU_USAGE} ${ICON_TEMP}${TEXT_COLOR} ${TEMP_C}${COLOR_RESET}"
            else
                echo "${ICON_CPU} ${ICON_TEMP}"
            fi
            ;;

        2) # Filesystem
            FS_USAGE=$(printf "%2d%%" "$FS_USAGE_VAL")
            if [ "$FS_USAGE_VAL" -ge 90 ]; then
                [ "$BLINK_STATE" -eq 0 ] && TEXT_COLOR="$COLOR_DANGER" || TEXT_COLOR="$COLOR_RESET"
                ICON_CLR="$COLOR_DANGER"
            elif [ "$FS_USAGE_VAL" -ge 70 ]; then
                TEXT_COLOR="$COLOR_WARN"; ICON_CLR="$COLOR_WARN"
            else
                TEXT_COLOR="$COLOR_RESET"; ICON_CLR="$COLOR_SAFE"
            fi
            ICON="%{T4}${ICON_CLR}${ICON_FS_CHAR}${COLOR_RESET}%{T-}"
            if [ "$STATE" == "full" ]; then
                echo "${ICON}${TEXT_COLOR} / ${FS_USAGE} ($FS_TOTAL)${COLOR_RESET}"
            else
                echo "${ICON}"
            fi
            ;;
    esac

    sleep 1
done
