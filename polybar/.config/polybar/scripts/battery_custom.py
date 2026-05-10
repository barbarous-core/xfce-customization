#!/usr/bin/env python3
import os

def read_file(path):
    try:
        with open(path, 'r') as f: 
            return f.read().strip()
    except Exception:
        return ""

def main():
    base = "/sys/class/power_supply/BAT0/"
    if not os.path.exists(base):
        print("No Battery")
        return
        
    status = read_file(base + "status")
    
    cap_str = read_file(base + "capacity")
    capacity = int(cap_str) if cap_str else 0

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
            # Handle rounding overflow
            if m == 60:
                h += 1
                m = 0
            formatted_time = f"{h:02d}:{m:02d}"

    # Choose icon based on capacity
    if capacity < 20: icon = ""
    elif capacity < 40: icon = ""
    elif capacity < 60: icon = ""
    elif capacity < 80: icon = ""
    else: icon = ""

    # Define colors
    color = "#C5C8C6"
    if status == "Charging":
        color = "#00FFFF"
    elif status == "Full" or capacity >= 98:
        color = "#00FF00"
    else:
        if capacity < 30: 
            color = "#FF0000"
        elif capacity < 60: 
            color = "#FFA500"

    # Define text
    text = f"{capacity}%"
    if status == "Full" or capacity >= 98:
        text = f"{capacity}% Full"
    elif formatted_time:
        text = f"{capacity}% {formatted_time}"

    # Output formatted string for Polybar
    print(f"%{{F{color}}}%{{T3}}{icon}%{{T-}} {text}%{{F-}}", flush=True)

if __name__ == "__main__":
    main()
