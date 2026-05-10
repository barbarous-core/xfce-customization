#!/bin/bash

# Get current layout (first one in the list)
# Note: Layout might be "us" or "ara"
CURRENT=$(setxkbmap -query | grep layout | awk '{print $2}' | cut -d, -f1)

if [ "$CURRENT" == "us" ]; then
    setxkbmap ara,us
else
    setxkbmap us,ara
fi
