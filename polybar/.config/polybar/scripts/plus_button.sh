#!/bin/bash

# Configuration
MAX_WORKSPACES=18
PRIMARY_COLOR="#F0C674"
DISABLED_COLOR="#707880"

# Get current count
CURRENT_COUNT=$(xfconf-query -c xfwm4 -p /general/workspace_count)

if [ "$CURRENT_COUNT" -ge "$MAX_WORKSPACES" ]; then
    # Show Lock icon in grey if full
    echo "%{F$DISABLED_COLOR}  %{F-}"
else
    # Show Plus icon in primary color if there is space
    echo "%{F$PRIMARY_COLOR}  %{F-}"
fi
