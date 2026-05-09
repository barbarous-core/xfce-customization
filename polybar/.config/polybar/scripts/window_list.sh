#!/bin/bash

# Define Rofi Theme (Consistent with OSD and Startup)
THEME="window { width: 60%; border: 0px; border-radius: 20px; background-color: #282a2e; } 
       listview { fixed-height: false; }
       element { padding: 10px; background-color: transparent; }
       element-text { font: \"JetBrainsMono Nerd Font 14\"; text-color: #c5c8c6; }
       element selected { background-color: #61afef; }
       element-text selected { text-color: #282a2e; }
       inputbar { enabled: true; padding: 10px; }"

# Function to convert seconds to human readable time
fmt_time() {
    local T=$1
    local H=$((T/60/60))
    local M=$((T/60%60))
    local S=$((T%60))
    
    if [ $H -gt 0 ]; then
        echo "${H}h ${M}m"
    else
        echo "${M}m ${S}s"
    fi
}

# 1. Get current workspace index
CURRENT_WS=$(xprop -root _NET_CURRENT_DESKTOP | awk '{print $3}')

# 2. Get window list with PIDs and IDs
# Format: WindowID DesktopID PID Hostname Title
WINDOWS=$(wmctrl -lp)

OPTIONS=""
declare -A ID_MAP

while read -r line; do
    # Correctly parse the fields: ID, WS, PID, HOST, and then TITLE
    read -r W_ID W_WS PID HOST TITLE <<< "$line"
    
    # Filter: Only show windows on the current workspace
    if [ "$W_WS" != "$CURRENT_WS" ] && [ "$W_WS" != "-1" ]; then
        continue
    fi
    
    # Filter: Skip windows that are set to skip the taskbar (like Polybar, panels, etc.)
    SKIP=$(xprop -id "$W_ID" _NET_WM_STATE | grep "SKIP_TASKBAR")
    if [ -n "$SKIP" ]; then
        continue
    fi
    
    # Get the elapsed time directly using the user's suggested 'etime' command
    TIME_STR=$(ps -p "$PID" -o etime= 2>/dev/null | tr -d ' ')
    
    if [ -n "$TIME_STR" ]; then
        # Format: [Time]  Title
        DISPLAY_STR=$(printf "<span color='#707880'>[%-8.8s]</span>  %s" "$TIME_STR" "$TITLE")
        OPTIONS+="$DISPLAY_STR\n"
        ID_MAP["$DISPLAY_STR"]="$W_ID"
    fi
done <<< "$WINDOWS"

# 2. Show Rofi
CHOICE=$(echo -e "$OPTIONS" | rofi -dmenu -markup-rows -p "Switch to:" -theme-str "$THEME" -i)

# 3. Focus the selected window
if [ -n "$CHOICE" ]; then
    W_ID="${ID_MAP["$CHOICE"]}"
    wmctrl -ia "$W_ID"
fi
