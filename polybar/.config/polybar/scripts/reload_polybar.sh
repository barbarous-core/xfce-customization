#!/bin/bash

# Path to your launch script
LAUNCH_SCRIPT="/home/mohamed/Linux_Data/Git_Projects/xfce-customization/polybar/.config/polybar/launch.sh"
CONFIG_FILE="/home/mohamed/Linux_Data/Git_Projects/xfce-customization/polybar/.config/polybar/config.ini"
COLORS_CONF="/home/mohamed/Linux_Data/Git_Projects/xfce-customization/polybar/.config/polybar/colors.ini"

# Extract colors from colors.ini
BG=$(grep "^background =" "$COLORS_CONF" | cut -d' ' -f3)
FG=$(grep "^foreground =" "$COLORS_CONF" | cut -d' ' -f3)
ACCENT=$(grep "^primary =" "$COLORS_CONF" | cut -d' ' -f3)
ALERT=$(grep "^alert =" "$COLORS_CONF" | cut -d' ' -f3)

# Extract radius from config.ini
RADIUS=$(grep "^radius =" "$CONFIG_FILE" | cut -d' ' -f3)
[ -z "$RADIUS" ] && RADIUS="12"

[ -z "$BG" ] && BG="#1c1c1c"
[ -z "$FG" ] && FG="#ecf0f1"
[ -z "$ACCENT" ] && ACCENT="#3498db"
[ -z "$ALERT" ] && ALERT="#e74c3c"

# Define CSS for YAD to match Polybar aesthetic
CSS="
window, #yad-dialog-window {
    background-color: $BG;
    color: $FG;
    font-family: 'JetBrainsMono Nerd Font';
    border: none;
    border-radius: 0px;
}
label {
    font-size: 11pt;
    margin: 20px;
    text-shadow: none;
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
#yad-button-0 { /* Default button */
    text-decoration: underline;
}
"








# Show confirmation dialog using YAD
yad --title="Polybar Reload" \
    --class="PolybarDialog" \
    --text="How do you want to reload Polybar?" \
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
    --css=<(echo "$CSS") \
    --fontname="JetBrainsMono Nerd Font 11"


EXIT_CODE=$?

# Check exit status
if [ $EXIT_CODE -eq 0 ]; then
    bash "$LAUNCH_SCRIPT" --last
elif [ $EXIT_CODE -eq 3 ]; then
    bash "$LAUNCH_SCRIPT" --new
fi

