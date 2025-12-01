#!/bin/bash

# HYPROLL - Window Manager for Hyprland
# GitHub: https://github.com/SeVe93/hyproll/
#
#  ~/.config/hypr/hyproll.sh
#
#   1. Сохранить файл
#   2. Сделать исполняемым: chmod +x ~/.config/hypr/hyproll.sh
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


# Расстояние между свернутыми окнами (в пикселях)
WINDOW_SPACING=100

# Высота от нижнего края экрана, куда опускаются окна
# 0 = самый низ экрана, больше = выше
FOLD_HEIGHT_OFFSET=0

# Порог для определения "нижней зоны" (в пикселях от низа экрана)
# Окна ниже этой линии считаются свернутыми
FOLD_ZONE_THRESHOLD=100

# Порог для автоматического сворачивания всех окон
FOLD_THRESHOLD=50

# Максимальное количество записей в истории на рабочий стол
HISTORY_LIMIT=20

# Высота курсора при фокусировке окон
CURSOR_HEIGHT=50


SCRIPT_NAME="hyproll.sh"

# Получаем информацию о мониторе
monitor_info=$(hyprctl monitors -j)
monitor_height=$(echo "$monitor_info" | jq -r '.[0].height')
monitor_width=$(echo "$monitor_info" | jq -r '.[0].width')

# Вычисляем конечную высоту для свернутых окон
FOLD_FINAL_HEIGHT=$((monitor_height - FOLD_HEIGHT_OFFSET))

# Функция для получения ID текущего рабочего стола
get_workspace_id() {
    hyprctl activeworkspace -j | jq -r '.id'
}

WORKSPACE_ID=$(get_workspace_id)
SLOTS_FILE="/tmp/hyproll_slots_$WORKSPACE_ID"
HISTORY_FILE="/tmp/hyproll_history_$WORKSPACE_ID"
SLOT_COUNT=$((monitor_width / WINDOW_SPACING))



refresh_slots_mapping() {
    > "$SLOTS_FILE"
    
    windows=$(hyprctl clients -j | jq "map(select(.workspace.id == $WORKSPACE_ID))")
    
    echo "$windows" | jq -c '.[]' | while read window; do
        address=$(echo "$window" | jq -r '.address')
        x=$(echo "$window" | jq -r '.at[0]')
        y=$(echo "$window" | jq -r '.at[1]')
        
        # Если окно в нижней зоне (используем настраиваемый порог)
        if [ $y -ge $((monitor_height - FOLD_ZONE_THRESHOLD)) ]; then
            slot=$((x / WINDOW_SPACING))
            if [ $slot -lt $SLOT_COUNT ]; then
                echo "$slot:$address" >> "$SLOTS_FILE"
            fi
        fi
    done
    
    # Выравниваем все окна после обновления
    align_folded_windows
}

align_folded_windows() {
    if [ -f "$SLOTS_FILE" ]; then
        # Сортируем слоты
        sort -t: -k1n "$SLOTS_FILE" -o "$SLOTS_FILE"
        
        # Перемещаем каждое окно в правильную позицию
        slot_index=0
        while IFS=: read -r slot address; do
            # Каждое окно идет в свой слот по порядку
            position=$((slot_index * WINDOW_SPACING))
            # Используем настраиваемую высоту
            hyprctl dispatch movewindowpixel exact $position $FOLD_FINAL_HEIGHT,address:$address
            # Обновляем запись с новым слотом
            sed -i "s/^$slot:$address/$slot_index:$address/" "$SLOTS_FILE"
            slot_index=$((slot_index + 1))
        done < "$SLOTS_FILE"
    fi
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
    tail -n $HISTORY_LIMIT "$HISTORY_FILE" > "${HISTORY_FILE}.tmp"
    mv "${HISTORY_FILE}.tmp" "$HISTORY_FILE"
}

# Функция для сохранения позиции окна перед сворачиванием
save_window_position() {
    local address=$1
    local window_json=$(hyprctl clients -j | jq -r ".[] | select(.address == \"$address\")")
    
    if [ -n "$window_json" ]; then
        local current_x=$(echo "$window_json" | jq -r '.at[0]')
        local current_y=$(echo "$window_json" | jq -r '.at[1]')
        
        # Ищем, есть ли уже запись fold для этого окна
        local existing_record=$(grep ":$address:fold:" "$HISTORY_FILE" 2>/dev/null | tail -1)
        if [ -z "$existing_record" ]; then
            # Сохраняем временную запись с placeholder для слота
            echo "temp:$address:fold:$current_x:$current_y" >> "$HISTORY_FILE"
        fi
    fi
}

# Функция для восстановления позиции окна
restore_window_position() {
    local address=$1
    local slot=$2
    
    # Ищем запись с fold для этого окна
    local history_line=$(grep ":$address:fold:" "$HISTORY_FILE" 2>/dev/null | tail -1)
    
    if [ -n "$history_line" ]; then
        local original_x=$(echo "$history_line" | cut -d: -f4)
        local original_y=$(echo "$history_line" | cut -d: -f5)
        
        # Удаляем временную запись
        sed -i "/:$address:fold:/d" "$HISTORY_FILE" 2>/dev/null
        
        # Если координаты не "center"
        if [ "$original_x" != "center" ] && [ "$original_y" != "center" ]; then
            hyprctl dispatch movewindowpixel exact $original_x $original_y,address:$address
            update_history $slot $address "raise" $original_x $original_y
            return 0
        fi
    fi
    
    # Если истории нет или координаты center - центрируем
    hyprctl dispatch centerwindow
    update_history $slot $address "raise" "center" "center"
    return 1
}

raise_window() {
    refresh_slots_mapping
    local slot_number=$1
    
    if [ -f "$SLOTS_FILE" ]; then
        line=$(grep "^$slot_number:" "$SLOTS_FILE")
        if [ -n "$line" ]; then
            address=$(echo "$line" | cut -d: -f2)
            
            restore_window_position "$address" "$slot_number"
            sed -i "/^$slot_number:/d" "$SLOTS_FILE"
        else
            history_line=$(grep "^$slot_number:.*:raise" "$HISTORY_FILE" 2>/dev/null | tail -1)
            if [ -n "$history_line" ]; then
                address=$(echo "$history_line" | cut -d: -f2)
                original_x=$(echo "$history_line" | cut -d: -f4)
                original_y=$(echo "$history_line" | cut -d: -f5)
                
                if hyprctl clients -j | jq -e ".[] | select(.address == \"$address\")" >/dev/null; then
                    # Сначала сохраняем текущую позицию
                    save_window_position "$address"
                    
                    position=$((slot_number * WINDOW_SPACING))
                    # Используем настраиваемую высоту
                    hyprctl dispatch movewindowpixel exact $position $FOLD_FINAL_HEIGHT,address:$address
                    update_slot_mapping $slot_number $address
                    update_history $slot_number $address "fold" $original_x $original_y
                else
                    sed -i "/:$address$/d" "$HISTORY_FILE" 2>/dev/null
                fi
            fi
        fi
    fi
}

# Toggle функция - основная
toggle_active_window() {
    refresh_slots_mapping
    active_window=$(hyprctl activewindow -j)
    
    if [ "$active_window" != "null" ]; then
        address=$(echo "$active_window" | jq -r '.address')
        current_x=$(echo "$active_window" | jq -r '.at[0]')
        current_y=$(echo "$active_window" | jq -r '.at[1]')
        
        # Проверяем, находится ли окно в нижней зоне (используем настраиваемый порог)
        if [ $current_y -ge $((monitor_height - FOLD_ZONE_THRESHOLD)) ]; then
            # Окно в зоне - разворачиваем
            if [ -f "$SLOTS_FILE" ]; then
                line=$(grep ":$address$" "$SLOTS_FILE")
                if [ -n "$line" ]; then
                    slot=$(echo "$line" | cut -d: -f1)
                    
                    # Восстанавливаем позицию
                    restore_window_position "$address" "$slot"
                    sed -i "/^$slot:/d" "$SLOTS_FILE"
                fi
            fi
        else
            # Окно не в зоне - сворачиваем
            # Сначала сохраняем текущую позицию
            save_window_position "$address"
            
            # Ищем свободный слот
            slot_found=-1
            for ((slot=0; slot<SLOT_COUNT; slot++)); do
                if ! grep -q "^$slot:" "$SLOTS_FILE" 2>/dev/null; then
                    slot_found=$slot
                    break
                fi
            done
            
            if [ $slot_found -ge 0 ]; then
                position=$((slot_found * WINDOW_SPACING))
                # Используем настраиваемую высоту
                hyprctl dispatch movewindowpixel exact $position $FOLD_FINAL_HEIGHT,address:$address
                update_slot_mapping $slot_found $address
                update_history $slot_found $address "fold" $current_x $current_y
            else
                # Все слоты заняты - используем первый
                position=0
                hyprctl dispatch movewindowpixel exact $position $FOLD_FINAL_HEIGHT,address:$address
                update_slot_mapping 0 $address
                update_history 0 $address "fold" $current_x $current_y
            fi
        fi
    fi
    
    # Выравниваем все окна
    align_folded_windows
}

# Оригинальная функция fold_active_window
fold_active_window() {
    refresh_slots_mapping
    active_window=$(hyprctl activewindow -j)
    if [ "$active_window" != "null" ]; then
        address=$(echo "$active_window" | jq -r '.address')
        current_x=$(echo "$active_window" | jq -r '.at[0]')
        current_y=$(echo "$active_window" | jq -r '.at[1]')
        
        # Сохраняем позицию перед сворачиванием
        save_window_position "$address"
        
        if ! grep -q ":$address:raise$" "$HISTORY_FILE" 2>/dev/null; then
            for ((slot=0; slot<SLOT_COUNT; slot++)); do
                if ! grep -q "^$slot:" "$SLOTS_FILE" 2>/dev/null; then
                    position=$((slot * WINDOW_SPACING))
                    # Используем настраиваемую высоту
                    hyprctl dispatch movewindowpixel exact $position $FOLD_FINAL_HEIGHT,address:$address
                    update_slot_mapping $slot $address
                    update_history $slot $address "fold" $current_x $current_y
                    break
                fi
            done
        fi
    fi
    
    align_folded_windows
}

# Оригинальная функция для выравнивания всех окон
fold_all_windows() {
    refresh_slots_mapping
    windows=$(hyprctl clients -j | jq "map(select(.workspace.id == $WORKSPACE_ID))")
    
    # Используем оригинальный FOLD_THRESHOLD для этой функции
    folded_windows=$(echo "$windows" | jq "[.[] | select(.at[1] >= $monitor_height - $FOLD_THRESHOLD)] | sort_by(.at[0])")
    folded_count=$(echo "$folded_windows" | jq 'length')

    i=0
    echo "$folded_windows" | jq -c '.[]' | while read window; do
        address=$(echo "$window" | jq -r '.address')
        offset=$((i * WINDOW_SPACING))
        
        # Сохраняем позицию перед перемещением
        save_window_position "$address"
        
        # Используем настраиваемую высоту
        hyprctl dispatch movewindowpixel exact $offset $FOLD_FINAL_HEIGHT,address:$address
        update_slot_mapping $i $address
        
        # Получаем оригинальные координаты для истории
        original_x=$(echo "$window" | jq -r '.at[0]')
        original_y=$(echo "$window" | jq -r '.at[1]')
        update_history $i $address "fold" $original_x $original_y
        
        i=$((i + 1))
    done

    new_offset=$((folded_count * WINDOW_SPACING))
    active_window=$(hyprctl activewindow -j)
    if [ "$active_window" != "null" ]; then
        current_y=$(echo "$active_window" | jq -r '.at[1]')
        # Используем оригинальный FOLD_THRESHOLD
        if [ $current_y -lt $((monitor_height - $FOLD_THRESHOLD)) ]; then
            address=$(echo "$active_window" | jq -r '.address')
            current_x=$(echo "$active_window" | jq -r '.at[0]')
            
            # Сохраняем позицию
            save_window_position "$address"
            
            hyprctl dispatch moveactive exact $new_offset $FOLD_FINAL_HEIGHT
            update_slot_mapping $folded_count $address
            update_history $folded_count $address "fold" $current_x $current_y
        fi
    fi

    # Сохраняем позицию курсора
    cursor_pos=$(hyprctl cursorpos -j)
    cursor_x=$(echo "$cursor_pos" | jq -r '.x')
    cursor_y=$(echo "$cursor_pos" | jq -r '.y')

    # Фокусируем окна в зоне
    if [ -f "$SLOTS_FILE" ]; then
        while IFS=: read -r slot address; do
            hyprctl dispatch focuswindow address:$address
        done < "$SLOTS_FILE"
    fi

    # Возвращаем фокус
    if [ "$active_window" != "null" ]; then
        active_address=$(echo "$active_window" | jq -r '.address')
        if ! grep -q ":$active_address$" "$SLOTS_FILE" 2>/dev/null; then
            hyprctl dispatch focuswindow address:$active_address
        fi
    fi


    target_cursor_y=$((monitor_height - CURSOR_HEIGHT))
    hyprctl dispatch movecursor $cursor_x $target_cursor_y
}





case "$1" in
    "raise")
        raise_window "$2"
        ;;
    "fold")
        fold_all_windows
        ;;
    *)
        toggle_active_window
        ;;
esac
