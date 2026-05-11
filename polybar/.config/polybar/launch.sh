#!/bin/bash

# Terminate already running bar instances
killall -q polybar

# Wait until the processes have been shut down
while pgrep -u $UID -x polybar >/dev/null; do sleep 1; done

# CONFIG DIR
CONFIG_DIR="$(dirname "$(realpath "$0")")"

# Function to update shortcuts
update_shortcuts() {
    local term=$1
    local browser=$2
    local file=$3
    
    # Update XML (Source)
    local XML_FILE="/home/mohamed/Linux_Data/Git_Projects/xfce-customization/xfce4/.config/xfce4/xfconf/xfce-perchannel-xml/xfce4-keyboard-shortcuts.xml"
    if [ -f "$XML_FILE" ]; then
        sed -i "s|<property name=\"&lt;Super&gt;Return\" type=\"string\" value=\"[^\"]*\"/>|<property name=\"&lt;Super&gt;Return\" type=\"string\" value=\"$term\"/>|" "$XML_FILE"
        sed -i "s|<property name=\"&lt;Super&gt;&lt;Shift&gt;b\" type=\"string\" value=\"[^\"]*\"/>|<property name=\"&lt;Super&gt;&lt;Shift&gt;b\" type=\"string\" value=\"$browser\"/>|" "$XML_FILE"
        sed -i "s|<property name=\"&lt;Super&gt;e\" type=\"string\" value=\"[^\"]*\"/>|<property name=\"&lt;Super&gt;e\" type=\"string\" value=\"$file\"/>|" "$XML_FILE"
    fi
    
    # Update Live Session
    xfconf-query -c xfce4-keyboard-shortcuts -p /commands/custom/'<Super>Return' -n -t string -s "$term"
    xfconf-query -c xfce4-keyboard-shortcuts -p /commands/custom/'<Super><Shift>b' -n -t string -s "$browser"
    xfconf-query -c xfce4-keyboard-shortcuts -p /commands/custom/'<Super>e' -n -t string -s "$file"
}

# 1. Show display layout visualization first (Wait for user OK)
LAST_CONF="$CONFIG_DIR/.last_launch"
LOAD_LAST=false

chmod +x "$CONFIG_DIR/scripts/show_layout.sh"
while true; do
    "$CONFIG_DIR/scripts/show_layout.sh"
    RES=$?
    if [ $RES -eq 2 ]; then
        continue
    elif [ $RES -eq 3 ]; then
        if [ -f "$LAST_CONF" ]; then
            source "$LAST_CONF"
            LOAD_LAST=true
        else
            notify-send "Polybar" "No previous configuration found."
        fi
        break
    else
        break
    fi
done

# 2. Detect monitors and ask for bar positions & modules
chmod +x "$CONFIG_DIR/scripts/bar_config.sh"
chmod +x "$CONFIG_DIR/scripts/bar_modules.sh"

# Get Monitor Status
HDMI_ACTIVE=$(xfconf-query -c displays -p "/Default/HDMI-1/Active" 2>/dev/null)
EDP_ACTIVE=$(xfconf-query -c displays -p "/Default/eDP-1/Active" 2>/dev/null)

if [ "$LOAD_LAST" != "true" ]; then
    # --- HDMI-1 (Principal) ---
    if [ "$HDMI_ACTIVE" == "true" ]; then
        # Ask Position
        POS_H=$(bash "$CONFIG_DIR/scripts/bar_config.sh" "HDMI-1" "External HP 23\"")
        # Ask Modules if not disabled
        if [ "$POS_H" != "none" ]; then
            MODS_H=$(bash "$CONFIG_DIR/scripts/bar_modules.sh" "External HP 23\"")
        else
            MODS_H="DISABLED"
        fi
    fi

    # --- eDP-1 (Laptop) ---
    if [ "$EDP_ACTIVE" == "true" ]; then
        # Ask Position
        POS_E=$(bash "$CONFIG_DIR/scripts/bar_config.sh" "eDP-1" "Laptop Screen")
        # Ask Modules if not disabled
        if [ "$POS_E" != "none" ]; then
            MODS_E=$(bash "$CONFIG_DIR/scripts/bar_modules.sh" "Laptop Screen")
        else
            MODS_E="DISABLED"
        fi
    fi
    
    # Save for next time
    cat <<EOF > "$LAST_CONF"
POS_H="$POS_H"
MODS_H="$MODS_H"
POS_E="$POS_E"
MODS_E="$MODS_E"
SEL_TERM="$SEL_TERM"
SEL_BROWSER="$SEL_BROWSER"
SEL_FILE="$SEL_FILE"
EOF
fi

# 3. Application Selection
if [ "$LOAD_LAST" != "true" ]; then
    chmod +x "$CONFIG_DIR/scripts/app_selector.sh"
    APPS=$(bash "$CONFIG_DIR/scripts/app_selector.sh")
    if [ $? -eq 0 ]; then
        SEL_TERM=$(echo "$APPS" | cut -d'|' -f1)
        SEL_BROWSER=$(echo "$APPS" | cut -d'|' -f2)
        SEL_FILE=$(echo "$APPS" | cut -d'|' -f3)
        update_shortcuts "$SEL_TERM" "$SEL_BROWSER" "$SEL_FILE"
    fi
else
    # Apply loaded shortcuts
    update_shortcuts "$SEL_TERM" "$SEL_BROWSER" "$SEL_FILE"
fi

# 4. Ask for workspace presets
if [ "$LOAD_LAST" != "true" ]; then
    chmod +x "$CONFIG_DIR/scripts/ws_presets.sh"
    "$CONFIG_DIR/scripts/ws_presets.sh"
fi

# 4. Final Launch
# Launch HDMI-1
if [ "$HDMI_ACTIVE" == "true" ] && [ "$MODS_H" != "DISABLED" ]; then
    LEFT=$(echo "$MODS_H" | cut -d'|' -f1)
    CENTER=$(echo "$MODS_H" | cut -d'|' -f2)
    RIGHT=$(echo "$MODS_H" | cut -d'|' -f3)
    
    MONITOR=HDMI-1 POLYBAR_BOTTOM=$POS_H \
    POLYBAR_LEFT="$LEFT" POLYBAR_CENTER="$CENTER" POLYBAR_RIGHT="$RIGHT" \
    polybar -c "$CONFIG_DIR/config.ini" main &
fi

# Launch eDP-1
if [ "$EDP_ACTIVE" == "true" ] && [ "$MODS_E" != "DISABLED" ]; then
    LEFT=$(echo "$MODS_E" | cut -d'|' -f1)
    CENTER=$(echo "$MODS_E" | cut -d'|' -f2)
    RIGHT=$(echo "$MODS_E" | cut -d'|' -f3)
    
    MONITOR=eDP-1 POLYBAR_BOTTOM=$POS_E \
    POLYBAR_LEFT="$LEFT" POLYBAR_CENTER="$CENTER" POLYBAR_RIGHT="$RIGHT" \
    polybar -c "$CONFIG_DIR/config.ini" main &
fi

# Launch workspace notifier
pkill -f ws_notifier.sh
"$CONFIG_DIR/scripts/ws_notifier.sh" &

# Launch battery monitor
pkill -f battery_monitor.sh
chmod +x "$CONFIG_DIR/scripts/battery_monitor.sh"
"$CONFIG_DIR/scripts/battery_monitor.sh" &

echo "Bars launched..."