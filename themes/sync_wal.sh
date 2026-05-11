#!/bin/bash

THEME_DIR="/home/mohamed/Linux_Data/Git_Projects/xfce-customization/themes"

for theme_folder in "$THEME_DIR"/*/; do
    [ ! -f "${theme_folder}colors.ini" ] && continue
    
    # Extract colors from .ini
    BG=$(grep "background =" "${theme_folder}colors.ini" | cut -d' ' -f3)
    FG=$(grep "foreground =" "${theme_folder}colors.ini" | cut -d' ' -f3)
    PRI=$(grep "primary =" "${theme_folder}colors.ini" | cut -d' ' -f3)
    SEC=$(grep "secondary =" "${theme_folder}colors.ini" | cut -d' ' -f3)
    ALR=$(grep "alert =" "${theme_folder}colors.ini" | cut -d' ' -f3)
    
    # Create wal-compatible JSON
    cat > "${theme_folder}colors.json" <<EOF
{
    "colors": {
        "color0": "$BG",
        "color1": "$ALR",
        "color2": "$PRI",
        "color3": "$SEC",
        "color4": "$PRI",
        "color5": "$SEC",
        "color6": "$SEC",
        "color7": "$FG",
        "color8": "$BG",
        "color9": "$ALR",
        "color10": "$PRI",
        "color11": "$SEC",
        "color12": "$PRI",
        "color13": "$SEC",
        "color14": "$SEC",
        "color15": "$FG"
    },
    "special": {
        "background": "$BG",
        "foreground": "$FG",
        "cursor": "$FG"
    }
}
EOF
done

echo "Pywal JSON files generated for all themes!"
