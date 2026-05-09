#!/bin/bash

# Terminate already running bar instances
killall -q polybar

# Wait until the processes have been shut down
while pgrep -u $UID -x polybar >/dev/null; do sleep 1; done

# Launch bar(s)
# The following line launches the bar for the primary display
# Use the config file in the same directory as the script
CONFIG_DIR="$(dirname "$(realpath "$0")")"
polybar -c "$CONFIG_DIR/config.ini" main & 

# Launch workspace notifier
pkill -f ws_notifier.sh
"$CONFIG_DIR/scripts/ws_notifier.sh" &

# Optional: To launch on a second display, uncomment the following line
# polybar secondary & 

echo "Bars launched..."