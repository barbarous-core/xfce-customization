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

# 2. Get current brightness for the slider's starting value
# Software brightness usually defaults to 100% (1.0). 
# We'll set the slider to start at 100.
START_VAL=100

# 3. Launch yad and use process substitution to handle slider events in real-time
yad --scale \
    --title="Power Menu" \
    --text="<b>Battery:</b> $BAT_INFO\n<b>Brightness:</b>" \
    --value="$START_VAL" \
    --print-partial \
    --width=350 \
    --undecorated \
    --on-top \
    --close-on-unfocus \
    --button="Settings!preferences-system":2 > >(while read val; do
    if [ -n "$val" ] && [[ "$val" =~ ^[0-9]+$ ]]; then
        # Prevent completely black screen by setting a minimum of 0.1
        if [ "$val" -lt 10 ]; then
            val=10
        fi
        
        # Use brightnessctl to set hardware brightness since xrandr is not installed
        # The slider is 10-100, so we just set brightnessctl to <val>%
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
