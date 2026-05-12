#!/bin/bash

# 1. Fetch Battery Info using acpi (if installed) or upower
if command -v acpi >/dev/null 2>&1; then
    BAT_INFO=$(acpi -b | sed 's/Battery [0-9]: //' | awk -F', ' '{
        if (NF >= 3) {
            print $1 ", " $2 "\\n<b>Time:</b> " $3
        } else {
            print $0
        }
    }')
else
    # Fallback if acpi is not installed
    UPOWER_PATH=$(upower -e | grep BAT | head -n 1)
    STATE=$(upower -i "$UPOWER_PATH" | grep -E "state:" | awk '{print $2}')
    PERCENT=$(upower -i "$UPOWER_PATH" | grep -E "percentage:" | awk '{print $2}')
    TIME=$(upower -i "$UPOWER_PATH" | grep -E "time to" | sed 's/^[ \t]*//')

    if [ -n "$TIME" ]; then
        BAT_INFO="${STATE^}, ${PERCENT}\n<b>${TIME^}</b>"
    else
        BAT_INFO="${STATE^}, ${PERCENT}"
    fi
fi

if [ -z "$BAT_INFO" ]; then
    BAT_INFO="No Battery Found"
fi

# 2. Get screen dimensions for positioning
screen_width=$(cat /sys/class/drm/card*-*/modes | head -n 1 | cut -d 'x' -f 1)
if [ -z "$screen_width" ]; then
    screen_width=1920
fi

# Target position (assuming battery is on the right, window width is 350)
pos_x=$(( screen_width - 400 ))
pos_y=40

# 3. Get current brightness for the slider's starting value
# ...
START_VAL=100

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








# 4. Launch yad and use process substitution to handle slider events in real-time
yad --scale \
    --class="PolybarDialog" \
    --posx=$pos_x --posy=$pos_y \
    --title="Power Menu" \
    --text="<span font='JetBrainsMono Nerd Font Mono 14'><b>Battery:</b> $BAT_INFO\n<b>Brightness:</b></span>" \
    --value="$START_VAL" \
    --print-partial \
    --width=350 \
    --undecorated \
    --on-top \
    --close-on-unfocus \
    --css=<(echo "$CSS") \
    --button="Settings!preferences-system":2 > >(while read val; do

    if [ -n "$val" ] && [[ "$val" =~ ^[0-9]+$ ]]; then
        # Prevent completely black screen by setting a minimum of 0.1
        if [ "$val" -lt 10 ]; then
            val=10
        fi
        
        # Use brightnessctl to set hardware brightness
        brightnessctl set ${val}%
    fi
done)

EXIT_CODE=$?


# 4. If Settings button was clicked (exit code 2), open xfce4-power-manager-settings
if [ $EXIT_CODE -eq 2 ]; then
    # Toggle logic: close if open, else open
    if pgrep -x "xfce4-power-manager-settings" > /dev/null; then
        killall xfce4-power-manager-settings
    else
        bash /home/mohamed/Linux_Data/Git_Projects/xfce-customization/polybar/.config/polybar/scripts/battery_toggle.sh
    fi
fi
