#!/bin/bash

STATE_FILE="/tmp/polybar_mini_pos"

# Default state: bottom|right
if [ ! -f "$STATE_FILE" ]; then
    echo "bottom|right" > "$STATE_FILE"
fi

CURRENT=$(cat "$STATE_FILE")
VALIGN=$(echo "$CURRENT" | cut -d'|' -f1)
HALIGN=$(echo "$CURRENT" | cut -d'|' -f2)

case "$1" in
    up)    VALIGN="top" ;;
    down)  VALIGN="bottom" ;;
    left)  HALIGN="left" ;;
    right) HALIGN="right" ;;
esac

echo "$VALIGN|$HALIGN" > "$STATE_FILE"

# Re-run launch script with --last
# This will pick up the new position state.
bash "$HOME/.config/polybar/launch.sh" --last
