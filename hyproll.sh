#!/bin/bash

https://github.com/SeVe93/hyproll/

SCRIPT_NAME="hyproll.sh"
WINDOW_SPACING=100
FOLD_THRESHOLD=50
RECALC_DELAY=0.1
DIRECTION="left"

monitor_info=$(hyprctl monitors -j)
monitor_height=$(echo "$monitor_info" | jq -r '.[0].height')
monitor_width=$(echo "$monitor_info" | jq -r '.[0].width')

windows=$(hyprctl clients -j | jq "map(select(.workspace.id == $(hyprctl activeworkspace -j | jq -r '.id')))")
folded_windows=$(echo "$windows" | jq "[.[] | select(.at[1] >= $monitor_height - $FOLD_THRESHOLD)] | sort_by(.at[0])")

folded_count=$(echo "$folded_windows" | jq 'length')

i=0
echo "$folded_windows" | jq -c '.[]' | while read window; do
    address=$(echo "$window" | jq -r '.address')
    offset=$((i * WINDOW_SPACING))
    
    hyprctl dispatch movewindowpixel exact $offset $monitor_height,address:$address
    i=$((i + 1))
done

new_offset=$((folded_count * WINDOW_SPACING))

active_window=$(hyprctl activewindow -j)
if [ "$active_window" != "null" ]; then
    current_y=$(echo "$active_window" | jq -r '.at[1]')
    if [ $current_y -lt $((monitor_height - $FOLD_THRESHOLD)) ]; then
        hyprctl dispatch moveactive exact $new_offset $monitor_height
    fi
fi
