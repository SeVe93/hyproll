<!DOCTYPE html>
<html>
<head>
<meta charset="UTF-8">

</head>
<body>

<p><code>hyproll.sh</code>Hyprland bash-script: быстрое "свертывание" и развертывание окон Hyprland, сохраняя содержимае, размер и положение в пространстве.</p>

<p>hyprctl + hyprpm + bash + jq<br>
Очень легкое решение распределения пространства Hyprland</p>

https://github.com/user-attachments/assets/2298bf8b-6a8b-4eae-b4ba-7c21cfdc0656

https://github.com/user-attachments/assets/e629e042-2dcb-4fc8-8799-b2e3236af6ab

<h2>Основная функциональность:</h2>
<p>делит ширину экрана на равные ячейки с заданной длинной. </p>
<p>При запуске скрипта - проверяет актуальное положение окон, опускает активное окно ниже уровня экрана в зону свободной ячейки</p>
<p>При запуске скрипта с функцией "hyproll.sh raise №" - возвращает окно в положение "до сворачивания" . повторный запус функции возвращает окно в наш "трей" </p>

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




<p>В начало конфига (плагины hyprland. в них нужно будет активировать hyprbar):<br>
<code>exec-once = hyprpm reload</code></p>

<p>В начало конфига
<code>exec-once = hyprpm reload</code><br>

#Бинд для разворачивания/сворачивания по номеру
bind = SUPER, 1, exec, ~/.config/hypr/scripts/hyproll.sh raise 0

#Бинд для "Сворачивания"
bind = SUPER, A, exec, ~/.config/hypr/hyproll.sh


<h2>Быстрая установка</h2>

<pre><code id="installCommand">sudo pacman -S jq && hyprpm update && hyprpm add https://github.com/hyprwm/hyprland-plugins && hyprpm enable hyprbars && git clone https://github.com/SeVe93/hyproll && mkdir -p ~/.config/hypr/scripts && cp hyproll/hyproll.sh ~/.config/hypr/scripts/hyproll.sh && chmod +x ~/.config/hypr/scripts/hyproll.sh && echo "bind = SUPER, PAGEDOWN, exec, ~/.config/hypr/scripts/hyproll.sh raise 0" >> ~/.config/hypr/hyprland.conf && echo "bind = SUPER, PAGEUP, exec, ~/.config/hypr/scripts/hyproll.sh" >> ~/.config/hypr/hyprland.conf && echo "Установка завершена! Что сделано:" && echo "1. Установлен jq для работы с JSON" && echo "2. Обновлен hyprpm и добавлены плагины" && echo "3. Включен hyprbars (шапки окон)" && echo "4. Скачан hyproll для управления окнами" && echo "5. Добавлены бинды: SUPER+PAGEDOWN - развернуть окно, SUPER+PAGEUP - свернуть окно" && echo "6. Скрипт размещен в ~/.config/hypr/scripts/hyproll.sh"</code></pre>

<p>Команда автоматически устанавливает и настраивает плагины для Hyprland: ставит jq для работы с JSON, обновляет менеджер плагинов hyprpm, добавляет официальные плагины Hyprland, активирует hyprbars для заголовков окон, скачивает скрипт hyproll для управления окнами, размещает его в правильной директории, добавляет горячие клавиши (Super+PageDown для разворачивания окон и Super+PageUp для сворачивания) в конфигурационный файл Hyprland.</p>

</body>
</html>

**Full Changelog**: https://github.com/SeVe93/hyproll/compare/Hyprland...hyproll
