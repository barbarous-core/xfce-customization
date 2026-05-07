#!/bin/bash
# =============================================================================
# start_conky.sh
# Kills existing Conky instances and launches the selected theme.
# =============================================================================

# 1. Kill ONLY the conky binary processes (avoiding this script)
pkill -x conky

# Wait a moment for processes to clean up
sleep 0.5

# 2. Select theme (Default: Polycore)
THEME=${1:-"polycore"}

if [ "$THEME" == "polycore" ]; then
    echo "Launching Polycore..."
    conky -c "$HOME/.config/conky/polycore/conkyrc.lua" > /dev/null 2>&1 &
elif [ "$THEME" == "mono" ]; then
    echo "Launching Mono Player..."
    conky -c "$HOME/.config/conky/mono-player/conkyrc_left" > /dev/null 2>&1 &
    conky -c "$HOME/.config/conky/mono-player/conkyrc_center" > /dev/null 2>&1 &
    conky -c "$HOME/.config/conky/mono-player/conkyrc_right" > /dev/null 2>&1 &
elif [ "$THEME" == "lean" ]; then
    echo "Launching Lean Conky Config..."
    bash "$HOME/.config/conky/lean-conky/start-lcc.sh" -n &
elif [ "$THEME" == "rings" ]; then
    echo "Launching Lua Rings..."
    RINGS="$HOME/.config/conky/lua-rings"
    conky -c "$RINGS/rings" > /dev/null 2>&1 &
    sleep 2
    conky -c "$RINGS/cpu" > /dev/null 2>&1 &
    conky -c "$RINGS/mem" > /dev/null 2>&1 &
elif [ "$THEME" == "lightning" ]; then
    echo "Launching Lightning HUD..."
    LT="$HOME/.config/conky/lightning"
    conky -c "$LT/info.rc"      > /dev/null 2>&1 &
    conky -c "$LT/cpu.rc"       > /dev/null 2>&1 &
    conky -c "$LT/mem.rc"       > /dev/null 2>&1 &
    conky -c "$LT/proc.rc"      > /dev/null 2>&1 &
    conky -c "$LT/disk.rc"      > /dev/null 2>&1 &
    conky -c "$LT/shortcuts.rc" > /dev/null 2>&1 &
elif [ "$THEME" == "jinx" ]; then
    echo "Launching Jinx (ncurses terminal theme)..."
    conky -c "$HOME/.config/conky/jinx/jinx.conky"
elif [ "$THEME" == "cards" ]; then
    echo "Launching Conky Cards..."
    bash "$HOME/.config/conky/conky-cards/launch_all.sh"
elif [ "$THEME" == "anurati" ]; then
    echo "Launching Anurati Futuristic..."
    conky -c "$HOME/.config/conky/anurati/Anurati-Futuristic.conf" > /dev/null 2>&1 &
elif [ "$THEME" == "alien" ]; then
    echo "Launching Alien Suite..."
    echo "Run configure-alien.sh first if not done already."
    cd "$HOME/.config/conky/alien" && bash alien-tmux
else
    echo "Unknown theme: $THEME"
    echo "Usage: $0 [polycore|mono|lean|rings|lightning|jinx|cards|alien]"
    exit 1
fi

# 3. Disown the background processes so they don't die when the terminal closes
disown -a

echo "Conky theme '$THEME' launched successfully!"
