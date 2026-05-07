#!/usr/bin/env python3
"""
mocp_data.py — Mono Player Conky Theme
Outputs MOCP player state as key=value lines for Lua to parse.
No external dependencies beyond Python stdlib + mocp.
"""

import subprocess

FORMAT = "STATE=%state\nTITLE=%title\nARTIST=%artist\nALBUM=%album\nCURRSEC=%cs\nTOTSEC=%ts"

FALLBACK = "STATE=STOP\nTITLE=\nARTIST=\nALBUM=\nCURRSEC=0\nTOTSEC=0"

try:
    r = subprocess.run(
        ["mocp", "--format", FORMAT],
        capture_output=True, text=True, timeout=3
    )
    out = r.stdout.strip()
    if r.returncode == 0 and out:
        print(out)
    else:
        print(FALLBACK)
except Exception:
    print(FALLBACK)
