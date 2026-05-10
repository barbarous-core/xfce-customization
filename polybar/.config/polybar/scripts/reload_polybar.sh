#!/bin/bash

# Path to your launch script
LAUNCH_SCRIPT="/home/mohamed/Linux_Data/Git_Projects/xfce-customization/polybar/.config/polybar/launch.sh"

# Show confirmation dialog using YAD
yad --title="Polybar Reload" \
    --text="Do you want to reload Polybar?" \
    --button="No:1" \
    --button="Yes:0" \
    --center \
    --width=300 \
    --fixed \
    --window-icon="view-refresh"

# Check exit status (0 is Yes)
if [ $? -eq 0 ]; then
    bash "$LAUNCH_SCRIPT"
fi
