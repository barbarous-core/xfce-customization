#!/bin/bash

# Paths
COLORS_CONF="$HOME/.config/polybar/colors.ini"
YAD_STYLE="$HOME/.config/yad/style.css"

# Check if files exist
[ ! -f "$COLORS_CONF" ] && exit 1
[ ! -f "$YAD_STYLE" ] && exit 1

# Extract colors from colors.ini
BG=$(grep "^background =" "$COLORS_CONF" | awk '{print $3}')
FG=$(grep "^foreground =" "$COLORS_CONF" | awk '{print $3}')
ACCENT=$(grep "^primary =" "$COLORS_CONF" | awk '{print $3}')

# Default fallbacks
[ -z "$BG" ] && BG="#141414"
[ -z "$FG" ] && FG="#ffffff"
[ -z "$ACCENT" ] && ACCENT="#00ff9f"

# Update style.css permanently
sed -i --follow-symlinks "s/--bg-color: [^;]*/--bg-color: $BG/" "$YAD_STYLE"
sed -i --follow-symlinks "s/--fg-color: [^;]*/--fg-color: $FG/" "$YAD_STYLE"
sed -i --follow-symlinks "s/--accent-color: [^;]*/--accent-color: $ACCENT/" "$YAD_STYLE"

# Log activity
notify-send "YAD" "Synchronizing theme colors..."
echo "[$(date)] YAD Theme synchronized. BG: $BG, FG: $FG, ACCENT: $ACCENT" >> /tmp/yad_sync.log

echo "YAD Theme synchronized with Polybar."
