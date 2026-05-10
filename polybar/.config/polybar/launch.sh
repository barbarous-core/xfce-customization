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

# 2. Detect monitors and ask for bar positions & modules
chmod +x "$CONFIG_DIR/scripts/bar_config.sh"
chmod +x "$CONFIG_DIR/scripts/bar_modules.sh"

# Get Monitor Status
HDMI_ACTIVE=$(xfconf-query -c displays -p "/Default/HDMI-1/Active" 2>/dev/null)
EDP_ACTIVE=$(xfconf-query -c displays -p "/Default/eDP-1/Active" 2>/dev/null)

# --- HDMI-1 (Principal) ---
if [ "$HDMI_ACTIVE" == "true" ]; then
    # Ask Position
    POS_H=$(bash "$CONFIG_DIR/scripts/bar_config.sh" "HDMI-1" "External HP 23\"")
    # Ask Modules
    MODS_H=$(bash "$CONFIG_DIR/scripts/bar_modules.sh" "External HP 23\"")
fi

# --- eDP-1 (Laptop) ---
if [ "$EDP_ACTIVE" == "true" ]; then
    # Ask Position
    POS_E=$(bash "$CONFIG_DIR/scripts/bar_config.sh" "eDP-1" "Laptop Screen")
    # Ask Modules
    MODS_E=$(bash "$CONFIG_DIR/scripts/bar_modules.sh" "Laptop Screen")
fi

# 3. Ask for workspace presets
chmod +x "$CONFIG_DIR/scripts/ws_presets.sh"
"$CONFIG_DIR/scripts/ws_presets.sh"

# 4. Final Launch
# Launch HDMI-1
if [ "$HDMI_ACTIVE" == "true" ] && [ "$MODS_H" != "DISABLED" ]; then
    LEFT=$(echo "$MODS_H" | cut -d'|' -f1)
    CENTER=$(echo "$MODS_H" | cut -d'|' -f2)
    RIGHT=$(echo "$MODS_H" | cut -d'|' -f3)
    
    MONITOR=HDMI-1 POLYBAR_BOTTOM=$POS_H \
    POLYBAR_LEFT="$LEFT" POLYBAR_CENTER="$CENTER" POLYBAR_RIGHT="$RIGHT" \
    polybar -c "$CONFIG_DIR/config.ini" main &
fi

# Launch eDP-1
if [ "$EDP_ACTIVE" == "true" ] && [ "$MODS_E" != "DISABLED" ]; then
    LEFT=$(echo "$MODS_E" | cut -d'|' -f1)
    CENTER=$(echo "$MODS_E" | cut -d'|' -f2)
    RIGHT=$(echo "$MODS_E" | cut -d'|' -f3)
    
    MONITOR=eDP-1 POLYBAR_BOTTOM=$POS_E \
    POLYBAR_LEFT="$LEFT" POLYBAR_CENTER="$CENTER" POLYBAR_RIGHT="$RIGHT" \
    polybar -c "$CONFIG_DIR/config.ini" main &
fi

# Launch workspace notifier
pkill -f ws_notifier.sh
"$CONFIG_DIR/scripts/ws_notifier.sh" &

echo "Bars launched..."