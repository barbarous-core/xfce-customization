#!/bin/bash

STATE_FILE="/tmp/polybar_minimal_state"

if [ -f "$STATE_FILE" ]; then
    rm "$STATE_FILE"
else
    touch "$STATE_FILE"
fi

# Reload Polybar with the current config
# Since launch.sh now checks for the state file, it will toggle the modules.
bash "$HOME/.config/polybar/launch.sh" --last
