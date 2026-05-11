#!/bin/bash

# Configuration
THEME_DIR="/home/mohamed/Linux_Data/Git_Projects/xfce-customization/themes"
THEME_STATE_FILE="/tmp/polybar_active_theme"
POLYBAR_COLORS="/home/mohamed/Linux_Data/Git_Projects/xfce-customization/polybar/.config/polybar/colors.ini"

# 1. Get current theme
[ ! -f "$THEME_STATE_FILE" ] && echo "Premium_Gold" > "$THEME_STATE_FILE"
CURRENT=$(cat "$THEME_STATE_FILE")

# 2. Get sorted list of themes (excluding any scripts)
THEMES=($(ls -1 "$THEME_DIR" | grep -v "\.sh"))
COUNT=${#THEMES[@]}

# 3. Find current index
INDEX=-1
for i in "${!THEMES[@]}"; do
   if [[ "${THEMES[$i]}" == "$CURRENT" ]]; then
       INDEX=$i
       break
   fi
done

# 4. Calculate new index
DIRECTION=$1
if [ "$DIRECTION" == "next" ]; then
    NEW_INDEX=$(( (INDEX + 1) % COUNT ))
elif [ "$DIRECTION" == "prev" ]; then
    NEW_INDEX=$(( (INDEX - 1 + COUNT) % COUNT ))
else
    exit 1
fi

NEW_THEME=${THEMES[$NEW_INDEX]}

# 5. Apply Theme
echo "$NEW_THEME" > "$THEME_STATE_FILE"
cp "$THEME_DIR/$NEW_THEME/colors.ini" "$POLYBAR_COLORS"

# Sync colors to terminal and other apps using Pywal
/home/mohamed/.local/bin/wal -n -q -f "$THEME_DIR/$NEW_THEME/colors.json"

# 6. Restart Polybar
polybar-msg cmd restart >/dev/null 2>&1

# 7. Show OSD (using notify-send for speed)
# Replace-id ensures we don't stack multiple notifications
notify-send -t 500 -h string:x-canonical-private-synchronous:theme-osd \
    -i "preferences-desktop-theme" "Theme: $NEW_THEME"
