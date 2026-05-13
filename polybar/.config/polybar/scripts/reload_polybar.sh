#!/bin/bash

# Paths
LAUNCH_SCRIPT="$HOME/.config/polybar/launch.sh"
YAD_STYLE="$HOME/.config/yad/style.css"

# Sync YAD theme before showing dialog
bash "$HOME/.config/polybar/scripts/sync_yad_theme.sh"

# Show simple confirmation dialog
yad --title="Polybar Reload" \
    --class="PolybarDialog" \
    --text="Do you want to reload Polybar?" \
    --window-icon="view-refresh" \
    --button="No:1" \
    --button="Yes (New Config):3" \
    --button="Yes (Last Config):0" \
    --default-button=0 \
    --center \
    --width=450 \
    --fixed \
    --undecorated \
    --skip-taskbar \
    --css="$YAD_STYLE" \
    --fontname="JetBrainsMono Nerd Font 11"

EXIT_CODE=$?

# Check exit status
if [ $EXIT_CODE -eq 0 ]; then
    notify-send "Polybar" "Reloading Last Config..."
    bash "$LAUNCH_SCRIPT" --last
elif [ $EXIT_CODE -eq 3 ]; then
    notify-send "Polybar" "Starting New Configuration..."
    bash "$LAUNCH_SCRIPT" --new
else
    notify-send "Polybar" "Reload Cancelled"
fi
