#!/bin/bash

# Terminate already running bar instances
killall -q polybar

# Wait until the processes have been shut down
while pgrep -u $UID -x polybar >/dev/null; do sleep 1; done

# CONFIG DIR
CONFIG_DIR="$(dirname "$(realpath "$0")")"

# 1. Show display layout visualization first (Wait for user OK)
chmod +x "$CONFIG_DIR/scripts/show_layout.sh"
while true; do
    "$CONFIG_DIR/scripts/show_layout.sh"
    if [ $? -eq 2 ]; then
        continue
    else
        break
    fi
done

# 2. Detect monitors and ask for bar positions
chmod +x "$CONFIG_DIR/scripts/bar_config.sh"

# Get Monitor Status
HDMI_ACTIVE=$(xfconf-query -c displays -p "/Default/HDMI-1/Active" 2>/dev/null)
EDP_ACTIVE=$(xfconf-query -c displays -p "/Default/eDP-1/Active" 2>/dev/null)

# Ask for HDMI-1 (Principal)
if [ "$HDMI_ACTIVE" == "true" ]; then
    POS_H=$(bash "$CONFIG_DIR/scripts/bar_config.sh" "HDMI-1" "External HP 23\"")
fi

# Ask for eDP-1 (Laptop)
if [ "$EDP_ACTIVE" == "true" ]; then
    POS_E=$(bash "$CONFIG_DIR/scripts/bar_config.sh" "eDP-1" "Laptop Screen")
fi

# 3. Ask for workspace presets
chmod +x "$CONFIG_DIR/scripts/ws_presets.sh"
"$CONFIG_DIR/scripts/ws_presets.sh"

# 4. Final Launch
if [ "$HDMI_ACTIVE" == "true" ]; then
    MONITOR=HDMI-1 POLYBAR_BOTTOM=$POS_H polybar -c "$CONFIG_DIR/config.ini" main &
fi

if [ "$EDP_ACTIVE" == "true" ]; then
    MONITOR=eDP-1 POLYBAR_BOTTOM=$POS_E polybar -c "$CONFIG_DIR/config.ini" main &
fi

# Launch workspace notifier
pkill -f ws_notifier.sh
"$CONFIG_DIR/scripts/ws_notifier.sh" &

echo "Bars launched..."