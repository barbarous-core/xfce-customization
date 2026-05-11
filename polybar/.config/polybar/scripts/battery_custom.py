#!/usr/bin/env python3
import os
import sys
import time

def read_file(path):
    try:
        with open(path, 'r') as f: 
            return f.read().strip()
    except Exception:
        return ""

STATE_FILE = "/tmp/battery_toggle_state"

def toggle():
    if not os.path.exists(STATE_FILE) or read_file(STATE_FILE) == "icon":
        with open(STATE_FILE, 'w') as f: f.write("full")
    else:
        with open(STATE_FILE, 'w') as f: f.write("icon")

def main():
    # Handle toggle argument
    if len(sys.argv) > 1 and sys.argv[1] == "--toggle":
        toggle()
        return

    base = "/sys/class/power_supply/BAT0/"
    if not os.path.exists(base):
        print("No Battery", flush=True)
        return
        
    blink_state = True

    while True:
        status = read_file(base + "status")
        cap_str = read_file(base + "capacity")
        capacity = int(cap_str) if cap_str else 0

        # Choose vertical icons (reverting to your preferred style)
        if status == "Charging":
            if capacity < 30: icon = "󱊤"
            elif capacity <= 70: icon = "󱊥"
            else: icon = "󱊦"
        else: # Discharging or Full
            if capacity < 30: icon = "󱊡"
            elif capacity <= 65: icon = "󱊢"
            else: icon = "󱊣"

        # Define colors
        color = "#C5C8C6"
        if status == "Charging":
            color = "#00FFFF" if blink_state else "#555555"
        elif status == "Full" or capacity >= 98:
            color = "#00FF00"
        else:
            if capacity < 30: 
                color = "#FF0000" if blink_state else "#555555"
            elif capacity < 65: 
                color = "#FFA500"
            else:
                color = "#00FF00"

        # Check global state
        GLOBAL_STATE_FILE = "/tmp/polybar_active_module"
        active_module = read_file(GLOBAL_STATE_FILE)
        show_full = active_module == "battery"

        # Font index T3 (size 14) to keep vertical icons small
        font_index = "T3"

        if show_full:
            print(f"%{{F{color}}}%{{{font_index}}}{icon}%{{T-}} {capacity}%%{{F-}}", flush=True)
        else:
            print(f"%{{F{color}}}%{{{font_index}}}{icon}%{{T-}}%{{F-}}", flush=True)

        blink_state = not blink_state
        time.sleep(0.5 if status == "Charging" or capacity < 30 else 2.0)

if __name__ == "__main__":
    main()
