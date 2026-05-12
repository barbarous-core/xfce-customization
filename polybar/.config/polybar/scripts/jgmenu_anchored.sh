#!/bin/bash

# jgmenu_anchored.sh — instant jgmenu positioning.
# All heavy lifting (xrandr, geometry) is done ONCE by launch.sh and cached
# in .last_launch. This script only calls xdotool getmouselocation (~5ms).

SCRIPT_DIR="$(dirname "$(realpath "$0")")"
LAST_LAUNCH="$SCRIPT_DIR/../.last_launch"
CONFIG="$HOME/.config/jgmenu/jgmenurc"

# ── 1. Load cached config ────────────────────────────────────────────────────
if [[ ! -f "$LAST_LAUNCH" ]]; then
    notify-send "jgmenu" "No .last_launch found — run launch.sh first."
    pkill -x jgmenu; jgmenu; exit 0
fi
source "$LAST_LAUNCH"
# Available after source:
#   JG_H_MON  JG_H_OX  JG_H_OY  JG_H_W  JG_H_H  JG_H_VALIGN  JG_H_MARGIN_Y  JG_H_MARGIN_X
#   JG_E_MON  JG_E_OX  JG_E_OY  JG_E_W  JG_E_H  JG_E_VALIGN  JG_E_MARGIN_Y  JG_E_MARGIN_X

# ── 2. Get mouse position (only external call needed) ────────────────────────
eval "$(xdotool getmouselocation --shell)"
M_X=$X
M_Y=$Y

# ── 3. Determine active monitor using cached bounds (pure bash arithmetic) ───
MON_NAME=""
VALIGN=""
MARGIN_Y=40
MARGIN_X=5

# Check HDMI-1
if [[ -n "$JG_H_MON" ]] && \
   (( M_X >= JG_H_OX && M_X <= JG_H_OX + JG_H_W &&
      M_Y >= JG_H_OY && M_Y <= JG_H_OY + JG_H_H )); then
    MON_NAME="$JG_H_MON"
    VALIGN="$JG_H_VALIGN"
    MARGIN_Y="$JG_H_MARGIN_Y"
    MARGIN_X="$JG_H_MARGIN_X"

# Check eDP-1
elif [[ -n "$JG_E_MON" ]] && \
     (( M_X >= JG_E_OX && M_X <= JG_E_OX + JG_E_W &&
        M_Y >= JG_E_OY && M_Y <= JG_E_OY + JG_E_H )); then
    MON_NAME="$JG_E_MON"
    VALIGN="$JG_E_VALIGN"
    MARGIN_Y="$JG_E_MARGIN_Y"
    MARGIN_X="$JG_E_MARGIN_X"

# Fallback: whichever monitor is defined
else
    if [[ -n "$JG_H_MON" ]]; then
        MON_NAME="$JG_H_MON"; VALIGN="$JG_H_VALIGN"
        MARGIN_Y="$JG_H_MARGIN_Y"; MARGIN_X="$JG_H_MARGIN_X"
    elif [[ -n "$JG_E_MON" ]]; then
        MON_NAME="$JG_E_MON"; VALIGN="$JG_E_VALIGN"
        MARGIN_Y="$JG_E_MARGIN_Y"; MARGIN_X="$JG_E_MARGIN_X"
    fi
fi

# ── 4. Patch jgmenurc (single sed call) ─────────────────────────────────────
COLORS_CONF="$SCRIPT_DIR/../colors.ini"
BG=$(grep "^background =" "$COLORS_CONF" | cut -d' ' -f3)
FG=$(grep "^foreground =" "$COLORS_CONF" | cut -d' ' -f3)
ACCENT=$(grep "^primary =" "$COLORS_CONF" | cut -d' ' -f3)

[ -z "$BG" ] && BG="#1c1c1c"
[ -z "$FG" ] && FG="#ecf0f1"
[ -z "$ACCENT" ] && ACCENT="#3498db"

sed -i --follow-symlinks \
    -e "s/^menu_margin_x = .*/menu_margin_x = $MARGIN_X/" \
    -e "s/^menu_margin_y = .*/menu_margin_y = $MARGIN_Y/" \
    -e "s/^menu_valign = .*/menu_valign = $VALIGN/" \
    -e "s/^#\?\s\?monitor = .*/monitor = $MON_NAME/" \
    -e "s/^color_menu_bg = .*/color_menu_bg = $BG 100/" \
    -e "s/^color_menu_bg_to = .*/color_menu_bg_to = $BG 100/" \
    -e "s/^color_menu_border = .*/color_menu_border = $ACCENT 100/" \
    -e "s/^color_norm_fg = .*/color_norm_fg = $FG 100/" \
    -e "s/^color_sel_bg = .*/color_sel_bg = $ACCENT 100/" \
    -e "s/^color_sel_fg = .*/color_sel_fg = $BG 100/" \
    -e "s/^color_sel_border = .*/color_sel_border = $ACCENT 100/" \
    -e "s/^color_sep_fg = .*/color_sep_fg = $ACCENT 50/" \
    "$CONFIG"

# ── 5. Launch jgmenu ─────────────────────────────────────────────────────────
pkill -x jgmenu
jgmenu
