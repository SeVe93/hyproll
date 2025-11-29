<!DOCTYPE html>
<html>
<head>
<meta charset="UTF-8">

</head>
<body>

<h1>hyproll</h1>

<p><code>hyproll.sh</code> — bash-скрипт для Hyprland, реализующий «dock-подобное» свёртывание окон в нижнюю часть экрана.</p>

<p>50 строк чистого баша (+jq).<br>
Очень легкое решение распределения пространства Hyprland</p>

<h2>Основная функциональность:</h2>
<p>Создает "свернутую" панель окон в нижней части экрана, похожую на док или панель задач.</p>
<p>По факту: просто переносит активную часть окна ниже зоны экнана, оставляя только шапку (hyprctl видит только размеры самого окна, что нам на руку), и выравнивает относительно соседнего.</p>
<p>В итоге получаем легчайший трей приложений с сохранением размера окон для каждого "рабочего стола"  </p>


![photo_1_2025-11-29_06-43-21](https://github.com/user-attachments/assets/dfeee8cd-a02d-4f01-8380-a36668894c94)
![photo_2_2025-11-29_06-43-21](https://github.com/user-attachments/assets/fe6cc499-61b0-40e7-b078-650f35f65bc0)
![photo_3_2025-11-29_06-43-21](https://github.com/user-attachments/assets/f01a2bf8-9c0f-439a-a59e-fe3cd1f84ada)
https://github.com/user-attachments/assets/78cf083d-aa62-47c5-94ff-033c197ef4e5


<h2>Как работает:</h2>
<ul>
<li>Находит все окна на текущем workspace.</li>
<li>Определяет положение верхней части выбранного окна относительно "зоны сворачивания" (FOLD_THRESHOLD=50)px.</li>
<li>Все окна, чье верхнее значение FOLD_THRESHOLD совпадает с "зоной сворачивания" - опускаются ниже уровня экрана, оставляя только шапку.</li>
<li>Перераспределяет все свернутые окна с равными промежутками (WINDOW_SPACING)px с лева направа, либо справа налево, в зависимости от выбранной переменной: DIRECTION="left" (либо right).</li>
<li>Перераспределяет "свернутые" окна при повторном применении скрипта (сворачивании окна) (мгновенного триггера без ущерба производительности пока не придумал...).</li>
</ul>

<p>Автоматическое определение монитора - получает размеры активного монитора.<br>
Работа с активным рабочим пространством - обрабатывает только окна текущего workspace.<br>
"Сворачивание" окон - окна ниже определенного порога (FOLD_THRESHOLD) считаются свернутыми.</p>

<hr>

<h2>Переменные конфигурации:</h2>

<pre>WINDOW_SPACING=100 - расстояние между окнами
FOLD_THRESHOLD=50  - порог для определения свернутых окон
RECALC_DELAY=0.1   - задержка перед перерасчетом позиций
DIRECTION="left"   - или "right" - направление размещения окон</pre>

<hr>

<h2>Зависимости:</h2>

<ul>
<li>hyprland - оконный менеджер<br>
https://hypr.land/</li>
<li>hyprplugins/hyprbar - шапка<br>
https://github.com/hyprwm/hyprland-plugins</li>
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

<p>В начало конфига (плагины hyprland. в них нужно будет активировать hyprbar):</p>

<pre>#В начало конфига
exec-once = hyprpm reload

#Бинд для "Сворачивания"
bind = SUPER, A, exec, ~/.config/hypr/hyproll.sh

#пример конфига hyprbars:
plugin {
    hyprbars {
        bar_height = 25
        icon_on_hover = true
        bar_color = rgb(252530)
        col.text = rgb(466670)
        bar_text_font = Sans
        bar_text_size = 10
        bar_text_align = left
        bar_padding = 10
        bar_button_padding = 6
        hyprbars-button = rgb(8c3737), 12, , hyprctl dispatch killactive
        #Вот это наш корешь
        hyprbars-button = rgb(3e6963), 12, , ~/.config/hypr/hyproll.sh
        hyprbars-button = rgb(466670), 12, , hyprctl dispatch togglefloating
        on_double_click = hyprctl dispatch fullscreen 1
    }   
}</pre>

</body>
</html>
