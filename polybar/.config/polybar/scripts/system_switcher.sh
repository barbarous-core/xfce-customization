#!/bin/bash

# Icons
ICON_RAM=$(echo -e "%{F#F0C674}%{T4}\uefc5%{T-}%{F-}")
ICON_CPU="%{F#F0C674}%{T4}%{T-}%{F-}"
ICON_TEMP="%{F#F0C674}%{T4}%{T-}%{F-}"
ICON_FS="%{F#F0C674}%{T4}󰋊%{T-}%{F-}"

# Fixed length to prevent bar jumping
FIXED_LEN=17

while true; do
    # --- Frame 1: Memory ---
    RAM_INFO=$(free -h | grep Mem)
    RAM_USAGE=$(free | grep Mem | awk '{print int($3/$2 * 100.0)}')
    TOTAL_RAM=$(echo "$RAM_INFO" | awk '{print $2}' | sed 's/Gi/GB/')
    
    MEM_TEXT=" ${RAM_USAGE}% ($TOTAL_RAM)"
    MEM_OUTPUT=$(printf "%-${FIXED_LEN}s" "$MEM_TEXT")
    echo "${ICON_RAM}${MEM_OUTPUT}"
    sleep 5
    
    # --- Frame 2: CPU & Temp ---
    CPU_USAGE=$(top -bn1 | grep "Cpu(s)" | sed "s/.*, *\([0-9.]*\)%* id.*/\1/" | awk '{print 100 - $1}')
    CPU_INT=${CPU_USAGE%.*}
    
    TEMP=$(cat /sys/class/thermal/thermal_zone0/temp 2>/dev/null || echo 0)
    TEMP_C=$((TEMP / 1000))
    
    CPU_TEXT=" ${CPU_INT}%  ${ICON_TEMP} ${TEMP_C}°C"
    echo "${ICON_CPU}${CPU_TEXT}    "
    sleep 5
    
    # --- Frame 3: Filesystem ---
    FS_INFO=$(df -h / | awk 'NR==2')
    FS_USAGE=$(echo "$FS_INFO" | awk '{print $5}')
    FS_TOTAL=$(echo "$FS_INFO" | awk '{print $2}' | sed 's/G/GB/')
    
    FS_TEXT=" / ${FS_USAGE} ($FS_TOTAL)"
    FS_OUTPUT=$(printf "%-${FIXED_LEN}s" "$FS_TEXT")
    echo "${ICON_FS}${FS_OUTPUT}"
    sleep 5
done
