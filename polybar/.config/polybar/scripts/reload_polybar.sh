#!/bin/bash

# Paths
LAUNCH_SCRIPT="$HOME/.config/polybar/launch.sh"
YAD_STYLE="$HOME/.config/yad/style.css"

# Sync YAD theme before showing dialog
bash "$HOME/.config/polybar/scripts/sync_yad_theme.sh"

# Get monitor resolution (robust way)
RES=$(xrandr --current | grep '*' | head -n1 | awk '{print $1}')
WIDTH=$(echo $RES | cut -d'x' -f1)
HEIGHT=$(echo $RES | cut -d'x' -f2)

# Extract foreground color for tinting
COLORS_CONF="$HOME/.config/polybar/colors.ini"
FG_COLOR=$(grep "^foreground =" "$COLORS_CONF" | awk '{print $3}')
[ -z "$FG_COLOR" ] && FG_COLOR="#ffffff"

# Create simulated blur with color tint
xfce4-screenshooter -f -s /tmp/polybar_blur.png
IMG_CMD="convert"
command -v magick >/dev/null 2>&1 && IMG_CMD="magick"
$IMG_CMD /tmp/polybar_blur.png -scale 10% -scale 1000% -fill "$FG_COLOR" -colorize 25% /tmp/polybar_blur.png

# Show blur background
yad --class="PolybarBlur" \
    --undecorated --fixed --no-buttons --skip-taskbar \
    --no-focus --sticky --center \
    --width=$WIDTH --height=$HEIGHT \
    --text="" \
    --css="window { background: url('/tmp/polybar_blur.png'); background-color: rgba(0,0,0,0.4); }" &
DIM_PID=$!

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

# Cleanup dimming
kill $DIM_PID 2>/dev/null

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
