#!/bin/bash

# CONFIG DIR
CONFIG_DIR="$HOME/.config/polybar"
COLORS_CONF="$CONFIG_DIR/colors.ini"

# Extract colors from colors.ini
BG=$(grep "^background =" "$COLORS_CONF" | cut -d' ' -f3)
FG=$(grep "^foreground =" "$COLORS_CONF" | cut -d' ' -f3)
ACCENT=$(grep "^primary =" "$COLORS_CONF" | cut -d' ' -f3)

[z "$BG" ] && BG="#1c1c1c"
[z "$FG" ] && FG="#ecf0f1"
[z "$ACCENT" ] && ACCENT="#3498db"

# Define Rofi Theme for Startup
THEME="window { width: 33%; border: 0px; border-radius: 0px; background-color: $BG; } 
       listview { lines: 2; scrollbar: false; }
       element { padding: 10px; background-color: transparent; }
       element-text { font: \"JetBrainsMono Nerd Font 11\"; horizontal-align: 0.5; text-color: $FG; }
       element selected { background-color: transparent; }
       element-text selected { text-color: $ACCENT; }
       inputbar { enabled: false; }"





# Options
YES_OPT="🚀 Load Productivity WS presets"
NO_OPT="🧹 Clean Slate (Only one WS)"
OPTIONS="${YES_OPT}\n${NO_OPT}"

# Show Rofi menu
CHOICE=$(echo -e "$OPTIONS" | rofi -dmenu -p "Workspace Setup" -theme-str "$THEME" -location 0 -monitor -1 -pid /tmp/rofi_startup.pid)

if [ "$CHOICE" == "$YES_OPT" ]; then
    # Load Preset: 9 workspaces
    xfconf-query -c xfwm4 -p /general/workspace_count -s 9
    xfconf-query -c xfwm4 -p /general/workspace_names -r
    xfconf-query -c xfwm4 -p /general/workspace_names -n \
        -t string -s "free workspace" \
        -t string -s "🌐 Web" \
        -t string -s " Code" \
        -t string -s " Terminal" \
        -t string -s " Chat" \
        -t string -s "🎨 Design" \
        -t string -s "🎬 Video" \
        -t string -s " Office" \
        -t string -s " PKM"
elif [ "$CHOICE" == "$NO_OPT" ]; then
    # RESET: Keep only 1 workspace
    xfconf-query -c xfwm4 -p /general/workspace_count -s 1
    xfconf-query -c xfwm4 -p /general/workspace_names -r
    xfconf-query -c xfwm4 -p /general/workspace_names -n -t string -s "free workspace"
fi
