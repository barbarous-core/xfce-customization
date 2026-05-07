#!/usr/bin/env bash
# =============================================================================
#  launch.sh — Polybar launcher for XFCE / Fedora 43
#
#  Usage:
#    ./launch.sh              → launch all bars on all monitors
#    ./launch.sh --top-only   → launch only the top bar
#    ./launch.sh --bottom-only→ launch only the bottom bar
#
#  Bars: top  (workspaces + status)
#        bottom (tray + disk + mocp)
# =============================================================================

# Ensure X utilities are on PATH (needed when called from XFCE autostart)
export PATH="/usr/bin:/usr/local/bin:$PATH"

set -euo pipefail

CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/polybar"
CONFIG="$CONFIG_DIR/config.ini"
LOG="$CONFIG_DIR/polybar.log"

# --------------------------------------------------------------------------- #
#  Flags
# --------------------------------------------------------------------------- #
TOP=true
BOTTOM=true

for arg in "$@"; do
  case $arg in
    --top-only)    BOTTOM=false ;;
    --bottom-only) TOP=false    ;;
    --help|-h)
      echo "Usage: $(basename "$0") [--top-only | --bottom-only]"
      exit 0
      ;;
  esac
done

# --------------------------------------------------------------------------- #
#  Kill any running instances
# --------------------------------------------------------------------------- #
echo "-- Terminating existing Polybar instances --"
pkill -x polybar 2>/dev/null || true
sleep 0.5

# --------------------------------------------------------------------------- #
#  Detect monitors via polybar --list-monitors (no xrandr dependency)
# --------------------------------------------------------------------------- #
mapfile -t MONITORS < <(polybar --list-monitors 2>/dev/null | awk -F: '{print $1}')

if [[ ${#MONITORS[@]} -eq 0 ]]; then
  echo "[ERROR] No connected monitors found." >&2
  exit 1
fi

echo "Found ${#MONITORS[@]} monitor(s): ${MONITORS[*]}"

# --------------------------------------------------------------------------- #
#  Fix hwmon path — coretemp hwmonN number changes on every reboot
# --------------------------------------------------------------------------- #
HWMON_PATH=$(find /sys/devices/platform/coretemp.0/hwmon -name "temp1_input" 2>/dev/null | head -1)
RUNTIME_CONFIG="$CONFIG_DIR/config.runtime.ini"

if [[ -n "$HWMON_PATH" ]]; then
  echo "Detected CPU hwmon: $HWMON_PATH"
  sed "s|hwmon-path.*=.*|hwmon-path      = $HWMON_PATH|" "$CONFIG" > "$RUNTIME_CONFIG"
else
  echo "[WARN] Could not detect coretemp hwmon path, using config as-is."
  cp "$CONFIG" "$RUNTIME_CONFIG"
fi

# Point to the patched runtime copy
CONFIG="$RUNTIME_CONFIG"

# --------------------------------------------------------------------------- #
#  Launch bars
# --------------------------------------------------------------------------- #
launch_bar() {
  local bar="$1"
  local monitor="$2"
  echo "Launching bar/$bar on $monitor ..."
  MONITOR="$monitor" polybar --config="$CONFIG" "$bar" >> "$LOG" 2>&1 &
  disown
}

: > "$LOG"   # truncate log

for monitor in "${MONITORS[@]}"; do
  $TOP    && launch_bar "top"    "$monitor"
  $BOTTOM && launch_bar "bottom" "$monitor"
  sleep 0.2
done

echo "-- All Polybar instances launched. Log: $LOG --"
