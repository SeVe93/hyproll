#!/bin/bash

# Addict: sudo pacman -S hyprland jq

SCRIPT_NAME="hyproll.sh"
WINDOW_SPACING=100
FOLD_THRESHOLD=50
RECALC_DELAY=0.1
# Direction: "left" or "right"
DIRECTION="left"

monitor_info=$(hyprctl monitors -j)
monitor_height=$(echo "$monitor_info" | jq -r '.[0].height')
monitor_width=$(echo "$monitor_info" | jq -r '.[0].width')

windows=$(hyprctl clients -j | jq "map(select(.workspace.id == $(hyprctl activeworkspace -j | jq -r '.id')))")
folded_windows=$(echo "$windows" | jq "[.[] | select(.at[1] >= $monitor_height - $FOLD_THRESHOLD)] | sort_by(.at[0])")

folded_count=$(echo "$folded_windows" | jq 'length')

# Calculate new offset based on direction
if [ "$DIRECTION" = "right" ]; then
    new_offset=$((monitor_width - WINDOW_SPACING))
else
    new_offset=$((folded_count * $WINDOW_SPACING))
fi

active_window=$(hyprctl activewindow -j)
if [ "$active_window" != "null" ]; then
    current_y=$(echo "$active_window" | jq -r '.at[1]')
    if [ $current_y -lt $((monitor_height - $FOLD_THRESHOLD)) ]; then
        hyprctl dispatch moveactive exact $new_offset $monitor_height
    fi
fi

sleep $RECALC_DELAY

windows=$(hyprctl clients -j | jq "map(select(.workspace.id == $(hyprctl activeworkspace -j | jq -r '.id')))")
folded_windows=$(echo "$windows" | jq "[.[] | select(.at[1] >= $monitor_height - $FOLD_THRESHOLD)] | sort_by(.at[0])")

# For right direction, we need to reverse the order
if [ "$DIRECTION" = "right" ]; then
    folded_windows=$(echo "$folded_windows" | jq 'reverse')
fi

i=0
echo "$folded_windows" | jq -c '.[]' | while read window; do
    address=$(echo "$window" | jq -r '.address')
    
    # Calculate offset based on direction
    if [ "$DIRECTION" = "right" ]; then
        offset=$((monitor_width - (i + 1) * WINDOW_SPACING))
    else
        offset=$((i * $WINDOW_SPACING))
    fi
    
    hyprctl dispatch movewindowpixel exact $offset $monitor_height,address:$address
    i=$((i + 1))
done
