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
if zenity --question --text "Do you want to load the Professional Workspace Preset?\n(Web, Code, Terminal, Chat, Design, Video, Office, PKM)" --title "Workspace Setup"; then
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