#!/bin/bash

# Terminate already running bar instances
killall -q polybar

# Wait until the processes have been shut down
while pgrep -u $UID -x polybar >/dev/null; do sleep 1; done

# Launch bar(s)
# The following line launches the bar for the primary display
# Use the config file in the same directory as the script
CONFIG_DIR="$(dirname "$(realpath "$0")")"
# Ask to load presets
# Define Rofi Theme for Startup
THEME="window { width: 33%; border: 0px; border-radius: 20px; background-color: #282a2e; } 
       listview { lines: 2; }
       element { padding: 15px; background-color: transparent; }
       element-text { font: \"JetBrainsMono Nerd Font 18\"; horizontal-align: 0.5; text-color: #c5c8c6; }
       element selected { background-color: #61afef; }
       element-text selected { text-color: #282a2e; }
       inputbar { enabled: false; }"

# Ask to load presets using Rofi
YES_OPT="🚀 Load Productivity WS presets"
NO_OPT="🧹 Clean Slate (Only one WS)"
OPTIONS="${YES_OPT}\n${NO_OPT}"
CHOICE=$(echo -e "$OPTIONS" | rofi -dmenu -p "Workspace Setup" -theme-str "$THEME" -location 0 -monitor -1 -pid /tmp/rofi_startup.pid)

if [ "$CHOICE" == "$YES_OPT" ]; then
    # Load Preset: 9 workspaces starting with 'free workspace'
    xfconf-query -c xfwm4 -p /general/workspace_count -s 9
    xfconf-query -c xfwm4 -p /general/workspace_names -r
    xfconf-query -c xfwm4 -p /general/workspace_names -n \
        -t string -s "free workspace" \
        -t string -s "🌐 Web" \
        -t string -s " Code" \
        -t string -s " Terminal" \
        -t string -s " Chat" \
        -t string -s "🎨 Design" \
        -t string -s "🎬 Video" \
        -t string -s " Office" \
        -t string -s " PKM"
else
    # RESET: Keep only 1 workspace named "free workspace"
    xfconf-query -c xfwm4 -p /general/workspace_count -s 1
    xfconf-query -c xfwm4 -p /general/workspace_names -r
    xfconf-query -c xfwm4 -p /general/workspace_names -n -t string -s "free workspace"
fi

polybar -c "$CONFIG_DIR/config.ini" main & 

# Launch workspace notifier
pkill -f ws_notifier.sh
"$CONFIG_DIR/scripts/ws_notifier.sh" &

# Optional: To launch on a second display, uncomment the following line
# polybar secondary & 

echo "Bars launched..."