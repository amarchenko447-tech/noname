# Этап 0.75 — архитектура расширяемого мира

## Результат
Модель WorldModel и транзакционный WorldService отделены от HUD. GridMetrics/IsoGrid
сохраняют прежнюю проекцию. Девять грядок загружаются из starter_region.tres, имеют
постоянные строковые ID. ObjectDefinition отделён от ObjectRecord; зарезервированы
типы plot/plant/building/decoration, footprint, поворот и слои занятости. Данные
растения/выращивание в этом коммите не реализованы.

Camera2D управляет pan/pinch/wheel; HUD находится в независимом CanvasLayer. Tap
подтверждается на отпускании; pan, pinch, UI и отменённые касания не выбирают грядку.
Камера ограничена по масштабу и области. В обзорном масштабе tap приближает участок.
Общие неподвижные YSort-опоры не зависят от bounce анимации.

Сохранение user://world_v1.json: schema_version, world_id, generation, unlocked_regions,
objects с ID/координатами/поворотом/метаданными. Полный атомарный JSON + last-good backup,
явный реестр миграций, запрет перезаписи будущей версии/двух повреждённых копий.
Кандидат записывается до применения к живой модели. Настройки языка остаются отдельно.

## Проверки
- Godot 4.6.3, импорт и запуск: без ошибок на последней проверенной версии.
- Базовый набор Phase 0: 45 проверок, 0 ошибок (адаптирован к ID/tap release).
- Регрессия Phase 0.5: 6018 проверок, 0 ошибок; семь языков, шрифт, UI, reduced motion.
- Phase 0.75: 1251 проверка, 0 ошибок: координаты, отрицательные чанки, 0/9/37/1000
  записей, перестановка сериализованных объектов, все категории, footprint/коллизии,
  сохранение, backup, I/O failure, миграции, жесты, UI, защита от двойной эмуляции мыши.
- World restart write/read: отдельные процессы восстановили ID и отрицательные координаты.
- В игру не добавлена большая карта; большие наборы существуют только в тестах данных.

Команды (с доступными XDG_DATA_HOME / XDG_CONFIG_HOME / XDG_CACHE_HOME):
```
godot --headless --path . --editor --import --quit
godot --headless --path . --quit-after 60
godot --headless --path . --script res://scripts/tests/phase_zero.gd
godot --headless --path . --script res://scripts/tests/phase_half.gd
godot --headless --path . --script res://scripts/tests/phase_three_quarters.gd
godot --headless --path . --script res://scripts/tests/world_restart.gd -- write
godot --headless --path . --script res://scripts/tests/world_restart.gd -- read
godot --headless --path . --script res://scripts/tests/world_restart.gd -- cleanup
```

## Скриншоты и ограничения
Реальные изображения Godot Compatibility/OpenGL через Xvfb/Mesa находятся в
screenshots/phase_0_75: before (этап 0.5), after (новая архитектура, семь языков),
comparison и navigation. Время анимации фиксируется на 2.25 сек для сравнения.
Исходная композиция сохранена; отличия сглаживания измеряются отдельно в сравнении.

Физические Android/iOS, аппаратный pinch, OS safe areas/lifecycle и FPS на среднем
Android не тестировались. Нет полного streaming и пространственного индекса:
objects_in_world_rect/objects_in_cells — граница для дальнейшей оптимизации.
Статическая сцена стартового региона остаётся оригинальной векторной графикой.

## Следующий шаг
Ночное дополнение владельца разрешает после этого стабильного коммита перейти к
растениям/экономике. Их данные должны расширить согласованный снимок, а не создать
независимый файл монет, рассогласованный с урожаем.
