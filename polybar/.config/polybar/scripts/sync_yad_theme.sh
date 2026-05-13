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

# Default fallbacks
[ -z "$BG" ] && BG="#141414"
[ -z "$BG_ALT" ] && BG_ALT="#1c1c1c"
[ -z "$FG" ] && FG="#ffffff"
[ -z "$PRIMARY" ] && PRIMARY="#00ff9f"
[ -z "$SECONDARY" ] && SECONDARY="#00cc7f"
[ -z "$ALERT" ] && ALERT="#ff5252"
[ -z "$DISABLED" ] && DISABLED="#666666"

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
    font-size: 11pt;
    margin: 20px;
    text-shadow: none;
    color: $FG;
}

button {
    background: transparent;
    color: $FG;
    border: none;
    box-shadow: none;
    text-shadow: none;
    font-size: 11pt;
    padding: 10px;
    margin: 5px;
    outline: none;
}

button:hover {
    background: $BG_ALT;
    background-color: $BG_ALT;
    color: $PRIMARY;
}
EOF

# Log activity
notify-send "System Theme" "Synchronizing YAD and GTK colors..."
echo "[$(date)] YAD Theme synchronized. BG: $BG, FG: $FG, PRIMARY: $PRIMARY" >> /tmp/yad_sync.log

# Generate GTK3 Colors CSS
GTK_COLORS="$HOME/Linux_Data/Git_Projects/xfce-customization/gtk-3.0/.config/gtk-3.0/gtk-colors.css"
mkdir -p "$(dirname "$GTK_COLORS")"
cat > "$GTK_COLORS" <<EOF
/* Dynamically generated GTK colors from Polybar colors.ini */
@define-color theme_bg_color $BG;
@define-color theme_fg_color $FG;
@define-color theme_text_color $FG;
@define-color theme_base_color $BG_ALT;
@define-color theme_selected_bg_color $PRIMARY;
@define-color theme_selected_fg_color $BG;
@define-color theme_unfocused_bg_color $BG;
@define-color theme_unfocused_fg_color $DISABLED;
@define-color borders $SECONDARY;
@define-color warning_color $ALERT;
@define-color error_color $ALERT;
@define-color success_color $PRIMARY;
EOF

echo "YAD and GTK3 Themes synchronized with Polybar."
