# Скриншоты технического аудита

Настоящий рендер Godot 4.6.3 / Xvfb / Mesa llvmpipe, Linux. Не фотографии телефона.
Основные кадры повторяют изолированную игровую фикстуру ночного спринта: шесть
зрелых видов, три младшие стадии, 41 монета; перед панелью семян морковь собрана,
баланс 51. Окружение зафиксировано на 2.25 с, часы тестовые; обычный save не меняется.

| Язык | Сад 390×844 | Семена 390×844 | Сад 430×932 | Семена 430×932 |
| --- | --- | --- | --- | --- |
| English | [garden](garden-en-390x844.png) | [seeds](seeds-en-390x844.png) | [garden](garden-en-430x932.png) | [seeds](seeds-en-430x932.png) |
| Русский | [garden](garden-ru-390x844.png) | [seeds](seeds-ru-390x844.png) | [garden](garden-ru-430x932.png) | [seeds](seeds-ru-430x932.png) |
| Polski | [garden](garden-pl-390x844.png) | [seeds](seeds-pl-390x844.png) | [garden](garden-pl-430x932.png) | [seeds](seeds-pl-430x932.png) |
| Español | [garden](garden-es-390x844.png) | [seeds](seeds-es-390x844.png) | [garden](garden-es-430x932.png) | [seeds](seeds-es-430x932.png) |
| Deutsch | [garden](garden-de-390x844.png) | [seeds](seeds-de-390x844.png) | [garden](garden-de-430x932.png) | [seeds](seeds-de-430x932.png) |
| Français | [garden](garden-fr-390x844.png) | [seeds](seeds-fr-390x844.png) | [garden](garden-fr-430x932.png) | [seeds](seeds-fr-430x932.png) |
| Português (Brasil) | [garden](garden-pt_BR-390x844.png) | [seeds](seeds-pt_BR-390x844.png) | [garden](garden-pt_BR-430x932.png) | [seeds](seeds-pt_BR-430x932.png) |

## Компактные экраны, планшет и zoom

Эта фикстура сажает морковь, Moonberry и Bubble Cactus штатными командами,
показывает их зрелыми через тестовые часы (баланс 88). Остальные грядки пусты.

| Размер | Сад | Языки |
| --- | --- | --- |
| 320x568 | [Сад](compact-garden-ru-320x568.png) | [Диалог](compact-language-ru-320x568.png) |
| 360x640 | [Сад](compact-garden-ru-360x640.png) | [Диалог](compact-language-ru-360x640.png) |
| 768x1024 | [Сад](compact-garden-ru-768x1024.png) | [Диалог](compact-language-ru-768x1024.png) |

[Максимальный zoom 390×844](zoom-ru-390x844.png): мир обрезается по игровой области
и не рисуется под надписями HUD. В компактном overview первый tap приближает карту,
следующий выбирает грядку. Это сохраняет удобные цели без уменьшения шрифтов.

## Программная геометрия safe area

Следующие кадры используют настоящий HUD/мир/Camera2D и тестовый подкласс HUD,
который подставляет результат OS geometry: экран 1170×2532, usable Rect(0,141,1170,2289).
Так проверяется реакция layout на отступы, а не работа API выреза на iPhone.
Нарисованных фиктивных системных панелей нет. Это **не физическая проверка**.

- 390x844: [Сад](simulated-safe-garden-ru-390x844.png), [языки](simulated-safe-language-ru-390x844.png).
- 430x932: [Сад](simulated-safe-garden-ru-430x932.png), [языки](simulated-safe-language-ru-430x932.png).

Все 39 кадров просмотрены. RGB-сравнение 28 основных кадров с исходным `4717dc8`:
[метрики](../visual-comparison.json). Разница HUD в проверенных верхних/нижних
областях равна нулю; отличия сада обусловлены фильтрацией raster cache.
Ограничения FPS/устройств и результаты автоматических тестов — в ../REPORT.md.
