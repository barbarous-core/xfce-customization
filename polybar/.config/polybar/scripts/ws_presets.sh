#!/bin/bash

# Define Rofi Theme for Startup
THEME="window { width: 33%; border: 0px; border-radius: 20px; background-color: #282a2e; } 
       listview { lines: 2; }
       element { padding: 15px; background-color: transparent; }
       element-text { font: \"JetBrainsMono Nerd Font 18\"; horizontal-align: 0.5; text-color: #c5c8c6; }
       element selected { background-color: #61afef; }
       element-text selected { text-color: #282a2e; }
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
