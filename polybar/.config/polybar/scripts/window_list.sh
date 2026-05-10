#!/bin/bash

# Define Rofi Theme
THEME="window { width: 60%; border: 0px; border-radius: 20px; background-color: #282a2e; } 
       listview { fixed-height: false; lines: 15; }
       element { padding: 10px; background-color: transparent; }
       element-text { font: \"JetBrainsMono Nerd Font 14\"; text-color: #c5c8c6; }
       element selected { background-color: #61afef; }
       element-text selected { text-color: #282a2e; }
       inputbar { enabled: true; padding: 10px; }"

# 1. Get monitor info from xfconf
MONITORS=()
while read -r line; do
    # Extract monitor name from path like /Default/eDP-1/Active
    MON_NAME=$(echo "$line" | cut -d' ' -f1 | cut -d'/' -f3)
    
    # Get properties
    MON_X=$(xfconf-query -c displays -p "/Default/$MON_NAME/Position/X" 2>/dev/null || echo 0)
    MON_Y=$(xfconf-query -c displays -p "/Default/$MON_NAME/Position/Y" 2>/dev/null || echo 0)
    MON_RES=$(xfconf-query -c displays -p "/Default/$MON_NAME/Resolution" 2>/dev/null || echo "1920x1080")
    MON_W=$(echo $MON_RES | cut -dx -f1)
    MON_H=$(echo $MON_RES | cut -dx -f2)
    
    # Get friendly name if possible
    FRIENDLY_NAME=$(xfconf-query -c displays -p "/Default/$MON_NAME" 2>/dev/null | head -n 1)
    [ -z "$FRIENDLY_NAME" ] && FRIENDLY_NAME="$MON_NAME"
    
    MONITORS+=("$MON_X:$MON_Y:$MON_W:$MON_H:$FRIENDLY_NAME")
done < <(xfconf-query -c displays -p /Default -lv | grep "/Active" | grep "true")

# 2. Get workspace names
WS_NAMES=()
# Parse xprop output for desktop names
NAMES_STR=$(xprop -root _NET_DESKTOP_NAMES | cut -d= -f2)
IFS=',' read -r -a WS_NAMES_RAW <<< "$NAMES_STR"
for name in "${WS_NAMES_RAW[@]}"; do
    # Remove quotes and surrounding whitespace
    clean_name=$(echo "$name" | sed 's/^ "//;s/"$//;s/^[[:space:]]*//;s/[[:space:]]*$//')
    WS_NAMES+=("$clean_name")
done

# 3. Get windows geometry and info
# Format: ID WS PID X Y W H HOST TITLE
WINDOWS_DATA=$(wmctrl -lpG)
OPTIONS=""
declare -A ID_MAP

# 4. Grouping Logic
for mon in "${MONITORS[@]}"; do
    IFS=':' read -r MX MY MW MH MNAME <<< "$mon"
    
    # We loop through WS -1 (All Workspaces) first, then 0 to N
    for ws_idx in -1 "${!WS_NAMES[@]}"; do
        if [ "$ws_idx" == "-1" ]; then
            WS_NAME="Global / Sticky"
        else
            WS_NAME="${WS_NAMES[$ws_idx]}"
            [ -z "$WS_NAME" ] && WS_NAME="WS $((ws_idx + 1))"
        fi
        
        GROUP_CONTENT=""
        
        while read -r line; do
            # Fields: W_ID, W_WS, PID, W_X, W_Y, W_W, W_H, HOST, TITLE...
            read -r W_ID W_WS PID W_X W_Y W_W W_H HOST W_TITLE <<< "$line"
            
            # Match Workspace
            [ "$W_WS" != "$ws_idx" ] && continue
            
            # Match Monitor (Center point of window)
            W_CX=$((W_X + W_W / 2))
            W_CY=$((W_Y + W_H / 2))
            
            if (( W_CX >= MX && W_CX < MX + MW && W_CY >= MY && W_CY < MY + MH )); then
                # Skip taskbar windows (Polybar, panels, etc.)
                SKIP=$(xprop -id "$W_ID" _NET_WM_STATE | grep "SKIP_TASKBAR")
                [ -n "$SKIP" ] && continue
                
                # Get elapsed time
                TIME_STR=$(ps -p "$PID" -o etime= 2>/dev/null | tr -d ' ' | sed 's/^[0:]*//')
                [ -z "$TIME_STR" ] && TIME_STR="0s"
                
                # Format window entry
                # We use a unique icon per screen type or just a generic one
                ICON=""
                [[ "$MNAME" =~ "Laptop" ]] && ICON="󰌢"
                [[ "$MNAME" =~ "HP" ]] && ICON="󰍹"
                
                # Truncate title for readability
                SHORT_TITLE="${W_TITLE:0:60}"
                [ "${#W_TITLE}" -gt 60 ] && SHORT_TITLE="${SHORT_TITLE}..."
                
                DISPLAY_STR=$(printf "  <span color='#61afef'>%s</span>  %-65s <span color='#707880'>[%s]</span>" "$ICON" "$SHORT_TITLE" "$TIME_STR")
                GROUP_CONTENT+="$DISPLAY_STR\n"
                ID_MAP["$DISPLAY_STR"]="$W_ID"
            fi
        done <<< "$WINDOWS_DATA"
        
        if [ -n "$GROUP_CONTENT" ]; then
            # Header format: bold with background
            HEADER="<span background='#3e4452' color='#61afef' weight='bold'> 󰥵 Application on WS $WS_NAME Screen $MNAME </span>"
            OPTIONS+="$HEADER\n$GROUP_CONTENT"
        fi
    done
done

# 5. Show Rofi
CHOICE=$(echo -e "$OPTIONS" | rofi -dmenu -markup-rows -p "Switch to:" -theme-str "$THEME" -i)

# 6. Action
if [ -n "$CHOICE" ]; then
    W_ID="${ID_MAP["$CHOICE"]}"
    if [ -n "$W_ID" ]; then
        wmctrl -ia "$W_ID"
    fi
fi
