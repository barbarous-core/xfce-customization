#!/bin/bash

# 1. If it's soft-blocked, unblock it first
if rfkill list bluetooth | grep -q "Soft blocked: yes"; then
    rfkill unblock bluetooth
    sleep 0.5 # Give it a moment to wake up
    bluetoothctl power on
    exit 0
fi

# 2. Regular toggle logic
if bluetoothctl show | grep -q "Powered: yes"; then
    bluetoothctl power off
else
    bluetoothctl power on
fi
