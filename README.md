<!DOCTYPE html>
<html>
<head>
<meta charset="UTF-8">

</head>
<body>

<p><code>hyproll.sh</code>Hyprland bash-script: быстрое "свертывание" и развертывание окон Hyprland, сохраняя содержимое, размер и положение в пространстве.</p>

<p>hyprctl + hyprpm + bash + jq<br>
Очень легкое решение распределения пространства Hyprland</p>

https://github.com/user-attachments/assets/2298bf8b-6a8b-4eae-b4ba-7c21cfdc0656



<h2>Основная функциональность:</h2>
<p>делит ширину экрана на равные ячейки с заданной длинной. </p>
<p>При запуске скрипта - проверяет актуальное положение окон, опускает активное окно ниже уровня экрана в зону свободной ячейки</p>
<p>При запуске скрипта с функцией "hyproll.sh raise №" - возвращает окно в положение "до сворачивания" . повторный запус функции возвращает окно в наш "трей" </p>
<p>Работает только при обращении к скрипту: никаких демонов, гасится по завершению исполнения</p>

https://github.com/user-attachments/assets/e629e042-2dcb-4fc8-8799-b2e3236af6ab

<h2>Баги:</h2>
<p>Могут быть проблемы с фокуссировкой на активное окно.   </p>


<h2>Переменные конфигурации:</h2>
расстояние между окнами
<code>WINDOW_SPACING=100 </code></p>
 порог для определения свернутых окон
<code>FOLD_THRESHOLD=50 </code></p>
 задержка перед перерасчетом позиций
<code>RECALC_DELAY=0.1</code></p>



<h2>Зависимости:</h2>

<ul>
<li>[hyprland - оконный менеджер](https://hypr.land/)</li>
<li>[hyprplugins/hyprbar - шапка](https://github.com/hyprwm/hyprland-plugins)</li>
<li>jq - для работы с JSON<br>
<code>sudo pacman -S jq</code></li>
</ul>

<hr>

<h2>Пример конфига Hyprland и запуск:</h2>

<p>Помещаем скрипт в папку конфига Hyprland<br>
<code>~/.config/hypr/hyproll.sh</code></p>

<p>Делаем исполняемым<br>
<code>chmod +x ~/.config/hypr/hyproll.sh</code></p>

<p>Устанавливаем jq - для работы с JSON<br>
<code>sudo pacman -S jq</code></p>






<p>В начало конфига Hyprland</p>
активируем плагин hyprbars
<code>exec-once = hyprpm reload</code>

<p>Бинд для разворачивания/сворачивания по номеру</p>
<code>bind = SUPER, 1, exec, ~/.config/hypr/scripts/hyproll.sh raise 0</code>

<p>Бинд для "Сворачивания"</p>
<code>bind = SUPER, A, exec, ~/.config/hypr/hyproll.sh</code>

<h2>Быстрая установка</h2>

<pre><code id="installCommand">sudo pacman -S --needed jq && hyprpm update 2>/dev/null && (hyprpm list | grep -q "hyprland-plugins" || hyprpm add https://github.com/hyprwm/hyprland-plugins) && (hyprpm list | grep -q "hyprbars" && echo "hyprbars уже включен" || hyprpm enable hyprbars) && (git clone https://github.com/SeVe93/hyproll /tmp/hyproll_tmp && cp /tmp/hyproll_tmp/hyproll.sh ~/.config/hypr/hyproll.sh && chmod +x ~/.config/hypr/hyproll.sh && rm -rf /tmp/hyproll_tmp && echo "hyproll скрипт обновлен") && (grep -q "plugin.hyprbars {" ~/.config/hypr/hyprland.conf || echo -e "\n# hyprbars config\nplugin {\n    hyprbars {\n        bar_height = 25\n        icon_on_hover = true\n        bar_color = rgb(252530)\n        col.text = rgb(466670)\n        bar_text_font = Sans\n        bar_text_size = 10\n        bar_text_align = left\n        bar_padding = 10\n        bar_button_padding = 6\n        hyprbars-button = rgb(8c3737), 12, , hyprctl dispatch killactive\n        hyprbars-button = rgb(466670), 12, , hyprctl dispatch togglefloating\n        hyprbars-button = rgb(3e6963), 12, , ~/.config/hypr/hyproll.sh\n        on_double_click = hyprctl dispatch fullscreen 1\n    }\n}" >> ~/.config/hypr/hyprland.conf) && (grep -q "hyproll window management" ~/.config/hypr/hyprland.conf || echo -e "\n# hyproll window management\n# Бинд для разворачивания/сворачивания по номеру\nbind = SUPER, PAGEUP, exec, ~/.config/hypr/hyproll.sh raise 0\n\n# Бинд для \"Сворачивания\"\nbind = SUPER, PAGEDOWN, exec, ~/.config/hypr/hyproll.sh" >> ~/.config/hypr/hyprland.conf) && echo "Установка завершена!"</code></pre>

<p>Команда автоматически устанавливает и настраивает плагины для Hyprland: ставит jq для работы с JSON, обновляет менеджер плагинов hyprpm, добавляет официальные плагины Hyprland, активирует hyprbars для заголовков окон, скачивает скрипт hyproll для управления окнами, размещает его в правильной директории, добавляет горячие клавиши (Super+PageDown для разворачивания окон и Super+PageUp для сворачивания) в конфигурационный файл Hyprland.</p>

</body>
</html>
