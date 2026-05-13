#!/bin/bash

# Default modules definitions
DEF_LEFT="jgmenu sep xworkspaces sep add-workspace sep scroll-window sep"
DEF_CENTER="date"
DEF_RIGHT="sep sys-switch sep xkeyboard sep media sep battery sep connection sep themes sep powermenu"

# CONFIG DIR
CONFIG_DIR="$HOME/.config/polybar"
YAD_STYLE="$HOME/.config/yad/style.css"
NAME=$1

# Source images
IMG_LEFT="$CONFIG_DIR/Left_seg.png"
IMG_CENTER="$CONFIG_DIR/Center_seg.png"
IMG_RIGHT="$CONFIG_DIR/Right_seg.png"
IMG_COMBINED="/tmp/segments_header.png"

# Canvas dimensions
CANVAS_W=640
PADDING=15
GAP=10
BOX_W=$(( (CANVAS_W - 2*PADDING - 2*GAP) / 3 ))   # ~197px each
BOX_H=90
TITLE_H=40
CANVAS_H=$(( TITLE_H + BOX_H + PADDING ))   # ~145px total

# Step 1: Resize each segment image to fit its box
magick "$IMG_LEFT"   -resize "${BOX_W}x${BOX_H}!" /tmp/_seg_l.png
magick "$IMG_CENTER" -resize "${BOX_W}x${BOX_H}!" /tmp/_seg_c.png
magick "$IMG_RIGHT"  -resize "${BOX_W}x${BOX_H}!" /tmp/_seg_r.png

# Box X positions
BOX1_X=$PADDING
BOX2_X=$(( PADDING + BOX_W + GAP ))
BOX3_X=$(( PADDING + 2*BOX_W + 2*GAP ))
BOX_Y=$TITLE_H

# Step 2: Build composite image:
#   - Dark background
#   - "Selection Segment" title text at top-left
#   - 3 rounded bordered boxes
#   - Segment images composited inside each box
magick \
    -size ${CANVAS_W}x${CANVAS_H} xc:"#2e3440" \
    \
    -fill "#d8dee9" \
    -font "Liberation-Sans" -pointsize 15 \
    -annotate "+${PADDING}+28" "Selection Segment" \
    \
    -fill "#3b4252" -stroke "#5e6b7d" -strokewidth 1 \
    -draw "roundrectangle ${BOX1_X},${BOX_Y} $((BOX1_X+BOX_W)),$((BOX_Y+BOX_H)) 4,4" \
    -draw "roundrectangle ${BOX2_X},${BOX_Y} $((BOX2_X+BOX_W)),$((BOX_Y+BOX_H)) 4,4" \
    -draw "roundrectangle ${BOX3_X},${BOX_Y} $((BOX3_X+BOX_W)),$((BOX_Y+BOX_H)) 4,4" \
    \
    /tmp/_seg_l.png -geometry "+${BOX1_X}+${BOX_Y}" -composite \
    /tmp/_seg_c.png -geometry "+${BOX2_X}+${BOX_Y}" -composite \
    /tmp/_seg_r.png -geometry "+${BOX3_X}+${BOX_Y}" -composite \
    "$IMG_COMBINED"

# Step 3: Show yad form with composite image on top, then 3 checkboxes aligned below
CHOICE=$(yad --form \
    --class="PolybarDialog" \
    --title="Module Config" \
    --text="" \
    --image="$IMG_COMBINED" \
    --image-on-top \
    --columns=3 \
    --field="Left Segment:CHK"   "TRUE" \
    --field="Center Segment:CHK" "TRUE" \
    --field="Right Segment:CHK"  "TRUE" \
    --button="Cancel:1" \
    --button="Save:0" \
    --center \
    --undecorated \
    --skip-taskbar \
    --css="$YAD_STYLE" \
    --width=$CANVAS_W)

# Exit if cancelled
[ $? -ne 0 ] && exit 1

# Parse result (3 checkboxes)
SHOW_LEFT=$(echo "$CHOICE"   | cut -d'|' -f1)
SHOW_CENTER=$(echo "$CHOICE" | cut -d'|' -f2)
SHOW_RIGHT=$(echo "$CHOICE"  | cut -d'|' -f3)

# Build output strings
OUT_LEFT=" ";   [ "$SHOW_LEFT"   == "TRUE" ] && OUT_LEFT="$DEF_LEFT"
OUT_CENTER=" "; [ "$SHOW_CENTER" == "TRUE" ] && OUT_CENTER="$DEF_CENTER"
OUT_RIGHT=" ";  [ "$SHOW_RIGHT"  == "TRUE" ] && OUT_RIGHT="$DEF_RIGHT"

# Output as piped format consumed by launch.sh
echo "$OUT_LEFT|$OUT_CENTER|$OUT_RIGHT"
