#!/bin/bash
##https://github.com/SeVe93/
#Меняет кофиг hyprpaper на обои из выбранной папки
#Запуск скрипта чередует обои
#Пример бинда:
#bind = SUPER, P, exec, ~/.config/hypr/wallpaper.sh
#при нажатии происходит смена (чередование) обоев.

#Папка с обоями
WALLPAPER_DIR="$HOME/.config/hypr/wallpapers"

CURRENT_FILE="$HOME/.current_wallpaper"
HYPRPAPER_CONF="$HOME/.config/hypr/hyprpaper.conf"

WALLPAPERS=($(find "$WALLPAPER_DIR" -type f \( -name "*.jpg" -o -name "*.png" -o -name "*.jpeg" -o -name "*.webp" \) | sort))

if [ ${#WALLPAPERS[@]} -eq 0 ]; then
    exit 1
fi

if [ -f "$CURRENT_FILE" ]; then
    CURRENT_INDEX=$(cat "$CURRENT_FILE")
else
    CURRENT_INDEX=0
fi

CURRENT_INDEX=$(( (CURRENT_INDEX + 1) % ${#WALLPAPERS[@]} ))
echo $CURRENT_INDEX > "$CURRENT_FILE"

WALLPAPER="${WALLPAPERS[$CURRENT_INDEX]}"

cat > "$HYPRPAPER_CONF" << EOF
preload = $WALLPAPER
wallpaper = ,$WALLPAPER
EOF

pkill hyprpaper
sleep 0.1
hyprpaper &
