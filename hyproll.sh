#!/bin/bash

# HYPROLL - Window Manager for Hyprland
# GitHub: https://github.com/SeVe93/hyproll/
#
#  ~/.config/hypr/hyproll.sh
#
#   1. Сохранить файл
#   2. Сделать исполняемым: chmod +x ~/.config/hypr/scripts/hyproll.sh
#   3. Добавить бинды в hyprland.conf
#
# БИНДЫ ДЛЯ hyprland.conf:
#
#   Свернуть активное окно
#   bind = SUPER, A, exec, ~/.config/hypr/hyproll.sh
#
#   Развернуть/Свернуть окно в центр экрана. Сворачивает на ту же позицию
#   bind = SUPER, 1, exec, ~/.config/hypr/scripts/hyproll.sh raise 0
#   bind = SUPER, 2, exec, ~/.config/hypr/scripts/hyproll.sh raise 1
#   bind = SUPER, 3, exec, ~/.config/hypr/scripts/hyproll.sh raise 2
#   bind = SUPER, 4, exec, ~/.config/hypr/scripts/hyproll.sh raise 3

#Настройки
SCRIPT_NAME="hyproll.sh"
#Видимое расстояние между окнами
WINDOW_SPACING=100
#Высота области бара
FOLD_THRESHOLD=50
RECALC_DELAY=0.1
DIRECTION="left"

monitor_info=$(hyprctl monitors -j)
monitor_height=$(echo "$monitor_info" | jq -r '.[0].height')
monitor_width=$(echo "$monitor_info" | jq -r '.[0].width')

SLOTS_FILE="/tmp/hyproll_slots"
HISTORY_FILE="/tmp/hyproll_history"
SLOT_COUNT=$((monitor_width / WINDOW_SPACING))

refresh_slots_mapping() {
    > "$SLOTS_FILE"
    
    windows=$(hyprctl clients -j | jq "map(select(.workspace.id == $(hyprctl activeworkspace -j | jq -r '.id')))")
    
    echo "$windows" | jq -c '.[]' | while read window; do
        address=$(echo "$window" | jq -r '.address')
        x=$(echo "$window" | jq -r '.at[0]')
        y=$(echo "$window" | jq -r '.at[1]')
        
        if [ $y -ge $((monitor_height - 100)) ]; then
            slot=$((x / WINDOW_SPACING))
            if [ $slot -lt $SLOT_COUNT ]; then
                echo "$slot:$address" >> "$SLOTS_FILE"
            fi
        fi
    done
}

update_slot_mapping() {
    local slot=$1
    local address=$2
    sed -i "/^$slot:/d" "$SLOTS_FILE" 2>/dev/null
    echo "$slot:$address" >> "$SLOTS_FILE"
}

update_history() {
    local slot=$1
    local address=$2
    local action=$3
    local x=$4
    local y=$5
    
    echo "$slot:$address:$action:$x:$y" >> "$HISTORY_FILE"
    tail -n 10 "$HISTORY_FILE" > "${HISTORY_FILE}.tmp"
    mv "${HISTORY_FILE}.tmp" "$HISTORY_FILE"
}

raise_window() {
    refresh_slots_mapping
    local slot_number=$1
    
    if [ -f "$SLOTS_FILE" ]; then
        line=$(grep "^$slot_number:" "$SLOTS_FILE")
        if [ -n "$line" ]; then
            address=$(echo "$line" | cut -d: -f2)
            
            history_line=$(grep "^$slot_number:$address:fold" "$HISTORY_FILE" 2>/dev/null | tail -1)
            if [ -n "$history_line" ]; then
                original_x=$(echo "$history_line" | cut -d: -f4)
                original_y=$(echo "$history_line" | cut -d: -f5)
                
                hyprctl dispatch focuswindow address:$address
                hyprctl dispatch movewindowpixel exact $original_x $original_y,address:$address
                sed -i "/^$slot_number:/d" "$SLOTS_FILE"
                update_history $slot_number $address "raise" $original_x $original_y
            else
                hyprctl dispatch focuswindow address:$address
                hyprctl dispatch centerwindow
                sed -i "/^$slot_number:/d" "$SLOTS_FILE"
                update_history $slot_number $address "raise" "center" "center"
            fi
        else
            history_line=$(grep "^$slot_number:.*:raise" "$HISTORY_FILE" 2>/dev/null | tail -1)
            if [ -n "$history_line" ]; then
                address=$(echo "$history_line" | cut -d: -f2)
                original_x=$(echo "$history_line" | cut -d: -f4)
                original_y=$(echo "$history_line" | cut -d: -f5)
                
                if hyprctl clients -j | jq -e ".[] | select(.address == \"$address\")" >/dev/null; then
                    position=$((slot_number * WINDOW_SPACING))
                    hyprctl dispatch movewindowpixel exact $position $monitor_height,address:$address
                    update_slot_mapping $slot_number $address
                    update_history $slot_number $address "fold" $original_x $original_y
                else
                    sed -i "/:$address$/d" "$HISTORY_FILE" 2>/dev/null
                fi
            fi
        fi
    fi
}

fold_active_window() {
    refresh_slots_mapping
    active_window=$(hyprctl activewindow -j)
    if [ "$active_window" != "null" ]; then
        address=$(echo "$active_window" | jq -r '.address')
        current_x=$(echo "$active_window" | jq -r '.at[0]')
        current_y=$(echo "$active_window" | jq -r '.at[1]')
        
        if ! grep -q ":$address:raise$" "$HISTORY_FILE" 2>/dev/null; then
            for ((slot=0; slot<SLOT_COUNT; slot++)); do
                if ! grep -q "^$slot:" "$SLOTS_FILE" 2>/dev/null; then
                    position=$((slot * WINDOW_SPACING))
                    hyprctl dispatch movewindowpixel exact $position $monitor_height,address:$address
                    update_slot_mapping $slot $address
                    update_history $slot $address "fold" $current_x $current_y
                    break
                fi
            done
        fi
    fi
}

case "$1" in
    "raise")
        raise_window "$2"
        ;;
    "fold")
        fold_active_window
        ;;
    *)
        refresh_slots_mapping
        windows=$(hyprctl clients -j | jq "map(select(.workspace.id == $(hyprctl activeworkspace -j | jq -r '.id')))")
        
        folded_windows=$(echo "$windows" | jq "[.[] | select(.at[1] >= $monitor_height - $FOLD_THRESHOLD)] | sort_by(.at[0])")
        folded_count=$(echo "$folded_windows" | jq 'length')

        i=0
        echo "$folded_windows" | jq -c '.[]' | while read window; do
            address=$(echo "$window" | jq -r '.address')
            offset=$((i * WINDOW_SPACING))
            hyprctl dispatch movewindowpixel exact $offset $monitor_height,address:$address
            update_slot_mapping $i $address
            i=$((i + 1))
        done

        new_offset=$((folded_count * WINDOW_SPACING))
        active_window=$(hyprctl activewindow -j)
        if [ "$active_window" != "null" ]; then
            current_y=$(echo "$active_window" | jq -r '.at[1]')
            if [ $current_y -lt $((monitor_height - $FOLD_THRESHOLD)) ]; then
                current_x=$(echo "$active_window" | jq -r '.at[0]')
                hyprctl dispatch moveactive exact $new_offset $monitor_height
                update_slot_mapping $folded_count $(echo "$active_window" | jq -r '.address')
                update_history $folded_count $(echo "$active_window" | jq -r '.address') "fold" $current_x $current_y
            fi
        fi

        # Сохраняем позицию курсора перед фокусами
        cursor_pos=$(hyprctl cursorpos -j)
        cursor_x=$(echo "$cursor_pos" | jq -r '.x')
        cursor_y=$(echo "$cursor_pos" | jq -r '.y')

        # Поднимаем все окна в зоне наверх
        if [ -f "$SLOTS_FILE" ]; then
            while IFS=: read -r slot address; do
                hyprctl dispatch focuswindow address:$address
            done < "$SLOTS_FILE"
        fi

        # Возвращаем фокус активному окну если оно не в зоне
        if [ "$active_window" != "null" ]; then
            active_address=$(echo "$active_window" | jq -r '.address')
            if ! grep -q ":$active_address$" "$SLOTS_FILE" 2>/dev/null; then
                hyprctl dispatch focuswindow address:$active_address
            fi
        fi

        # Восстанавливаем позицию курсора
        hyprctl dispatch movecursor $cursor_x $cursor_y
        ;;
esac
