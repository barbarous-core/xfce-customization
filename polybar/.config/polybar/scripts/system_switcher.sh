#!/bin/bash

# Icons
ICON_RAM=$(echo -e "%{F#F0C674}%{T4}\uefc5%{T-}%{F-}")
ICON_CPU="%{F#F0C674}%{T4}%{T-}%{F-}"
ICON_TEMP="%{F#F0C674}%{T4}%{T-}%{F-}"

# Reduced fixed length to avoid excessive trailing space
# " RAM 100% (100GB)" is 16 chars. So 17 is a safe tight limit.
FIXED_LEN=17

while true; do
    # --- Frame 1: Memory ---
    RAM_INFO=$(free -h | grep Mem)
    RAM_USAGE=$(free | grep Mem | awk '{print int($3/$2 * 100.0)}')
    TOTAL_RAM=$(echo "$RAM_INFO" | awk '{print $2}' | sed 's/Gi/GB/')
    
    MEM_TEXT=" RAM ${RAM_USAGE}% ($TOTAL_RAM)"
    # Pad to match FIXED_LEN exactly
    MEM_OUTPUT=$(printf "%-${FIXED_LEN}s" "$MEM_TEXT")
    
    echo "${ICON_RAM}${MEM_OUTPUT}"
    sleep 5
    
    # --- Frame 2: CPU & Temp ---
    CPU_USAGE=$(top -bn1 | grep "Cpu(s)" | sed "s/.*, *\([0-9.]*\)%* id.*/\1/" | awk '{print 100 - $1}')
    CPU_INT=${CPU_USAGE%.*}
    
    TEMP=$(cat /sys/class/thermal/thermal_zone0/temp 2>/dev/null || echo 0)
    TEMP_C=$((TEMP / 1000))
    
    # " 10%  T 45°C" -> 13 chars. 
    # We add 4 spaces to reach 17.
    CPU_TEXT=" ${CPU_INT}%  ${ICON_TEMP} ${TEMP_C}°C"
    echo "${ICON_CPU}${CPU_TEXT}    "
    sleep 5
done
