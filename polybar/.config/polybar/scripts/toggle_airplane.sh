#!/bin/bash

# Get current WiFi state
WIFI_STATE=$(nmcli radio wifi)

if [ "$WIFI_STATE" == "enabled" ]; then
    # Turning Airplane Mode ON (Radios OFF)
    nmcli radio wifi off
    bluetoothctl power off
else
    # Turning Airplane Mode OFF (Radios ON)
    nmcli radio wifi on
    bluetoothctl power on
fi

# Notify the connection_status script to refresh immediately
PID=$(pgrep -f "connection_status.sh")
if [ -n "$PID" ]; then
    kill -USR1 $PID 2>/dev/null
fi
