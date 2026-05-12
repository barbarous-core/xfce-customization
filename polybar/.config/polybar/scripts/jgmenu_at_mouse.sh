#!/bin/bash

# Kill any running jgmenu first to ensure fresh reload
pkill -x jgmenu

# Launch jgmenu at the mouse position
# --at-pointer handles the coordinates automatically using X11
jgmenu --at-pointer
