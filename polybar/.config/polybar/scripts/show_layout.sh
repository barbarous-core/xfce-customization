#!/bin/bash

# Temporary SVG file
SVG_FILE="/tmp/display_layout.svg"

# Function to get xfconf property
get_prop() {
    xfconf-query -c displays -p "/Default/$1/$2" 2>/dev/null || echo "$3"
}

# CONFIG DIR
CONFIG_DIR="$HOME/.config/polybar"
COLORS_CONF="$CONFIG_DIR/colors.ini"
YAD_STYLE="$HOME/.config/yad/style.css"

# Extract colors from colors.ini
BG=$(grep "^background =" "$COLORS_CONF" | cut -d' ' -f3); [ -z "$BG" ] && BG="#1c1c1c"
FG=$(grep "^foreground =" "$COLORS_CONF" | cut -d' ' -f3); [ -z "$FG" ] && FG="#ecf0f1"
ACCENT=$(grep "^primary =" "$COLORS_CONF" | cut -d' ' -f3); [ -z "$ACCENT" ] && ACCENT="#3498db"

# Detect connected monitors using xrandr
# Format: NAME WIDTH HEIGHT X Y
MONITORS=()
while IFS= read -r line; do
    NAME=$(echo "$line" | cut -d' ' -f1)
    GEOM=$(echo "$line" | grep -oE '[0-9]+x[0-9]+\+[0-9]+\+[0-9]+')
    if [ -n "$GEOM" ]; then
        W=$(echo "$GEOM" | cut -d'x' -f1)
        H=$(echo "$GEOM" | cut -d'x' -f2 | cut -d'+' -f1)
        X=$(echo "$GEOM" | cut -d'+' -f2)
        Y=$(echo "$GEOM" | cut -d'+' -f3)
        MONITORS+=("$NAME|$W|$H|$X|$Y")
    fi
done < <(xrandr --query | grep " connected")

if [ ${#MONITORS[@]} -eq 0 ]; then
    notify-send "Error" "No connected monitors detected."
    exit 1
fi

# Calculate bounds for scaling
MIN_X=99999; MIN_Y=99999; MAX_X=-99999; MAX_Y=-99999
for m in "${MONITORS[@]}"; do
    IFS='|' read -r name w h x y <<< "$m"
    [ "$x" -lt "$MIN_X" ] && MIN_X=$x
    [ "$y" -lt "$MIN_Y" ] && MIN_Y=$y
    [ "$((x + w))" -gt "$MAX_X" ] && MAX_X=$((x + w))
    [ "$((y + h))" -gt "$MAX_Y" ] && MAX_Y=$((y + h))
done

TOTAL_W=$(( MAX_X - MIN_X ))
TOTAL_H=$(( MAX_Y - MIN_Y ))
[ "$TOTAL_W" -le 0 ] && TOTAL_W=1920
[ "$TOTAL_H" -le 0 ] && TOTAL_H=1080

# Scaling factor (to fit in ~460x280)
SCALE_W=$(echo "scale=4; 460 / $TOTAL_W" | bc)
SCALE_H=$(echo "scale=4; 280 / $TOTAL_H" | bc)
SCALE=$(echo "if ($SCALE_W < $SCALE_H) $SCALE_W else $SCALE_H" | bc)

X_OFFSET=$(echo "(500 - ($TOTAL_W * $SCALE)) / 2" | bc)

# Mirror Detection (Check if all monitors share same position)
IS_MIRROR=false
FIRST_POS=$(echo "${MONITORS[0]}" | cut -d'|' -f4,5)
MIRROR_COUNT=0
for m in "${MONITORS[@]}"; do
    POS=$(echo "$m" | cut -d'|' -f4,5)
    [ "$POS" == "$FIRST_POS" ] && ((MIRROR_COUNT++))
done
[ "$MIRROR_COUNT" -eq "${#MONITORS[@]}" ] && [ "${#MONITORS[@]}" -gt 1 ] && IS_MIRROR=true

# Create SVG
cat <<EOF > "$SVG_FILE"
<svg width="500" height="450" viewBox="0 0 500 450" xmlns="http://www.w3.org/2000/svg">
  <defs>
    <linearGradient id="grad1" x1="0%" y1="0%" x2="100%" y2="100%">
      <stop offset="0%" style="stop-color:$ACCENT;stop-opacity:1" />
      <stop offset="100%" style="stop-color:$(echo $ACCENT | sed 's/#/#aa/');stop-opacity:1" />
    </linearGradient>
  </defs>
  <rect width="100%" height="100%" fill="$BG" rx="0" />
  <text x="250" y="45" font-family="JetBrainsMono Nerd Font" font-weight="bold" font-size="18" fill="$ACCENT" text-anchor="middle">Monitor Arrangement Detected</text>
  <text x="250" y="75" font-family="JetBrainsMono Nerd Font" font-size="12" fill="$FG" text-anchor="middle">Adjust your display settings or proceed with the current layout.</text>
  <g>
EOF

if [ "$IS_MIRROR" == "true" ]; then
    # Draw Mirror Mode
    IFS='|' read -r name w h x y <<< "${MONITORS[0]}"
    SW=$(echo "$w * $SCALE" | bc); SH=$(echo "$h * $SCALE" | bc)
    SX=$(echo "($x - $MIN_X) * $SCALE + $X_OFFSET" | bc); SY=$(echo "($y - $MIN_Y) * $SCALE + 120" | bc)
    
    cat <<EOF >> "$SVG_FILE"
    <rect x="$SX" y="$SY" width="$SW" height="$SH" rx="12" fill="$BG" stroke="url(#grad1)" stroke-width="4" />
    <rect x="$(echo "$SX + 10" | bc)" y="$(echo "$SY + 10" | bc)" width="$SW" height="$SH" rx="12" fill="none" stroke="$FG" stroke-width="1" stroke-dasharray="4" opacity="0.5" />
    <text x="$(echo "$SX + $SW/2" | bc)" y="$(echo "$SY + $SH/2" | bc)" font-family="JetBrainsMono Nerd Font" font-weight="bold" font-size="14" fill="$FG" text-anchor="middle">MIRROR MODE</text>
    <text x="$(echo "$SX + $SW/2" | bc)" y="$(echo "$SY + $SH/2 + 20" | bc)" font-family="JetBrainsMono Nerd Font" font-size="9" fill="$FG" text-anchor="middle" opacity="0.7">$(echo "${MONITORS[@]}" | sed 's/|[^ ]*//g')</text>
EOF
else
    # Draw Each Monitor
    for m in "${MONITORS[@]}"; do
        IFS='|' read -r name w h x y <<< "$m"
        SW=$(echo "$w * $SCALE" | bc); SH=$(echo "$h * $SCALE" | bc)
        SX=$(echo "($x - $MIN_X) * $SCALE + $X_OFFSET" | bc); SY=$(echo "($y - $MIN_Y) * $SCALE + 120" | bc)
        
        # Try to get human name (simplified)
        HNAME="$name"
        [[ "$name" == eDP* ]] && HNAME="Laptop"
        [[ "$name" == HDMI* ]] && HNAME="External Display"
        
        cat <<EOF >> "$SVG_FILE"
        <rect x="$SX" y="$SY" width="$SW" height="$SH" rx="12" fill="$BG" stroke="url(#grad1)" stroke-width="4"/>
        <text x="$(echo "$SX + $SW/2" | bc)" y="$(echo "$SY + $SH/2" | bc)" font-family="JetBrainsMono Nerd Font" font-weight="bold" font-size="11" fill="$FG" text-anchor="middle">$HNAME</text>
EOF
    done
fi

echo "</g></svg>" >> "$SVG_FILE"

yad --form --image="$SVG_FILE" --image-on-top \
    --class="PolybarDialog" \
    --title="Display Layout" --center \
    --button="Confirm Layout:0" \
    --button="Display Settings:2" \
    --width=500 --height=550 \
    --window-icon="video-display" \
    --skip-taskbar \
    --undecorated \
    --css="$YAD_STYLE"

EXIT_CODE=$?
if [ "$EXIT_CODE" -eq 2 ]; then
    killall -q polybar
    xfce4-display-settings
    exit 2
fi
exit 0
