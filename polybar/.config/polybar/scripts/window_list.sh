#!/bin/bash

# Configuration
COLORS_FILE="/home/mohamed/Linux_Data/Git_Projects/xfce-customization/polybar/.config/polybar/colors.ini"

# Get colors from colors.ini
BG=$(grep "background =" "$COLORS_FILE" | cut -d' ' -f3)
BG_ALT=$(grep "background-alt =" "$COLORS_FILE" | cut -d' ' -f3)
FG=$(grep "foreground =" "$COLORS_FILE" | cut -d' ' -f3)
PRIMARY=$(grep "primary =" "$COLORS_FILE" | cut -d' ' -f3)
DISABLED=$(grep "disabled =" "$COLORS_FILE" | cut -d' ' -f3)

# Define Rofi Theme
THEME="window { width: 60%; border: 2px; border-color: $PRIMARY; border-radius: 20px; background-color: $BG; } 
       listview { fixed-height: false; lines: 15; }
       element { padding: 10px; background-color: transparent; }
       element-text { font: \"JetBrainsMono Nerd Font 14\"; text-color: $FG; }
       element selected { background-color: $PRIMARY; }
       element-text selected { text-color: $BG; }
       inputbar { enabled: true; padding: 10px; }"

# 1. Get monitor info from xfconf
MONITORS=()
while read -r line; do
    MON_NAME=$(echo "$line" | cut -d' ' -f1 | cut -d'/' -f3)
    MON_X=$(xfconf-query -c displays -p "/Default/$MON_NAME/Position/X" 2>/dev/null || echo 0)
    MON_Y=$(xfconf-query -c displays -p "/Default/$MON_NAME/Position/Y" 2>/dev/null || echo 0)
    MON_RES=$(xfconf-query -c displays -p "/Default/$MON_NAME/Resolution" 2>/dev/null || echo "1920x1080")
    MON_W=$(echo $MON_RES | cut -dx -f1)
    MON_H=$(echo $MON_RES | cut -dx -f2)
    FRIENDLY_NAME=$(xfconf-query -c displays -p "/Default/$MON_NAME" 2>/dev/null | head -n 1)
    [ -z "$FRIENDLY_NAME" ] && FRIENDLY_NAME="$MON_NAME"
    MONITORS+=("$MON_X:$MON_Y:$MON_W:$MON_H:$FRIENDLY_NAME")
done < <(xfconf-query -c displays -p /Default -lv | grep "/Active" | grep "true")

# 2. Get workspace names
WS_NAMES=()
NAMES_STR=$(xprop -root _NET_DESKTOP_NAMES | cut -d= -f2)
IFS=',' read -r -a WS_NAMES_RAW <<< "$NAMES_STR"
for name in "${WS_NAMES_RAW[@]}"; do
    clean_name=$(echo "$name" | sed 's/^ "//;s/"$//;s/^[[:space:]]*//;s/[[:space:]]*$//')
    WS_NAMES+=("$clean_name")
done

# 3. Get windows geometry and info
WINDOWS_DATA=$(wmctrl -lpG)
OPTIONS=""
declare -A ID_MAP

# 4. Grouping Logic
for mon in "${MONITORS[@]}"; do
    IFS=':' read -r MX MY MW MH MNAME <<< "$mon"
    for ws_idx in -1 "${!WS_NAMES[@]}"; do
        if [ "$ws_idx" == "-1" ]; then
            WS_NAME="Global / Sticky"
        else
            WS_NAME="${WS_NAMES[$ws_idx]}"
            [ -z "$WS_NAME" ] && WS_NAME="WS $((ws_idx + 1))"
        fi
        GROUP_CONTENT=""
        while read -r line; do
            read -r W_ID W_WS PID W_X W_Y W_W W_H HOST W_TITLE <<< "$line"
            [ "$W_WS" != "$ws_idx" ] && continue
            W_CX=$((W_X + W_W / 2))
            W_CY=$((W_Y + W_H / 2))
            if (( W_CX >= MX && W_CX < MX + MW && W_CY >= MY && W_CY < MY + MH )); then
                SKIP=$(xprop -id "$W_ID" _NET_WM_STATE | grep "SKIP_TASKBAR")
                [ -n "$SKIP" ] && continue
                TIME_STR=$(ps -p "$PID" -o etime= 2>/dev/null | tr -d ' ' | sed 's/^[0:]*//')
                [ -z "$TIME_STR" ] && TIME_STR="0s"
                ICON=""
                [[ "$MNAME" =~ "Laptop" ]] && ICON="󰌢"
                [[ "$MNAME" =~ "HP" ]] && ICON="󰍹"
                SHORT_TITLE="${W_TITLE:0:60}"
                [ "${#W_TITLE}" -gt 60 ] && SHORT_TITLE="${SHORT_TITLE}..."
                
                DISPLAY_STR=$(printf "  <span color='$PRIMARY'>%s</span>  %-65s <span color='$DISABLED'>[%s]</span>" "$ICON" "$SHORT_TITLE" "$TIME_STR")
                GROUP_CONTENT+="$DISPLAY_STR\n"
                ID_MAP["$DISPLAY_STR"]="$W_ID"
            fi
        done <<< "$WINDOWS_DATA"
        if [ -n "$GROUP_CONTENT" ]; then
            HEADER="<span background='$BG_ALT' color='$PRIMARY' weight='bold'> 󰥵 Application on WS $WS_NAME Screen $MNAME </span>"
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
