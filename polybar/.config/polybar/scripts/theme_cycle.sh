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

# Update Jgmenu colors
BG=$(grep "background =" "$THEME_DIR/$NEW_THEME/colors.ini" | cut -d' ' -f3)
FG=$(grep "foreground =" "$THEME_DIR/$NEW_THEME/colors.ini" | cut -d' ' -f3)
PRI=$(grep "primary =" "$THEME_DIR/$NEW_THEME/colors.ini" | cut -d' ' -f3)
ALT=$(grep "background-alt =" "$THEME_DIR/$NEW_THEME/colors.ini" | cut -d' ' -f3)

sed -i "s/color_menu_bg = .*/color_menu_bg = $BG 100/" ~/.config/jgmenu/jgmenurc
sed -i "s/color_menu_bg_to = .*/color_menu_bg_to = $BG 100/" ~/.config/jgmenu/jgmenurc
sed -i "s/color_menu_border = .*/color_menu_border = $PRI 100/" ~/.config/jgmenu/jgmenurc
sed -i "s/color_norm_fg = .*/color_norm_fg = $FG 100/" ~/.config/jgmenu/jgmenurc
sed -i "s/color_sel_fg = .*/color_sel_fg = $PRI 100/" ~/.config/jgmenu/jgmenurc
sed -i "s/color_sel_bg = .*/color_sel_bg = $ALT 100/" ~/.config/jgmenu/jgmenurc
sed -i "s/color_sel_border = .*/color_sel_border = $ALT 100/" ~/.config/jgmenu/jgmenurc

# 6. Restart Polybar
polybar-msg cmd restart >/dev/null 2>&1

# 7. Show OSD (using notify-send for speed)
# Replace-id ensures we don't stack multiple notifications
notify-send -t 500 -h string:x-canonical-private-synchronous:theme-osd \
    -i "preferences-desktop-theme" "Theme: $NEW_THEME"
