#!/bin/bash

# Configuration
DEFAULT_SSID="$(hostname)_AP"
DEFAULT_PW="$(hostname)_AP"
IFACE="wlp0s20f3"

# Polybar Colors
BG="#282A2E"
FG="#C5C8C6"
ACCENT="#F0C674"
ALT="#373B41"

# Create CSS for YAD (including entry styling)
STYLE="* { 
    background-color: $BG; 
    color: $FG; 
    font-family: 'JetBrainsMono Nerd Font', sans-serif;
}
#yad-window { 
    border: 2px solid $ALT;
    border-radius: 12px;
}
entry { 
    background-color: $ALT;
    color: $FG;
    border: 1px solid $ACCENT;
    border-radius: 4px;
    padding: 5px;
    margin: 5px;
}
button { 
    background-image: none;
    background-color: $ALT;
    border: 1px solid $ACCENT;
    border-radius: 6px;
    padding: 8px 15px;
    font-weight: bold;
}
button:hover { 
    background-color: $ACCENT;
    color: $BG;
}
"

# UI using YAD --form
RESULT=$(yad --form --title="Hotspot Manager" --window-icon="network-wireless-hotspot" \
    --css=<(echo "$STYLE") \
    --text="<span font='12'><b>Configure your Hotspot</b></span>\n" \
    --field="SSID Name" "$DEFAULT_SSID" \
    --field="Password" "$DEFAULT_PW" \
    --button="Creation Hotspot:0" \
    --button="Cancel:1" \
    --center --width=400 --fixed --borders=15)

if [ $? -eq 0 ]; then
    # Parse result (values separated by |)
    NEW_SSID=$(echo "$RESULT" | cut -d'|' -f1)
    NEW_PW=$(echo "$RESULT" | cut -d'|' -f2)

    # Validate inputs
    if [ -z "$NEW_SSID" ] || [ ${#NEW_PW} -lt 8 ]; then
        notify-send "Hotspot Error" "SSID cannot be empty and Password must be at least 8 characters."
        exit 1
    fi

    # Kill any existing connection with this SSID
    nmcli connection down "$NEW_SSID" 2>/dev/null
    
    notify-send "Hotspot" "Activating $NEW_SSID..."
    
    # Run creation command
    nmcli device wifi hotspot ifname "$IFACE" ssid "$NEW_SSID" password "$NEW_PW"
    
    if [ $? -eq 0 ]; then
        notify-send "Hotspot" "Success! $NEW_SSID is now active."
    else
        notify-send "Hotspot Error" "Failed to create hotspot."
    fi
fi
