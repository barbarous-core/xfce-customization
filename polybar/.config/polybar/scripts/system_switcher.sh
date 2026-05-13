#!/bin/bash

# Configuration
GLOBAL_STATE_FILE="/tmp/polybar_active_module"

# Fetch theme colors from polybar colors.ini
SUCCESS_COLOR=$(grep "^success =" "$HOME/.config/polybar/colors.ini" | cut -d' ' -f3 || echo "#70af1e")
WARNING_COLOR=$(grep "^warning =" "$HOME/.config/polybar/colors.ini" | cut -d' ' -f3 || echo "#f0c674")
ALERT_COLOR=$(grep "^alert =" "$HOME/.config/polybar/colors.ini" | cut -d' ' -f3 || echo "#A54242")

COLOR_SAFE="%{F$SUCCESS_COLOR}"
COLOR_WARN="%{F$WARNING_COLOR}"
COLOR_DANGER="%{F$ALERT_COLOR}"
COLOR_RESET="%{F-}"

# Icons
ICON_RAM_CHAR=$(echo -e "\uefc5")
ICON_CPU_CHAR=$(echo -e "\uf4bc")
ICON_TEMP_CHAR=$(echo -e "\uf2c7")
ICON_FS_CHAR=$(echo -e "\U000f02ca")

# --- Cache thermal zone path once ---
TEMP_PATH=$(grep -l "x86_pkg_temp" /sys/class/thermal/thermal_zone*/type 2>/dev/null | head -n1)
if [ -n "$TEMP_PATH" ]; then
    TEMP_PATH="${TEMP_PATH%type}temp"
else
    TEMP_PATH="/sys/class/thermal/thermal_zone0/temp"
fi

# --- Initialize CPU measurement ---
read -r _ PREV_USER PREV_NICE PREV_SYSTEM PREV_IDLE PREV_IOWAIT PREV_IRQ PREV_SOFTIRQ _ < /proc/stat
PREV_TOTAL=$((PREV_USER + PREV_NICE + PREV_SYSTEM + PREV_IDLE + PREV_IOWAIT + PREV_IRQ + PREV_SOFTIRQ))
PREV_IDLE_ALL=$((PREV_IDLE + PREV_IOWAIT))

while true; do
    # 1. Gather all data
    # RAM
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

    # CPU
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

    # Temp
    TEMP=$(cat "$TEMP_PATH" 2>/dev/null || echo 0)
    TEMP_C_VAL=$((TEMP / 1000))

    # FS
    read -r FS_USAGE_VAL FS_TOTAL <<< "$(df -h / | awk 'NR==2 { gsub(/%/,"",$5); print $5, $2 }')"

    # 2. Check global state
    ACTIVE_MODULE=$(cat "$GLOBAL_STATE_FILE" 2>/dev/null || echo "none")

    # 3. Determine Colors
    if [ "$CPU_USAGE_VAL" -ge 90 ]; then CLR_CPU="$COLOR_DANGER"; elif [ "$CPU_USAGE_VAL" -ge 70 ]; then CLR_CPU="$COLOR_WARN"; else CLR_CPU="$COLOR_SAFE"; fi
    if [ "$TEMP_C_VAL" -ge 80 ]; then CLR_TEMP="$COLOR_DANGER"; elif [ "$TEMP_C_VAL" -ge 60 ]; then CLR_TEMP="$COLOR_WARN"; else CLR_TEMP="$COLOR_SAFE"; fi
    if [ "$RAM_USAGE_VAL" -ge 90 ]; then CLR_RAM="$COLOR_DANGER"; elif [ "$RAM_USAGE_VAL" -ge 70 ]; then CLR_RAM="$COLOR_WARN"; else CLR_RAM="$COLOR_SAFE"; fi
    if [ "$FS_USAGE_VAL" -ge 90 ]; then CLR_FS="$COLOR_DANGER"; elif [ "$FS_USAGE_VAL" -ge 70 ]; then CLR_FS="$COLOR_WARN"; else CLR_FS="$COLOR_SAFE"; fi

    ICON_CPU="%{T4}${CLR_CPU}${ICON_CPU_CHAR}${COLOR_RESET}%{T-}"
    ICON_TEMP="%{T4}${CLR_TEMP}${ICON_TEMP_CHAR}${COLOR_RESET}%{T-}"
    ICON_RAM="%{T4}${CLR_RAM}${ICON_RAM_CHAR}${COLOR_RESET}%{T-}"
    ICON_FS="%{T4}${CLR_FS}${ICON_FS_CHAR}${COLOR_RESET}%{T-}"

    if [ "$ACTIVE_MODULE" == "system" ]; then
        # Expanded view
        CPU_OUT="${ICON_CPU} ${CPU_USAGE_VAL}%"
        TEMP_OUT="${ICON_TEMP} ${TEMP_C_VAL}°C"
        RAM_OUT="${ICON_RAM} ${RAM_USAGE_VAL}%"
        FS_OUT="${ICON_FS} ${FS_USAGE_VAL}%"
        echo "${CPU_OUT}  ${TEMP_OUT}  ${RAM_OUT}  ${FS_OUT}"
    else
        # Collapsed view (all icons)
        echo "${ICON_CPU} ${ICON_TEMP} ${ICON_RAM} ${ICON_FS}"
    fi

    sleep 1
done
