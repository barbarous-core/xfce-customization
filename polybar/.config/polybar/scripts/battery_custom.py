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
    GLOBAL_STATE_FILE = "/tmp/polybar_active_module"
    current = ""
    if os.path.exists(GLOBAL_STATE_FILE):
        with open(GLOBAL_STATE_FILE, 'r') as f:
            current = f.read().strip()
    
    with open(GLOBAL_STATE_FILE, 'w') as f:
        if current == "battery":
            f.write("none")
        else:
            f.write("battery")

def get_theme_colors():
    colors_conf = os.path.expanduser("~/.config/polybar/colors.ini")
    theme_colors = {
        "success": "#00FF00", 
        "warning": "#FFA500", 
        "alert": "#FF0000",
        "disabled": "#555555"
    }
    if os.path.exists(colors_conf):
        try:
            with open(colors_conf, 'r') as f:
                for line in f:
                    if '=' in line:
                        k, v = line.split('=')
                        k = k.strip()
                        v = v.strip()
                        if k in theme_colors:
                            theme_colors[k] = v
        except Exception:
            pass
    return theme_colors

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
        
        theme_colors = get_theme_colors()

        # Time Calculation
        charge_now = 0.0
        current_now = 0.0
        charge_full = 0.0
        
        # Try charge variables (Ah)
        cn = read_file(base + "charge_now")
        curr = read_file(base + "current_now")
        cf = read_file(base + "charge_full")
        
        if cn and curr and cf:
            charge_now = float(cn)
            current_now = float(curr)
            charge_full = float(cf)
        else:
            # Try energy variables (Wh)
            en = read_file(base + "energy_now")
            pwr = read_file(base + "power_now")
            ef = read_file(base + "energy_full")
            if en and pwr and ef:
                charge_now = float(en)
                current_now = float(pwr)
                charge_full = float(ef)

        formatted_time = ""
        if current_now > 0:
            if status == "Discharging":
                hours = charge_now / current_now
            elif status == "Charging":
                hours = (charge_full - charge_now) / current_now
            else:
                hours = 0
                
            if hours > 0:
                h = int(hours)
                m = int(round((hours - h) * 60))
                if m == 60: h += 1; m = 0
                formatted_time = f"({h:02d}:{m:02d})"

        # Choose icons
        if status == "Charging":
            if capacity < 30: icon = "󱊤"
            elif capacity <= 70: icon = "󱊥"
            else: icon = "󱊦"
        else:
            if capacity < 30: icon = "󱊡"
            elif capacity <= 65: icon = "󱊢"
            else: icon = "󱊣"

        # Power Saving Logic
        POWER_SAVING_FILE = "/tmp/polybar_power_saving"
        is_power_saving = os.path.exists(POWER_SAVING_FILE)

        # Define colors
        color = "#C5C8C6"
        disabled_color = theme_colors.get("disabled", "#555555")

        if status == "Charging":
            # Alter between electric blue and theme disabled color
            if is_power_saving:
                color = "#00FFFF" # No blinking in power saving
            else:
                color = "#00FFFF" if blink_state else disabled_color
        elif status == "Full" or capacity >= 98:
            color = theme_colors["success"]
        else:
            if capacity < 30: 
                # Alert color with blink for low battery
                if is_power_saving:
                    color = theme_colors["alert"] # No blinking
                else:
                    color = theme_colors["alert"] if blink_state else disabled_color
            elif capacity < 65: 
                color = theme_colors["warning"]
            else:
                color = theme_colors["success"]

        # Check global state
        GLOBAL_STATE_FILE = "/tmp/polybar_active_module"
        active_module = read_file(GLOBAL_STATE_FILE)
        show_full = active_module == "battery"

        # Output
        if status == "Charging":
            font_index = "T6"
        else:
            font_index = "T3"
            
        if show_full:
            text = f"{capacity}% {formatted_time}"
            print(f"%{{F{color}}}%{{{font_index}}}{icon}%{{T-}} {text}%{{F-}}", flush=True)
        else:
            print(f"%{{F{color}}}%{{{font_index}}}{icon}%{{T-}}%{{F-}}", flush=True)

        blink_state = not blink_state
        
        if is_power_saving:
            time.sleep(10.0) # Long sleep in power saving
        else:
            time.sleep(1.0 if status == "Charging" or capacity < 30 else 2.0)

if __name__ == "__main__":
    main()
