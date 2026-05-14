#!/bin/bash

# Paths
COLORS_CONF="$HOME/.config/polybar/colors.ini"
YAD_STYLE="$HOME/.config/yad/style.css"

# Check if files exist
[ ! -f "$COLORS_CONF" ] && exit 1
[ ! -f "$YAD_STYLE" ] && exit 1

# Extract colors from colors.ini
BG=$(grep "^background =" "$COLORS_CONF" | awk '{print $3}')
BG_ALT=$(grep "^background-alt =" "$COLORS_CONF" | awk '{print $3}')
FG=$(grep "^foreground =" "$COLORS_CONF" | awk '{print $3}')
PRIMARY=$(grep "^primary =" "$COLORS_CONF" | awk '{print $3}')
SECONDARY=$(grep "^secondary =" "$COLORS_CONF" | awk '{print $3}')
ALERT=$(grep "^alert =" "$COLORS_CONF" | awk '{print $3}')
DISABLED=$(grep "^disabled =" "$COLORS_CONF" | awk '{print $3}')
WARNING=$(grep "^warning =" "$COLORS_CONF" | awk '{print $3}')
SUCCESS=$(grep "^success =" "$COLORS_CONF" | awk '{print $3}')

# Default fallbacks
[ -z "$BG" ] && BG="#141414"
[ -z "$BG_ALT" ] && BG_ALT="#1c1c1c"
[ -z "$FG" ] && FG="#ffffff"
[ -z "$PRIMARY" ] && PRIMARY="#00ff9f"
[ -z "$SECONDARY" ] && SECONDARY="#00cc7f"
[ -z "$ALERT" ] && ALERT="#ff5252"
[ -z "$DISABLED" ] && DISABLED="#666666"
[ -z "$WARNING" ] && WARNING="#FFA500"
[ -z "$SUCCESS" ] && SUCCESS="#00FF00"

# Generate style.css permanently
cat > "$YAD_STYLE" <<EOF
/* YAD Minimalist Style Template */
/* Generated dynamically by sync_yad_theme.sh */

window,
dialog,
window.background,
#yad-dialog-window {
    background-color: $BG;
    background: $BG;
    font-family: 'JetBrainsMono Nerd Font';
    border: none;
    border-radius: 0px;
}

label {
    font-size: 9pt;
    margin: 5px;
    text-shadow: none;
    color: $FG;
}

button {
    background: transparent;
    color: $FG;
    border: none;
    box-shadow: none;
    text-shadow: none;
    font-size: 9pt;
    padding: 10px;
    margin: 5px;
    outline: none;
}

button:hover,
button:hover label {
    background: $BG_ALT;
    background-color: $BG_ALT;
    color: $PRIMARY;
}

scrollbar, scrollbar button, scrollbar slider {
    opacity: 0;
    min-width: 0;
    min-height: 0;
}

scrolledwindow {
    border: none;
}

#yad-form-widget {
    margin: 10px;
}

/* Checkbox Styling */
checkbutton {
    margin-bottom: 10px;
    margin-left: 10px;
}

checkbutton check {
    background-color: $BG_ALT;
    border: none;
    color: $PRIMARY;
    border-radius: 4px;
    min-height: 18px;
    min-width: 18px;
}

checkbutton check:checked {
    background-color: $PRIMARY;
    color: $BG;
}

#yad-form-image {
    margin-bottom: 10px;
}
EOF

# Log activity
# notify-send "System Theme" "Synchronizing YAD and GTK colors..."
echo "[$(date)] YAD Theme synchronized. BG: $BG, FG: $FG, PRIMARY: $PRIMARY" >> /tmp/yad_sync.log

# Convert hex to RGB for rgba usage
hex_to_rgb() {
    local hex=${1#\#}
    if [ ${#hex} -eq 3 ]; then
        hex=$(echo $hex | sed 's/\(.\)\(.\)\(.\)/\1\1\2\2\3\3/')
    fi
    printf "%d, %d, %d" 0x${hex:0:2} 0x${hex:2:2} 0x${hex:4:2}
}

BG_RGB=$(hex_to_rgb "$BG")
FG_RGB=$(hex_to_rgb "$FG")
PRIMARY_RGB=$(hex_to_rgb "$PRIMARY")

# Generate GTK3 Colors CSS
GTK_COLORS="$HOME/Linux_Data/Git_Projects/xfce-customization/gtk-3.0/.config/gtk-3.0/gtk-colors.css"
mkdir -p "$(dirname "$GTK_COLORS")"
TMP_GTK_COLORS=$(mktemp)
cat > "$TMP_GTK_COLORS" <<EOF
/* Dynamically generated GTK colors from Polybar colors.ini */
/* Using standard CSS variables for maximum compatibility and IDE support */
:root, * {
    --theme-bg-color: $BG;
    --theme-fg-color: $FG;
    --theme-text-color: $FG;
    --theme-base-color: $BG_ALT;
    --theme-selected-bg-color: $PRIMARY;
    --theme-selected-fg-color: $BG;
    --theme-unfocused-bg-color: $BG;
    --theme-unfocused-fg-color: $DISABLED;
    --borders: $SECONDARY;
    --warning-color: $WARNING;
    --error-color: $ALERT;
    --success-color: $SUCCESS;

    /* Transparency variants */
    --theme-bg-alpha-50: rgba($BG_RGB, 0.5);
    --theme-bg-alpha-10: rgba($BG_RGB, 0.1);
    --theme-fg-alpha-50: rgba($FG_RGB, 0.5);
    --theme-fg-alpha-10: rgba($FG_RGB, 0.1);
}
EOF
mv "$TMP_GTK_COLORS" "$GTK_COLORS"

# Generate Polythemes GTK3 Colors (Directly in repo to ensure persistence)
REPO_ROOT="/home/mohamed/Linux_Data/Git_Projects/xfce-customization"
POLY_GTK_COLORS="$REPO_ROOT/polythemes/.themes/polythemes/gtk-3.0/gtk-colors.css"
mkdir -p "$(dirname "$POLY_GTK_COLORS")"
TMP_POLY_GTK_COLORS=$(mktemp)

cat > "$TMP_POLY_GTK_COLORS" <<EOF
/* Dynamically generated for Polythemes */
/* Using standard CSS variables for maximum compatibility and IDE support */
:root, * {
    --theme-bg-color: $BG;
    --theme-fg-color: $FG;
    --theme-text-color: $FG;
    --theme-base-color: $BG_ALT;
    --theme-selected-bg-color: $PRIMARY;
    --theme-selected-fg-color: $BG;
    --theme-unfocused-bg-color: $BG;
    --theme-unfocused-fg-color: $DISABLED;
    --fg-color: $FG;
    --bg-color: $BG;
    --base-color: $BG_ALT;
    --selected-bg-color: $PRIMARY;
    --selected-fg-color: $BG;
    --borders: $SECONDARY;
    --warning-color: $WARNING;
    --error-color: $ALERT;
    --success-color: $SUCCESS;
    --wm-title: $FG;
    --wm-bg: $BG;
    --wm-border: $SECONDARY;

    /* RGB variants for rgba() usage */
    --theme-bg-rgb: $BG_RGB;
    --theme-fg-rgb: $FG_RGB;
    --theme-selected-bg-rgb: $PRIMARY_RGB;

    /* Common transparency levels generated dynamically */
EOF

# Append a wide range of alpha variants
for a in 03 05 06 07 08 10 12 15 20 25 30 35 40 45 50 55 60 65 70 75 80 85 90 95; do
    alpha="0.${a}"
    [ "$a" -eq 100 ] && alpha="1.0"
    echo "    --theme-bg-alpha-${a}: rgba($BG_RGB, ${alpha});" >> "$TMP_POLY_GTK_COLORS"
    echo "    --theme-fg-alpha-${a}: rgba($FG_RGB, ${alpha});" >> "$TMP_POLY_GTK_COLORS"
    echo "    --theme-sel-alpha-${a}: rgba($PRIMARY_RGB, ${alpha});" >> "$TMP_POLY_GTK_COLORS"
done

cat >> "$TMP_POLY_GTK_COLORS" <<EOF
}
EOF
mv "$TMP_POLY_GTK_COLORS" "$POLY_GTK_COLORS"
chmod 644 "$GTK_COLORS" "$POLY_GTK_COLORS"

# Optional: Force GTK to refresh by toggling the theme
# This only works if the theme is already set to 'polythemes'
CURRENT_THEME=$(xfconf-query -c xsettings -p /Net/ThemeName 2>/dev/null)
if [ "$CURRENT_THEME" == "polythemes" ]; then
    # We toggle to a dummy theme and back to force a reload of the CSS
    xfconf-query -c xsettings -p /Net/ThemeName -s "Default"
    sleep 0.1
    xfconf-query -c xsettings -p /Net/ThemeName -s "polythemes"
fi

echo "YAD and GTK3 Themes synchronized with Polybar. GTK theme refreshed."
