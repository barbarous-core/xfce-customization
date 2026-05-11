#!/bin/bash

STATE_FILE="/tmp/polybar_active_module"
TARGET_MODULE=$1

# Create file if it doesn't exist
[ ! -f "$STATE_FILE" ] && echo "none" > "$STATE_FILE"

CURRENT_ACTIVE=$(cat "$STATE_FILE")

if [ "$CURRENT_ACTIVE" == "$TARGET_MODULE" ]; then
    # If clicking the same module, collapse everything
    echo "none" > "$STATE_FILE"
else
    # Set the new module as the only active one
    echo "$TARGET_MODULE" > "$STATE_FILE"
fi
