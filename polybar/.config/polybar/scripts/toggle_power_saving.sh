#!/bin/bash

STATE_FILE="/tmp/polybar_power_saving"

if [ -f "$STATE_FILE" ]; then
    rm "$STATE_FILE"
    notify-send "Polybar" "Power Saving Mode: OFF (Normal Refresh)" --icon=battery
else
    touch "$STATE_FILE"
    notify-send "Polybar" "Power Saving Mode: ON (Long Refresh / No Animation)" --icon=battery-caution
fi

# Reload Polybar to apply interval changes
bash /home/mohamed/Linux_Data/Git_Projects/xfce-customization/polybar/.config/polybar/launch.sh --last
