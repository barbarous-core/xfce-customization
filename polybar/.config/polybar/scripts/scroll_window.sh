#!/bin/bash

# Configuration
LENGTH=30
SPACING=5
DELAY=0.2

# Get the initial window title
get_title() {
    ID=$(xprop -root _NET_ACTIVE_WINDOW | awk '{print $5}')
    if [ "$ID" == "0x0" ] || [ -z "$ID" ]; then
        echo "Desktop"
    else
        TITLE=$(xprop -id "$ID" _NET_WM_NAME | cut -d '"' -f 2)
        if [ -z "$TITLE" ]; then
            echo "Window"
        else
            echo "$TITLE"
        fi
    fi
}

# Infinite loop for scrolling
TITLE=$(get_title)
LAST_ID=$(xprop -root _NET_ACTIVE_WINDOW | awk '{print $5}')

while true; do
    # Check if window changed
    CURRENT_ID=$(xprop -root _NET_ACTIVE_WINDOW | awk '{print $5}')
    if [ "$CURRENT_ID" != "$LAST_ID" ]; then
        TITLE=$(get_title)
        LAST_ID=$CURRENT_ID
    fi

    # Prepare the string for scrolling (add spacing)
    BASE_TEXT="$TITLE$(printf '%*s' $SPACING)"
    TEXT_LEN=${#BASE_TEXT}
    # Double the text to handle seamless wrap-around
    TEXT="$BASE_TEXT$BASE_TEXT"

    # Only scroll if text is longer than our display length
    if [ ${#TITLE} -gt $LENGTH ]; then
        for (( i=0; i<$TEXT_LEN; i++ )); do
            # Check for window change during scroll
            CHECK_ID=$(xprop -root _NET_ACTIVE_WINDOW | awk '{print $5}')
            if [ "$CHECK_ID" != "$LAST_ID" ]; then break; fi
            
            # Print the substring (now guaranteed to have $LENGTH chars due to doubling)
            echo "${TEXT:$i:$LENGTH}"
            sleep $DELAY
        done
    else
        echo "$TITLE"
        # Sleep a bit longer if not scrolling to save CPU
        sleep 1
    fi
done
