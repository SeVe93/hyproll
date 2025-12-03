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
#   Свернуть/развернуть активное окно
#   bind = SUPER, A, exec, ~/.config/hypr/hyproll.sh
#
#   Развернуть/Свернуть окно в конкретный слот
#   bind = SUPER, 1, exec, ~/.config/hypr/hyproll.sh raise 0
#   bind = SUPER, 2, exec, ~/.config/hypr/hyproll.sh raise 1
#   bind = SUPER, 3, exec, ~/.config/hypr/hyproll.sh raise 2
#   bind = SUPER, 4, exec, ~/.config/hypr/hyproll.sh raise 3

# Расстояние между свернутыми окнами (в пикселях)
WINDOW_SPACING=100

# Высота от нижнего края экрана, куда опускаются окна
# 0 = самый низ экрана, больше = выше
FOLD_HEIGHT_OFFSET=0

# Порог для определения свернутых окон (в пикселях от низа экрана)
# Окна ниже этой линии считаются свернутыми
FOLD_THRESHOLD=100

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

# Простая функция для получения свободного слота
get_free_slot() {
    if [ ! -f "$SLOTS_FILE" ] || [ ! -s "$SLOTS_FILE" ]; then
        echo 0
        return 0
    fi
    
    # Получаем максимальный занятый слот
    max_slot=$(cut -d: -f1 "$SLOTS_FILE" | sort -n | tail -1)
    echo $((max_slot + 1))
}

# Функция для обновления всех свернутых окон
update_folded_windows() {
    # Получаем все свернутые окна
    windows=$(hyprctl clients -j | jq "map(select(.workspace.id == $WORKSPACE_ID and .at[1] >= $((monitor_height - FOLD_THRESHOLD))))")
    
    # Сортируем по X координате
    sorted_windows=$(echo "$windows" | jq -c 'sort_by(.at[0]) | .[]')
    
    > "$SLOTS_FILE"
    
    slot=0
    while read -r window; do
        if [ -n "$window" ]; then
            address=$(echo "$window" | jq -r '.address')
            position=$((slot * WINDOW_SPACING))
            
            # Перемещаем окно
            hyprctl dispatch movewindowpixel exact $position $FOLD_FINAL_HEIGHT,address:$address
            
            # Сохраняем в слоты
            echo "$slot:$address" >> "$SLOTS_FILE"
            
            slot=$((slot + 1))
        fi
    done <<< "$sorted_windows"
}

# Функция для сохранения позиции НЕ свернутого окна
save_window_original_position() {
    local address=$1
    
    # Ищем окно и проверяем что оно не свернуто
    window_info=$(hyprctl clients -j | jq -r ".[] | select(.address == \"$address\")")
    if [ -n "$window_info" ]; then
        current_x=$(echo "$window_info" | jq -r '.at[0]')
        current_y=$(echo "$window_info" | jq -r '.at[1]')
        
        # Сохраняем только если окно НЕ свернуто
        if [ $current_y -lt $((monitor_height - FOLD_THRESHOLD)) ]; then
            # Удаляем старую запись
            sed -i "/:$address$/d" "$HISTORY_FILE" 2>/dev/null
            # Сохраняем новую
            echo "$current_x:$current_y:$address" >> "$HISTORY_FILE"
        fi
    fi
}

# Функция для восстановления позиции окна
restore_window_position() {
    local address=$1
    
    # Ищем сохраненную позицию
    line=$(grep ":$address$" "$HISTORY_FILE" | tail -1)
    if [ -n "$line" ]; then
        x=$(echo "$line" | cut -d: -f1)
        y=$(echo "$line" | cut -d: -f2)
        
        # Перемещаем окно
        hyprctl dispatch movewindowpixel exact $x $y,address:$address
        
        # Удаляем из истории
        sed -i "/:$address$/d" "$HISTORY_FILE" 2>/dev/null
        return 0
    fi
    
    # Если истории нет - центрируем
    hyprctl dispatch centerwindow address:$address
    return 1
}

# Основная функция сворачивания/разворачивания
toggle_active_window() {
    active_window=$(hyprctl activewindow -j)
    
    if [ "$active_window" != "null" ]; then
        address=$(echo "$active_window" | jq -r '.address')
        current_x=$(echo "$active_window" | jq -r '.at[0]')
        current_y=$(echo "$active_window" | jq -r '.at[1]')
        
        # Проверяем, свернуто ли окно
        if [ $current_y -ge $((monitor_height - FOLD_THRESHOLD)) ]; then
            # Окно свернуто - разворачиваем
            
            # Восстанавливаем сохраненную позицию
            restore_window_position "$address"
            
            # Удаляем из слотов
            sed -i "/:$address$/d" "$SLOTS_FILE" 2>/dev/null
            
        else
            # Окно не свернуто - сворачиваем
            
            # Сохраняем текущую позицию (не свернутую)
            save_window_original_position "$address"
            
            # Получаем свободный слот
            slot=$(get_free_slot)
            position=$((slot * WINDOW_SPACING))
            
            # Сворачиваем
            hyprctl dispatch movewindowpixel exact $position $FOLD_FINAL_HEIGHT,address:$address
            
            # Добавляем в слоты
            echo "$slot:$address" >> "$SLOTS_FILE"
        fi
        
        # Обновляем все свернутые окна
        update_folded_windows
    fi
}

# Функция для работы с конкретным слотом
raise_window() {
    local slot_number=$1
    
    # Обновляем список свернутых окон
    update_folded_windows
    
    if [ -f "$SLOTS_FILE" ]; then
        # Проверяем, есть ли окно в этом слоте
        line=$(grep "^$slot_number:" "$SLOTS_FILE")
        
        if [ -n "$line" ]; then
            # Есть окно - разворачиваем его
            address=$(echo "$line" | cut -d: -f2)
            
            # Восстанавливаем позицию
            restore_window_position "$address"
            
            # Удаляем из слотов
            sed -i "/^$slot_number:/d" "$SLOTS_FILE"
            
            # Обновляем все свернутые окна
            update_folded_windows
        else
            # Слот пустой - сворачиваем активное окно в этот слот
            active_window=$(hyprctl activewindow -j)
            if [ "$active_window" != "null" ]; then
                address=$(echo "$active_window" | jq -r '.address')
                current_x=$(echo "$active_window" | jq -r '.at[0]')
                current_y=$(echo "$active_window" | jq -r '.at[1]')
                
                # Проверяем, не свернуто ли уже
                if [ $current_y -lt $((monitor_height - FOLD_THRESHOLD)) ]; then
                    # Сохраняем позицию (не свернутую)
                    save_window_original_position "$address"
                    
                    # Сворачиваем в указанный слот
                    position=$((slot_number * WINDOW_SPACING))
                    hyprctl dispatch movewindowpixel exact $position $FOLD_FINAL_HEIGHT,address:$address
                    
                    # Добавляем в слоты
                    echo "$slot_number:$address" >> "$SLOTS_FILE"
                    
                    # Обновляем все свернутые окна
                    update_folded_windows
                fi
            fi
        fi
    fi
}

# Главная функция
main() {
    case "$1" in
        "raise")
            raise_window "$2"
            ;;
        *)
            toggle_active_window
            ;;
    esac
}

# Запуск скрипта
main "$@"
