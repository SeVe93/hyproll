<!DOCTYPE html>
<html>

<body>

<p><code>hyproll.sh</code> - Bash-скрипт для Hyprland: быстрое "свертывание" и развертывание окон с сохранением содержимого, размера и положения в пространстве.</p>

<p><strong>Стек:</strong> hyprctl + hyprpm + bash + jq<br>
Очень легкое решение для управления пространством в Hyprland.</p>

https://github.com/user-attachments/assets/3d76e2a6-4159-4ffa-9a5a-127dd10ff72a

<p>Работает только при обращении к скрипту: никаких демонов, завершается после исполнения.</p>

<h2>Основная функциональность</h2>
<p>Делит ширину экрана на равные ячейки с заданной шириной. При запуске скрипта проверяет актуальное положение окон и опускает активное окно ниже уровня экрана в зону свободной ячейки.</p>

<p>При запуске скрипта с функцией <code>hyproll.sh raise №</code> возвращает окно в положение "до сворачивания". Повторный запрос функции возвращает окно обратно в "трей".</p>




<h2>Известные проблемы</h2>
<p>Могут быть проблемы с фокусировкой на активное окно.</p>

<h2>Переменные конфигурации</h2>
<table border="1" cellpadding="8" cellspacing="0" style="border-collapse: collapse;">
<tr>
<th>Переменная</th>
<th>Описание</th>
<th>Значение по умолчанию</th>
</tr>
<tr>
<td><code>WINDOW_SPACING</code></td>
<td>Расстояние между окнами (ширина ячейки)</td>
<td><code>100</code></td>
</tr>
<tr>
<td><code>FOLD_HEIGHT_OFFSET</code></td>
<td>Высота от нижнего края экрана</td>
<td><code>0</code></td>
</tr>
<tr>
<td><code>FOLD_THRESHOLD</code></td>
<td>Порог для определения свернутых окон</td>
<td><code>100</code></td>
</tr>
</table>

<h2>Зависимости</h2>
<ul>
<li><a href="https://hypr.land/">hyprland</a> - оконный менеджер</li>
<li><a href="https://github.com/hyprwm/hyprland-plugins">hyprbars</a> - плагин для заголовков окон (опционально)</li>
<li><strong>jq</strong> - для работы с JSON:<br>
<code>sudo pacman -S jq</code></li>
</ul>

<hr>

<h2>Установка и настройка</h2>

<p><strong>1.</strong> Поместите скрипт в папку конфига Hyprland:<br>
<code>~/.config/hypr/hyproll.sh</code></p>

<p><strong>2.</strong> Сделайте скрипт исполняемым:<br>
<code>chmod +x ~/.config/hypr/hyproll.sh</code></p>

<p><strong>3.</strong> Установите jq (если еще не установлен):<br>
<code>sudo pacman -S jq</code></p>

<p><strong>4.</strong> В конфигурацию Hyprland (<code>~/.config/hypr/hyprland.conf</code>) добавьте:</p>

<h3>Бинды для управления окнами:</h3>
<pre><code># Развернуть окно по номеру
bind = SUPER, 1, exec, ~/.config/hypr/hyproll.sh raise 0
bind = SUPER, 2, exec, ~/.config/hypr/hyproll.sh raise 1
bind = SUPER, 3, exec, ~/.config/hypr/hyproll.sh raise 2
bind = SUPER, 4, exec, ~/.config/hypr/hyproll.sh raise 3
</code></pre>

<pre><code>
# Свернуть/развернуть активное окно
bind = SUPER, A, exec, ~/.config/hypr/hyproll.sh</code></pre>

<h3>Конфигурация hyprbars (опционально):</h3>
<pre><code>exec-once = hyprpm reload

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
        hyprbars-button = rgb(466670), 12, , hyprctl dispatch togglefloating
        hyprbars-button = rgb(3e6963), 12, , hyprctl dispatch fullscreen 1
        on_double_click = ~/.config/hypr/hyproll.sh
    }   
}</code></pre>

<h2>Быстрая установка</h2>
<p>Выполните следующую команду для автоматической установки и настройки:</p>

<pre style="background: #f4f4f4; padding: 15px; border-left: 4px solid #ccc; overflow-x: auto;">
<code id="installCommand">sudo pacman -S --needed jq && \
hyprpm update 2>/dev/null && \
(hyprpm list | grep -q "hyprland-plugins" || hyprpm add https://github.com/hyprwm/hyprland-plugins) && \
(hyprpm list | grep -q "hyprbars" && echo "hyprbars уже включен" || hyprpm enable hyprbars) && \
(git clone https://github.com/SeVe93/hyproll /tmp/hyproll_tmp && \
cp /tmp/hyproll_tmp/hyproll.sh ~/.config/hypr/hyproll.sh && \
chmod +x ~/.config/hypr/hyproll.sh && \
rm -rf /tmp/hyproll_tmp && \
echo "hyproll скрипт установлен") && \
(grep -q "plugin.hyprbars {" ~/.config/hypr/hyprland.conf || echo -e "\n# hyprbars config\nplugin {\n    hyprbars {\n        bar_height = 25\n        icon_on_hover = true\n        bar_color = rgb(252530)\n        col.text = rgb(466670)\n        bar_text_font = Sans\n        bar_text_size = 10\n        bar_text_align = left\n        bar_padding = 10\n        bar_button_padding = 6\n        hyprbars-button = rgb(8c3737), 12, , hyprctl dispatch killactive\n        hyprbars-button = rgb(466670), 12, , hyprctl dispatch togglefloating\n        hyprbars-button = rgb(3e6963), 12, , ~/.config/hypr/hyproll.sh\n        on_double_click = hyprctl dispatch fullscreen 1\n    }\n}" >> ~/.config/hypr/hyprland.conf) && \
(grep -q "hyproll window management" ~/.config/hypr/hyprland.conf || echo -e "\n# hyproll window management\n# Бинды для разворачивания/сворачивания по номеру\nbind = SUPER, 1, exec, ~/.config/hypr/hyproll.sh raise 0\nbind = SUPER, 2, exec, ~/.config/hypr/hyproll.sh raise 1\nbind = SUPER, 3, exec, ~/.config/hypr/hyproll.sh raise 2\nbind = SUPER, 4, exec, ~/.config/hypr/hyproll.sh raise 3\n\n# Бинд для \"Сворачивания\"\nbind = SUPER, A, exec, ~/.config/hypr/hyproll.sh" >> ~/.config/hypr/hyprland.conf) && \
echo "Установка завершена!"</code>
</pre>

<p>Команда автоматически устанавливает и настраивает плагины для Hyprland: ставит jq для работы с JSON, обновляет менеджер плагинов hyprpm, добавляет официальные плагины Hyprland, активирует hyprbars для заголовков окон, скачивает скрипт hyproll для управления окнами, размещает его в правильной директории, добавляет горячие клавиши в конфигурационный файл Hyprland.</p>

</body>
</html>





