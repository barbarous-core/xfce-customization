#!/usr/bin/env python3
"""
vnstat_data.py — Mono Player Conky Theme
Provides vnstat hourly + monthly data as key=value lines for Lua to parse.
No external dependencies beyond Python stdlib + vnstat + iproute2.
"""

import datetime
import json
import os
import subprocess
import sys

CACHE_DIR = os.getenv("XDG_CACHE_HOME", os.path.expanduser("$HOME/.cache"))
SCROLL_FILE = os.path.join(CACHE_DIR, "monoplayer-vnstat-scroll.idx")
WINDOW = 10   # hours to show at once


# ── helpers ──────────────────────────────────────────────────────────────────

def cvt(n: float) -> str:
    """Convert bytes to human-readable string."""
    for unit in ("B", "KB", "MB", "GB", "TB"):
        if n < 1000 or unit == "TB":
            return f"{n:.1f} {unit}" if unit != "B" else f"{int(n)} B"
        n /= 1000


def get_iface() -> str:
    try:
        r = subprocess.run(["ip", "route", "get", "1.1.1.1"],
                           capture_output=True, text=True, timeout=3)
        parts = r.stdout.split()
        if "dev" in parts:
            return parts[parts.index("dev") + 1]
    except Exception:
        pass
    return "wlo1"


def get_vnstat(iface: str) -> dict:
    try:
        r = subprocess.run(["vnstat", "-i", iface, "--json"],
                           capture_output=True, text=True, timeout=5)
        data = json.loads(r.stdout)
        for ifc in data.get("interfaces", []):
            if ifc["name"] == iface:
                return ifc
        ifaces = data.get("interfaces", [])
        return ifaces[0] if ifaces else {}
    except Exception:
        return {}


# ── main ─────────────────────────────────────────────────────────────────────

NOW   = datetime.datetime.now()
IFACE = get_iface()
RAW   = get_vnstat(IFACE)

# ── hourly (today) ───────────────────────────────────────────────────────────

hours_raw = RAW.get("traffic", {}).get("hour", [])
today: dict[int, dict] = {}
for e in hours_raw:
    d = e.get("date", {})
    if d.get("year") == NOW.year and d.get("month") == NOW.month and d.get("day") == NOW.day:
        h = e.get("time", {}).get("hour", -1)
        if h >= 0:
            today[h] = {"rx": e.get("rx", 0), "tx": e.get("tx", 0),
                        "total": e.get("rx", 0) + e.get("tx", 0)}

n_hours    = len(today)
total_rx   = sum(v["rx"]    for v in today.values()) if today else 0
total_tx   = sum(v["tx"]    for v in today.values()) if today else 0
total_day  = total_rx + total_tx
hourly_avg = total_day / n_hours if n_hours else 0

max_h = max(today, key=lambda h: today[h]["total"]) if today else 0
min_h = min(today, key=lambda h: today[h]["total"]) if today else 0

# ── scroll index ─────────────────────────────────────────────────────────────

try:
    with open(SCROLL_FILE) as f:
        scroll = int(f.read().strip())
except Exception:
    scroll = 0

n_scrollable = max(1, n_hours - WINDOW + 1)
scroll = scroll % n_scrollable
next_scroll = (scroll + 1) % n_scrollable
try:
    with open(SCROLL_FILE, "w") as f:
        f.write(str(next_scroll))
except Exception:
    pass

sorted_h = sorted(today.keys())
window   = sorted_h[scroll : scroll + WINDOW]

# ── monthly ──────────────────────────────────────────────────────────────────

days_raw  = RAW.get("traffic", {}).get("day", [])
month_days = [d for d in days_raw
              if d.get("date", {}).get("year")  == NOW.year
              and d.get("date", {}).get("month") == NOW.month]
month_rx  = sum(d.get("rx", 0) for d in month_days)
month_tx  = sum(d.get("tx", 0) for d in month_days)
month_tot = month_rx + month_tx
month_avg = month_tot / len(month_days) if month_days else 0

if month_days:
    m_max = max(month_days, key=lambda d: d.get("rx",0)+d.get("tx",0))
    m_min = min(month_days, key=lambda d: d.get("rx",0)+d.get("tx",0))
    m_max_tot = m_max.get("rx",0) + m_max.get("tx",0)
    m_min_tot = m_min.get("rx",0) + m_min.get("tx",0)
    m_max_day = f"{m_max['date']['day']:02d}"
    m_min_day = f"{m_min['date']['day']:02d}"
else:
    m_max_tot = m_min_tot = 0
    m_max_day = m_min_day = "--"

# ── output ───────────────────────────────────────────────────────────────────

out = []
out.append(f"IFACE={IFACE}")
out.append(f"N_HOURS={n_hours}")
out.append(f"SCROLL={scroll}")
out.append(f"N_WINDOW={len(window)}")

out.append(f"DAILY_RX={cvt(total_rx)}")
out.append(f"DAILY_TX={cvt(total_tx)}")
out.append(f"DAILY_TOT={cvt(total_day)}")

out.append(f"HOURLY_AVG={cvt(hourly_avg)}")
out.append(f"HOURLY_MAX_H={max_h:02d}")
out.append(f"HOURLY_MAX={cvt(today[max_h]['total']) if today else '---'}")
out.append(f"HOURLY_MIN_H={min_h:02d}")
out.append(f"HOURLY_MIN={cvt(today[min_h]['total']) if today else '---'}")

out.append(f"MONTH_RX={cvt(month_rx)}")
out.append(f"MONTH_TX={cvt(month_tx)}")
out.append(f"MONTH_TOT={cvt(month_tot)}")
out.append(f"MONTH_AVG={cvt(month_avg)}")
out.append(f"MONTH_MAX={cvt(m_max_tot)} (day {m_max_day})")
out.append(f"MONTH_MIN={cvt(m_min_tot)} (day {m_min_day})")
out.append(f"N_MONTH_DAYS={len(month_days)}")

for i, h in enumerate(window):
    e = today[h]
    flags = ""
    if h == max_h:   flags += "M"
    if h == min_h:   flags += "m"
    if h == NOW.hour: flags += ">"
    out.append(f"H{i}_H={h:02d}")
    out.append(f"H{i}_RX={cvt(e['rx'])}")
    out.append(f"H{i}_TX={cvt(e['tx'])}")
    out.append(f"H{i}_TOT={cvt(e['total'])}")
    out.append(f"H{i}_RAW={e['total']}")
    out.append(f"H{i}_FLAG={flags}")

print("\n".join(out))
