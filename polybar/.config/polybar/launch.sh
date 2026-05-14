#!/bin/bash

# Terminate already running bar instances
killall -q polybar

# Wait until the processes have been shut down
while pgrep -u $UID -x polybar >/dev/null; do sleep 1; done

notify-send "Polybar" "Launch script started..."

# CONFIG DIR
CONFIG_DIR="$(dirname "$(realpath "$0")")"


# REPO ROOT
REPO_ROOT="$(realpath "$CONFIG_DIR/../../../")"

# Sync YAD theme with Polybar colors
echo "[$(date)] Triggering YAD sync from launch.sh" >> /tmp/yad_sync.log
chmod +x "$HOME/.config/polybar/scripts/sync_yad_theme.sh"
"$HOME/.config/polybar/scripts/sync_yad_theme.sh"


# Function to update shortcuts
update_shortcuts() {
    local term=$1
    local browser=$2
    local file=$3
    
    # Update XML (Source)
    local XML_FILE="$HOME/.config/xfce4/xfconf/xfce-perchannel-xml/xfce4-keyboard-shortcuts.xml"
    if [ -f "$XML_FILE" ]; then
        sed -i "s|<property name=\"&lt;Super&gt;Return\" type=\"string\" value=\"[^\"]*\"/>|<property name=\"&lt;Super&gt;Return\" type=\"string\" value=\"$term\"/>|" "$XML_FILE"
        sed -i "s|<property name=\"&lt;Super&gt;&lt;Shift&gt;b\" type=\"string\" value=\"[^\"]*\"/>|<property name=\"&lt;Super&gt;&lt;Shift&gt;b\" type=\"string\" value=\"$browser\"/>|" "$XML_FILE"
        sed -i "s|<property name=\"&lt;Super&gt;e\" type=\"string\" value=\"[^\"]*\"/>|<property name=\"&lt;Super&gt;e\" type=\"string\" value=\"$file\"/>|" "$XML_FILE"
    fi
    
    # Update Live Session
    xfconf-query -c xfce4-keyboard-shortcuts -p /commands/custom/'<Super>Return' -n -t string -s "$term"
    xfconf-query -c xfce4-keyboard-shortcuts -p /commands/custom/'<Super><Shift>b' -n -t string -s "$browser"
    xfconf-query -c xfce4-keyboard-shortcuts -p /commands/custom/'<Super>e' -n -t string -s "$file"
    
    # PrintScreen Shortcuts
    xfconf-query -c xfce4-keyboard-shortcuts -p /commands/custom/Print -n -t string -s "xfce4-screenshooter"
    xfconf-query -c xfce4-keyboard-shortcuts -p /commands/custom/'<Alt>Print' -n -t string -s "xfce4-screenshooter -w"
    xfconf-query -c xfce4-keyboard-shortcuts -p /commands/custom/'<Shift>Print' -n -t string -s "xfce4-screenshooter -r"
}

# 1. Show display layout visualization first (Wait for user OK)
LAST_CONF="$HOME/.config/polybar/.last_launch"
LOAD_LAST=false

# Parse arguments
for arg in "$@"; do
    case $arg in
        --last)
            if [ -f "$LAST_CONF" ]; then
                source "$LAST_CONF"
                LOAD_LAST=true
            else
                notify-send "Polybar" "No previous configuration found."
            fi
            SKIP_PROMPT=true
            ;;
        --new)
            LOAD_LAST=false
            SKIP_PROMPT=false
            ;;
    esac
done

if [ "$SKIP_PROMPT" != "true" ]; then
    chmod +x "$HOME/.config/polybar/scripts/show_layout.sh"
    while true; do
        "$HOME/.config/polybar/scripts/show_layout.sh"

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
fi

# 2. Detect monitors and ask for bar positions & modules
chmod +x "$HOME/.config/polybar/scripts/bar_config.sh"
chmod +x "$HOME/.config/polybar/scripts/bar_modules.sh"

# Get Monitor Status
HDMI_ACTIVE=$(xfconf-query -c displays -p "/Default/HDMI-1/Active" 2>/dev/null)
EDP_ACTIVE=$(xfconf-query -c displays -p "/Default/eDP-1/Active" 2>/dev/null)

if [ "$LOAD_LAST" != "true" ]; then
    # --- HDMI-1 (Principal) ---
    if [ "$HDMI_ACTIVE" == "true" ]; then
        # Ask Position
        POS_H=$(bash "$HOME/.config/polybar/scripts/bar_config.sh" "HDMI-1" "External HP 23\"")
        # Ask Modules if not disabled
        if [ "$POS_H" != "none" ]; then
            MODS_H=$(bash "$HOME/.config/polybar/scripts/bar_modules.sh" "External HP 23\"")
        else
            MODS_H="DISABLED"
        fi
    fi

    # --- eDP-1 (Laptop) ---
    if [ "$EDP_ACTIVE" == "true" ]; then
        # Ask Position
        POS_E=$(bash "$HOME/.config/polybar/scripts/bar_config.sh" "eDP-1" "Laptop Screen")
        # Ask Modules if not disabled
        if [ "$POS_E" != "none" ]; then
            MODS_E=$(bash "$HOME/.config/polybar/scripts/bar_modules.sh" "Laptop Screen")
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

# --- MINIMAL MODE OVERRIDE ---
BAR_NAME="main"
STATE_FILE="/tmp/polybar_minimal_state"
if [ -f "$STATE_FILE" ]; then
    BAR_NAME="mini"
    # We keep only icon-show and powermenu on the right
    MODS_H=" | | icon-show powermenu"
    MODS_E=" | | icon-show powermenu"
fi

# 3. Application Selection
if [ "$LOAD_LAST" != "true" ]; then
    chmod +x "$HOME/.config/polybar/scripts/app_selector.sh"
    APPS=$(bash "$HOME/.config/polybar/scripts/app_selector.sh")
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
    chmod +x "$HOME/.config/polybar/scripts/ws_presets.sh"
    "$HOME/.config/polybar/scripts/ws_presets.sh"
fi


# 4. Final Launch
# Launch HDMI-1
if [ "$HDMI_ACTIVE" == "true" ] && [ "$MODS_H" != "DISABLED" ]; then
    LEFT=$(echo "$MODS_H" | cut -d'|' -f1)
    CENTER=$(echo "$MODS_H" | cut -d'|' -f2)
    RIGHT=$(echo "$MODS_H" | cut -d'|' -f3)
    
    MONITOR=HDMI-1 POLYBAR_BOTTOM=$POS_H \
    POLYBAR_LEFT="$LEFT" POLYBAR_CENTER="$CENTER" POLYBAR_RIGHT="$RIGHT" \
    polybar -c "$HOME/.config/polybar/config.ini" "$BAR_NAME" &
fi

# Launch eDP-1
if [ "$EDP_ACTIVE" == "true" ] && [ "$MODS_E" != "DISABLED" ]; then
    LEFT=$(echo "$MODS_E" | cut -d'|' -f1)
    CENTER=$(echo "$MODS_E" | cut -d'|' -f2)
    RIGHT=$(echo "$MODS_E" | cut -d'|' -f3)
    
    MONITOR=eDP-1 POLYBAR_BOTTOM=$POS_E \
    POLYBAR_LEFT="$LEFT" POLYBAR_CENTER="$CENTER" POLYBAR_RIGHT="$RIGHT" \
    polybar -c "$HOME/.config/polybar/config.ini" "$BAR_NAME" &
fi

# Launch workspace notifier
pkill -f ws_notifier.sh
"$HOME/.config/polybar/scripts/ws_notifier.sh" &

# Launch battery monitor
pkill -f battery_monitor.sh
chmod +x "$HOME/.config/polybar/scripts/battery_monitor.sh"
"$HOME/.config/polybar/scripts/battery_monitor.sh" &

# Launch monitor watcher (Detects unplug/plug)
pkill -f monitor_watcher.sh
chmod +x "$HOME/.config/polybar/scripts/monitor_watcher.sh"
"$HOME/.config/polybar/scripts/monitor_watcher.sh" &


# 5. Pre-compute and cache jgmenu positioning into .last_launch
# Runs xrandr ONCE here so jgmenu_anchored.sh never has to call it.
save_jgmenu_cache() {
    local conf="$1"
    local bar_height gap margin_x
    bar_height=32   # matches height = 32 in config.ini
    gap=8
    margin_x=5

    # Read all connected monitor geometries from xrandr in one pass
    while IFS= read -r xline; do
        local mname mgeom mw mh mox moy
        mname=$(echo "$xline" | cut -d' ' -f1)
        mgeom=$(echo "$xline" | grep -oE '[0-9]+x[0-9]+\+[0-9]+\+[0-9]+')
        [[ -z "$mgeom" ]] && continue
        mw=$(echo "$mgeom"  | cut -d'x' -f1)
        mh=$(echo "$mgeom"  | cut -d'x' -f2 | cut -d'+' -f1)
        mox=$(echo "$mgeom" | cut -d'+' -f2)
        moy=$(echo "$mgeom" | cut -d'+' -f3)

        case "$mname" in
            HDMI-1)
                JG_H_MON="$mname"
                JG_H_OX="$mox"; JG_H_OY="$moy"; JG_H_W="$mw"; JG_H_H="$mh"
                # POS_H: "true"=bottom bar → valign=bottom ; "false"=top → valign=top
                [[ "$POS_H" == "true" ]] && JG_H_VALIGN="bottom" || JG_H_VALIGN="top"
                JG_H_MARGIN_Y=$(( bar_height + gap ))
                JG_H_MARGIN_X=$margin_x
                ;;
            eDP-1)
                JG_E_MON="$mname"
                JG_E_OX="$mox"; JG_E_OY="$moy"; JG_E_W="$mw"; JG_E_H="$mh"
                [[ "$POS_E" == "true" ]] && JG_E_VALIGN="bottom" || JG_E_VALIGN="top"
                JG_E_MARGIN_Y=$(( bar_height + gap ))
                JG_E_MARGIN_X=$margin_x
                ;;
        esac
    done < <(xrandr --query | grep " connected")

    # Append jgmenu cache fields to .last_launch
    {
        echo "JG_H_MON=\"${JG_H_MON:-}\""
        echo "JG_H_OX=\"${JG_H_OX:-0}\""
        echo "JG_H_OY=\"${JG_H_OY:-0}\""
        echo "JG_H_W=\"${JG_H_W:-0}\""
        echo "JG_H_H=\"${JG_H_H:-0}\""
        echo "JG_H_VALIGN=\"${JG_H_VALIGN:-top}\""
        echo "JG_H_MARGIN_Y=\"${JG_H_MARGIN_Y:-40}\""
        echo "JG_H_MARGIN_X=\"${JG_H_MARGIN_X:-5}\""
        echo "JG_E_MON=\"${JG_E_MON:-}\""
        echo "JG_E_OX=\"${JG_E_OX:-0}\""
        echo "JG_E_OY=\"${JG_E_OY:-0}\""
        echo "JG_E_W=\"${JG_E_W:-0}\""
        echo "JG_E_H=\"${JG_E_H:-0}\""
        echo "JG_E_VALIGN=\"${JG_E_VALIGN:-top}\""
        echo "JG_E_MARGIN_Y=\"${JG_E_MARGIN_Y:-40}\""
        echo "JG_E_MARGIN_X=\"${JG_E_MARGIN_X:-5}\""
    } >> "$conf"
}

save_jgmenu_cache "$LAST_CONF"

echo "Bars launched..."