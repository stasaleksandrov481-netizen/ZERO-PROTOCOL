# Проверки 0.12.0

К трём наборам 0.11 добавлена `physics_regression_tests.tscn`: 35 проверок приводов, полного цикла круговых движений и отпускания обоих стиков, конечных углов, падения с отключённым приводом, разгона и торможения, быстрого физического удара в челюсть, всех 10 форм Клыка, плоской воды и плеска, паузы, уменьшенного движения и размещения рации на двух экранах.

```bash
godot --headless --path . --scene res://tests/physics_regression_tests.tscn
```

`capture_weight.tscn` снимает настоящие PNG с водой, шагом, телефонным HUD, контактом, видимыми коллизиями и руками после отпускания. Бирюзовые контуры добавляет только диагностический `collision_audit.gd`; в игровом интерфейсе их нет. Полный текущий набор: 67 + 33 + 42 + 35 = 177 проверок. Старые 3D-проверки ниже исторические.

---

# Текущие проверки 0.11.0

После импорта в Godot 4.7.2 запустите три сцены с отдельным `XDG_DATA_HOME` для каждой:

```bash
godot --headless --path . --scene res://tests/nightfall_tests.tscn
godot --headless --path . --scene res://tests/asset_startup_tests.tscn
godot --headless --path . --scene res://tests/prologue_tests.tscn
```

`nightfall_tests` проверяет кампанию, физику боя, сохранения и сеть баз; `asset_startup_tests` — исходные PNG, отсутствие старых моделей и скрытую сборку сцен; `prologue_tests` — ветки разговора, сводку, пропуск, клавиатуру, уменьшенное движение, аудиопереход, журнал, необязательное обучение и компоновку четырёх размеров экрана.

Графические сцены `capture_polish_10.tscn` и `capture_prologue.tscn` снимают настоящие viewport PNG в `RIFT_CAPTURE_DIR`. Для новых проверок не нужен GUT. Снимки и экспорт PCK не подтверждают аппаратный запуск на Android.

Ниже — историческая документация прежних наборов; часть старых тестовых сцен больше не относится к текущему игровому срезу.

---

# Проверки 0.9.0

Используйте отдельный `XDG_DATA_HOME`, поскольку тесты создают и изменяют профиль. Сначала выполните импорт проекта Godot 4.7.2.

```bash
XDG_DATA_HOME="$PWD/.qa-user" godot --headless --path . --scene res://tests/ui_09_tests.tscn
XDG_DATA_HOME="$PWD/.qa-user" godot --headless --path . --scene res://tests/test_runner.tscn
XDG_DATA_HOME="$PWD/.qa-user" godot --headless --path . --scene res://tests/range_2d_tests.tscn
XDG_DATA_HOME="$PWD/.qa-user" godot --headless --path . --scene res://tests/expedition_08_path.tscn
```

`UI09_RESULT` содержит итог новых проверок радио, трёх пальцев, полного останова физики и обработки, настроек поверх игры, журнала, восстановления сохранения и страниц с реальными данными. `expedition_08_path` проходит маршрут настоящими физическими ударами. Эти сценарии не требуют дополнительных плагинов.

Для настоящих изображений используйте графический запуск `capture_ui_09.tscn`. `RIFT_CAPTURE_DIR` задаёт папку PNG, `RIFT_PHONE=1` включает окно 1024×459. В headless изображения не создаются. Снимки сами по себе не подтверждают аппаратную работу Android.

Ниже сохранена документация ранних наборов. В ней есть исторические проверки 3D-разворотов, не относящиеся к действующей 2D-сцене 0.9. Актуальные ограничения: `docs/ACTOR_2D_RULES.md`.

# Новые проверки полигона 0.2.0

`range_physics_tests.tscn` запускает физический набор. `range_layout_probe.tscn` проверяет расположение HUD при четырёх масштабах. `capture_range.tscn` сохраняет реальные изображения главного меню, полигона и настроек.

Пример после импорта проекта, с отдельными тестовыми настройками:

```bash
XDG_DATA_HOME="$PWD/.qa-user" godot --headless --path . --scene res://tests/range_physics_tests.tscn
```

Результат: user://range_test_results.json. Без headless можно снять кадры: задайте RIFT_CAPTURE_DIR и откройте capture_range.tscn. Ниже — общие проверки исходного фундамента; актуальные количества находятся в docs/TEST_PLAN.md.

# Проверка фундамента

Тесты запускают настоящие сцены Godot, не требуют GUT или других плагинов. Нужен Godot 4.7.x. Сначала импортируйте проект редактором.

Тесты меняют настройки. Используйте отдельный каталог пользовательских данных. Пример для Linux из папки проекта:

```bash
XDG_DATA_HOME="$PWD/.qa-user" godot --headless --path . --scene res://tests/test_runner.tscn
```

Результат печатается строкой RESULT и записывается в `user://test_results.json`. Проверяются загрузка скриптов, все маршруты, реальные события мыши, настройки и аудиошины, сцены вкладок, отсутствие датчика, сброс, 40 повторных переходов, число узлов и статическая память.

Сохранение между отдельными процессами:

```bash
XDG_DATA_HOME="$PWD/.qa-user" godot --headless --path . --scene res://tests/persistence_probe.tscn -- --write
XDG_DATA_HOME="$PWD/.qa-user" godot --headless --path . --scene res://tests/persistence_probe.tscn -- --read
```

Восстановление и миграция:

```bash
XDG_DATA_HOME="$PWD/.qa-user" godot --headless --path . --scene res://tests/recovery_probe.tscn
```

RecoveryProbe намеренно портит свой settings.cfg. Сообщения ConfigFile parse error в этом тесте ожидаемы; итог должен содержать пустой список failures. Не запускайте этот тест на важных пользовательских настройках.

Клавиатура, синтетический touch, платформенное уведомление Back и подтверждённый выход:

```bash
XDG_DATA_HOME="$PWD/.qa-user" godot --headless --path . --scene res://tests/input_probe.tscn
```

Для проверки изображения запустите обычный графический режим с `--scene res://tests/layout_probe.tscn --resolution 2400x1080`. Он проходит все четыре масштаба и проверяет границы значимых элементов, прокрутку до калибровки и окно выхода. Необязательная переменная `RIFT_CAPTURE_DIR` задаёт папку PNG и JSON-отчёта. Без неё снимки не сохраняются.

`capture_preview.tscn` снимает меню, четыре вкладки и окно выхода из реального viewport. Ему нужен графический режим; headless не создаёт изображение. Штатный снимок по умолчанию сохраняется в `user://previews`.

Синтетические события и виртуальные размеры не подтверждают работу сенсора или физических касаний на телефоне. Аппаратный чек-лист находится в `docs/ANDROID_EXPORT.md`.
