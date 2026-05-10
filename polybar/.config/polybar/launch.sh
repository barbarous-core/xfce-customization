#!/bin/bash

# Terminate already running bar instances
killall -q polybar

# Wait until the processes have been shut down
while pgrep -u $UID -x polybar >/dev/null; do sleep 1; done

# Launch bar(s)
# The following line launches the bar for the primary display
# Use the config file in the same directory as the script
CONFIG_DIR="$(dirname "$(realpath "$0")")"

# Show display layout visualization
# If user clicks Display Settings, it returns 2, and we restart the check
while true; do
    chmod +x "$CONFIG_DIR/scripts/show_layout.sh"
    "$CONFIG_DIR/scripts/show_layout.sh"
    if [ $? -eq 2 ]; then
        continue
    else
        break
    fi
done

# Ask to load presets
chmod +x "$CONFIG_DIR/scripts/ws_presets.sh"
"$CONFIG_DIR/scripts/ws_presets.sh"


polybar -c "$CONFIG_DIR/config.ini" main & 

# Launch workspace notifier
pkill -f ws_notifier.sh
"$CONFIG_DIR/scripts/ws_notifier.sh" &

echo "Bars launched..."