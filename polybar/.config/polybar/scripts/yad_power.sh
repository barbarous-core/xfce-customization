#!/bin/bash

# 1. Fetch Battery Info
if command -v acpi >/dev/null 2>&1; then
    BAT_INFO=$(acpi -b | sed 's/Battery [0-9]: //' | awk -F', ' '{print $1 ", " $2}')
else
    UPOWER_PATH=$(upower -e | grep BAT | head -n 1)
    STATE=$(upower -i "$UPOWER_PATH" | grep -E "state:" | awk '{print $2}')
    PERCENT=$(upower -i "$UPOWER_PATH" | grep -E "percentage:" | awk '{print $2}')
    BAT_INFO="${STATE^}, ${PERCENT}"
fi

# 2. Get current brightness
BRIGHTNESS_VAL=$(brightnessctl g | awk -v max=$(brightnessctl m) '{print int($1/max*100)}')

# CONFIG DIR
CONFIG_DIR="$HOME/.config/polybar"
COLORS_CONF="$CONFIG_DIR/colors.ini"

# Extract colors from colors.ini
BG=$(grep "^background =" "$COLORS_CONF" | cut -d' ' -f3)
FG=$(grep "^foreground =" "$COLORS_CONF" | cut -d' ' -f3)
ACCENT=$(grep "^primary =" "$COLORS_CONF" | cut -d' ' -f3)

[ -z "$BG" ] && BG="#1c1c1c"
[ -z "$FG" ] && FG="#ecf0f1"
[ -z "$ACCENT" ] && ACCENT="#3498db"

# Path to centralized YAD CSS
YAD_STYLE="$HOME/.config/yad/style.css"


# 4. Launch yad
yad --scale \
    --class="PolybarDialog" \
    --title="System Power" \
    --text="Battery: $BAT_INFO | Brightness" \
    --value="$BRIGHTNESS_VAL" \
    --print-partial \
    --undecorated \
    --fixed \
    --close-on-unfocus \
    --center \
    --width=400 \
    --button="Shutdown:bash -c 'systemctl poweroff'":0 \
    --button="Reboot:bash -c 'systemctl reboot'":0 \
    --button="Suspend:bash -c 'systemctl suspend'":0 \
    --css="$YAD_STYLE" \
    --fontname="JetBrainsMono Nerd Font 11" | while read -r line; do
    if [[ "$line" =~ ^[0-9]+$ ]]; then
        brightnessctl s "${line}%" > /dev/null
    fi
done
