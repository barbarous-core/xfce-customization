#!/bin/bash

# Temporary SVG file
SVG_FILE="/tmp/display_layout.svg"

# Function to get xfconf property
get_prop() {
    xfconf-query -c displays -p "/Default/$1/$2" 2>/dev/null || echo "$3"
}

# Gather info for eDP-1 (Laptop)
L_X=$(get_prop "eDP-1" "Position/X" 0)
L_Y=$(get_prop "eDP-1" "Position/Y" 1080)
L_RES=$(get_prop "eDP-1" "Resolution" "1920x1080")
L_W=$(echo $L_RES | cut -dx -f1)
L_H=$(echo $L_RES | cut -dx -f2)

# Gather info for HDMI-1 (External)
H_X=$(get_prop "HDMI-1" "Position/X" 0)
H_Y=$(get_prop "HDMI-1" "Position/Y" 0)
H_RES=$(get_prop "HDMI-1" "Resolution" "1920x1080")
H_W=$(echo $H_RES | cut -dx -f1)
H_H=$(echo $H_RES | cut -dx -f2)

# Calculate bounds
MIN_X=$(( L_X < H_X ? L_X : H_X ))
MIN_Y=$(( L_Y < H_Y ? L_Y : H_Y ))
MAX_X=$(( (L_X + L_W) > (H_X + H_W) ? (L_X + L_W) : (H_X + H_W) ))
MAX_Y=$(( (L_Y + L_H) > (H_Y + H_H) ? (L_Y + L_H) : (H_Y + H_H) ))

TOTAL_W=$(( MAX_X - MIN_X ))
TOTAL_H=$(( MAX_Y - MIN_Y ))

# Scaling factor (to fit in ~460x280)
SCALE_W=$(echo "scale=4; 460 / $TOTAL_W" | bc)
SCALE_H=$(echo "scale=4; 280 / $TOTAL_H" | bc)
SCALE=$(echo "if ($SCALE_W < $SCALE_H) $SCALE_W else $SCALE_H" | bc)

# Calculate X_OFFSET to center the group of monitors within the 500px SVG width
SCALED_TOTAL_W=$(echo "$TOTAL_W * $SCALE" | bc)
X_OFFSET=$(echo "(500 - $SCALED_TOTAL_W) / 2" | bc)

# Calculate scaled positions
L_SX=$(echo "($L_X - $MIN_X) * $SCALE + $X_OFFSET" | bc)
L_SY=$(echo "($L_Y - $MIN_Y) * $SCALE + 120" | bc)
L_SW=$(echo "$L_W * $SCALE" | bc)
L_SH=$(echo "$L_H * $SCALE" | bc)

H_SX=$(echo "($H_X - $MIN_X) * $SCALE + $X_OFFSET" | bc)
H_SY=$(echo "($H_Y - $MIN_Y) * $SCALE + 120" | bc)
H_SW=$(echo "$H_W * $SCALE" | bc)
H_SH=$(echo "$H_H * $SCALE" | bc)

# CONFIG DIR
CONFIG_DIR="/home/mohamed/Linux_Data/Git_Projects/xfce-customization/polybar/.config/polybar"
COLORS_CONF="$CONFIG_DIR/colors.ini"

# Extract colors from colors.ini
BG=$(grep "^background =" "$COLORS_CONF" | cut -d' ' -f3)
FG=$(grep "^foreground =" "$COLORS_CONF" | cut -d' ' -f3)
ACCENT=$(grep "^primary =" "$COLORS_CONF" | cut -d' ' -f3)

[ -z "$BG" ] && BG="#1c1c1c"
[ -z "$FG" ] && FG="#ecf0f1"
[ -z "$ACCENT" ] && ACCENT="#3498db"

# Extract radius from config.ini
RADIUS=$(grep "^radius =" "$CONFIG_DIR/config.ini" | cut -d' ' -f3)
[ -z "$RADIUS" ] && RADIUS="12"

# Create the SVG using dynamic colors
cat <<EOF > "$SVG_FILE"
<svg width="500" height="450" viewBox="0 0 500 450" xmlns="http://www.w3.org/2000/svg">
  <defs>
    <linearGradient id="grad1" x1="0%" y1="0%" x2="100%" y2="100%">
      <stop offset="0%" style="stop-color:$ACCENT;stop-opacity:1" />
      <stop offset="100%" style="stop-color:$(echo $ACCENT | sed 's/#/#aa/');stop-opacity:1" />
    </linearGradient>
  </defs>
  
  <rect width="100%" height="100%" fill="$BG" rx="0" />
  
  <!-- Title Text at the top using Polybar Font style -->
  <text x="250" y="45" font-family="JetBrainsMono Nerd Font" font-weight="bold" font-size="18" fill="$ACCENT" text-anchor="middle">Monitor Arrangement Detected</text>
  <text x="250" y="75" font-family="JetBrainsMono Nerd Font" font-size="12" fill="$FG" text-anchor="middle">Adjust your display settings or proceed with the current layout.</text>

  <!-- Monitor HDMI-1 -->
  <rect x="$H_SX" y="$H_SY" width="$H_SW" height="$H_SH" rx="12" fill="$BG" stroke="url(#grad1)" stroke-width="4"/>
  <text x="$(echo "$H_SX + $H_SW/2" | bc)" y="$(echo "$H_SY + $H_SH/2" | bc)" font-family="JetBrainsMono Nerd Font" font-weight="bold" font-size="11" fill="$FG" text-anchor="middle">HP Inc. 23"</text>

  <!-- Monitor eDP-1 -->
  <rect x="$L_SX" y="$L_SY" width="$L_SW" height="$L_SH" rx="12" fill="$BG" stroke="url(#grad1)" stroke-width="4"/>
  <text x="$(echo "$L_SX + $L_SW/2" | bc)" y="$(echo "$L_SY + $L_SH/2" | bc)" font-family="JetBrainsMono Nerd Font" font-weight="bold" font-size="11" fill="$FG" text-anchor="middle">Laptop</text>
</svg>
EOF

# Calculate position to be at the top center
SCREEN_WIDTH=$(xwininfo -root | grep "Width:" | awk '{print $2}')
[ -z "$SCREEN_WIDTH" ] && SCREEN_WIDTH=1920
X_POS=$(( (SCREEN_WIDTH / 2) - 250 ))
Y_POS=50

CSS="
window, #yad-dialog-window {
    background-color: $BG;
    color: $FG;
    font-family: 'JetBrainsMono Nerd Font';
    border: none;
    border-radius: 0px;
}
button {
    background: transparent;
    color: $ACCENT;
    border: none;
    box-shadow: none;
    text-shadow: none;
    font-size: 11pt;
    padding: 10px;
    margin: 5px;
    outline: none;
}
button:hover {
    background: transparent;
    color: $FG;
}
"




# Show YAD dialog with Polybar's font (JetBrainsMono Nerd Font)
yad --picture --filename="$SVG_FILE" --size=orig \
    --class="PolybarDialog" \
    --title="Display Layout" --posx=$X_POS --posy=$Y_POS \
    --button="Load Last Config:3" \
    --button="Create New Configuration:0" \
    --button="Display Settings:2" \
    --width=500 --height=520 \
    --window-icon="video-display" \
    --skip-taskbar \
    --undecorated \
    --css=<(echo "$CSS") \
    --fontname="JetBrainsMono Nerd Font 10"


EXIT_CODE=$?

if [ "$EXIT_CODE" -eq 2 ]; then
    killall -q polybar
    xfce4-display-settings
    exit 2
elif [ "$EXIT_CODE" -eq 3 ]; then
    exit 3
fi

exit 0

