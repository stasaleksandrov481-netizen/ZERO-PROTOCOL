# Исходники художественных ресурсов

Все три растровые иллюстрации созданы для проекта встроенным инструментом imagegen. Режим CLI/API не использовался. Пользовательская картинка меню служила визуальным референсом композиции и стиля, а не готовым фоном с кнопками.

| Файл в проекте | Назначение | Прозрачность |
| --- | --- | --- |
| `res://assets/background/city_hangar.png` | Ночной город, ангар, Разлом, пол | Непрозрачный фон |
| `res://assets/background/atlant_menu.png` | Декоративный Атлант отдельным слоем | Alpha |
| `res://assets/background/pilot_menu.png` | Пилот на переднем плане | Alpha |
| `res://resources/configuration/pilot_sprite.tres` | Редактируемая область AtlasTexture для пилота | Исходный alpha сохранён |
| `res://assets/background/pilot.svg` | Лёгкий альтернативный силуэт | Вектор |
| `res://assets/ui/rift_logo.svg` | Собственный знак и надпись | Векторные контуры |
| `res://assets/icons/*.svg` | Иконки, состояния и значок приложения | Редактируемые SVG |

Оригинальные растры сохранены без дорисовки программными средствами. Размер и обрезка регулируются узлами сцены и AtlasTexture. Пилот и Атлант в меню не являются готовыми моделями для боя. Отдельные атмосферные эффекты рисуются поверх слоёв в Godot.

## Промпт окружения

```text
Use case: stylized-concept. Asset type: original layered game menu BACKGROUND ENVIRONMENT only for RIFT ZERO PROTOCOL. Input image 1 is a reference for composition, atmosphere and restrained pixel-styled detail; do not reproduce any UI. Create a wide 16:9 night-time sci-fi industrial hangar opening onto a dense blue-grey city. Leftmost 31% is a very dark structural wall and empty shadow with enough negative space for the real game logo and menu to be added separately in Godot. A vertical hangar beam at 31% with dangling cables overhead. Center and right show distant skyline, a huge magenta-red thin arcing rift in storm clouds, angled searchlight beams, rain haze. A wet industrial platform along bottom 20%, dark safety rail near bottom 17%, tiny red emergency lamps and muted reflections. Important: RIGHT HALF IS EMPTY HANGAR SPACE FOR A GIANT ROBOT SPRITE TO BE PLACED LATER. Do NOT draw any robot or person anywhere. Robot is a separate transparent asset. Style: hand-crafted stylized 2.5D game environment, painterly pixel-like edges and restrained low-poly industrial detail, NOT photorealistic, NOT glossy. Navy black, steel blue, small red accents. Composition very close to reference, clean readable silhouettes. Full-bleed image. No text, letters, logos, UI, symbols, numbers, badges, borders or HUD. Original assets for a game.
```

## Промпт Атланта

```text
Use case: stylized-concept. Asset type: isolated transparent giant mech sprite for a 2.5D mobile game hangar menu. Image 1 is a style and composition reference ONLY. Create a new original enormous humanoid combat robot Atlant, shown from upper thighs to top of head in slight three-quarter front view, looking towards left. Blocky heavy blue-grey industrial armored torso, squat compact head with a narrow amber single visor, broad asymmetrical shoulders, segmented arms, layered armor, a small triangular generic geometry insignia with no text. Original design, not a known franchise robot. Match reference robotic silhouette, colors and night lighting. Cold blue rimlight on armor edges from upper left, dark navy shadows, subtle amber mechanical details, very restrained wear. Clean low-poly/pixel-styled game illustration with readable plates and restrained brush details, NOT photorealistic, NOT glossy. Complete silhouette contained with small margin, no cropped head or arms. Standing neutral, hands low beside torso. Background must be genuinely TRANSPARENT alpha, with absolutely no environment, ground, text, letters, watermarks, UI, border, glow haze outside silhouette. This asset will be placed at 60%-92% of a wide screen, behind a foreground railing.
```

## Промпт пилота

```text
Use case: stylized-concept. Asset type: tiny isolated foreground pilot sprite for an original dark sci-fi hangar game menu. Reference image 1 shows the atmosphere and the intended small back-facing human figure, use as style reference only. Full body of a lone human pilot standing still, BACK towards camera, relaxed arms down, looking slightly right and upwards at an enormous machine outside frame. Dark navy practical armored flight suit, compact helmet with a small narrow amber edge, layered shoulder protection, tactical boots, small rectangular backpack, small plain triangle stitched on upper back, no weapons. Natural believable human proportions and subtle silhouette, male or androgynous, no identifiable face. Same stylized 2.5D low-poly industrial game illustration as the reference, restrained pixel-like detail, NOT glossy photorealistic, no cartoon outline. Steel-blue cold rim lighting from front of pilot / the background, very dark shadows facing us. Character will appear only 100-160 pixels tall so silhouette must read. Full feet and helmet visible, centered with minimal empty margins. Genuinely transparent alpha background, no ground, shadow, environment, text, other figures, robot, UI or watermark.
```

## Звуки и тема

`tools/build_assets.py` воспроизводимо создаёт три коротких UI-сигнала, 16-секундный зацикленный низкий фон и периодический синтетический шум окружения. Формат — mono PCM WAV, 22050 Гц. Огибающие и амплитуды ограничены до записи; клиппинг исключён проверкой генератора.

Тот же инструмент создаёт SVG и `rift_theme.tres`. Для генерации нужны Python, numpy, fonttools, но для запуска игры они не требуются. Палитра и компоненты централизованы в RiftUI; русские строки — отдельный Translation-ресурс.

## АТ-01: новая геометрия и материал

Объёмная модель создана процедурно авторским AtlantMeshFactory, а не собрана из изображения меню. Геометрия запечена в scenes/atlants/at01.tscn; исходник и генератор включены. Новая карта окрашенного металла: res://assets/materials/at01_painted_steel.png. Она создана встроенным imagegen, режим CLI/API не использовался. Растр сохранён без последующего редактирования; вариации краски задаются материалами Godot.

Промпт материала:

```text
Use case: stylized-concept. Asset type: seamless square albedo material texture for a real original 3D game mech model. Primary request: a flat orthographic close-up of worn neutral cool-grey painted armored steel with very fine micro-scratches, tiny restrained chipped paint exposing dark brushed metal, subtle machining grain and slight dirt in the surface. It is a reusable seamless material, NOT a robot illustration and NOT a designed panel layout. Uniform neutral grey value across the entire tile so it can be tinted navy blue or ivory in Godot. Stylistically detailed hand-painted industrial 2.5D / low-poly game art, crisp restrained texture, no baked directional lighting, no cast shadows, no vignette, no bright hot spots. Very restrained wear, predominantly intact paint. No text, numerals, logos, objects, giant seams, holes, circles, borders or perspective. Fill the whole square edge to edge with a continuous tileable steel paint texture. Intended for small detailed armor plates of a starter giant robot.
```

Короткие механические звуки созданы tools/build_test_audio.py. Для запуска не нужны Python или сторонние библиотеки.


## 0.9: радиосвязь

`assets/ui/radio_personnel.png` — созданный для проекта квадратный атлас 2×2 с четырьмя портретами: Ника / Эхо, Даниил / Кедр, Ветрова, Тая. Сдержанная иллюстрация промышленной научной фантастики, холодный свет, тактические гарнитуры, без текста и интерфейса внутри изображения. Создан встроенной генерацией изображений; в игре отображается отдельная плитка соответствующего говорящего.

Стальные панели, иконки, индикаторы радио и кнопки нарисованы кодом Godot. Короткий сигнал приёма синтезируется в `audio_manager.gd`; внешняя фонограмма не используется.

## 0.10.0 — ночной берег
Новые фоновые материалы, транспорт, происхождение атласа «Клыка», референс и промпты: [ART_ASSETS_0_10_0.md](ART_ASSETS_0_10_0.md). Реальные кадры игры: `screenshots/nightfall/`.

## 0.10.1 — актуальный семичастный Атлант

`assets/atlants/at01_oplot_atlas.png` — пользовательский исходник «Атлас семи деталей робота в профиль.png», перенесён без изменения пикселей. Деление на семь деталей и положение суставов задаются `scripts/models/atlant_2d_skin.gd`. Старые изображения и 3D-компоненты из исторических записей выше удалены из текущего проекта; они не участвуют в загрузке и экспорте. Все актуальные растровые текстуры загружаются через общий `texture_source.gd`.

## 0.11.0 — ночной конвой

Новая постановка пролога повторно использует существующие `night_sea.png`, `heavy_transport.png` и `radio_personnel.png`; новых растровых исходников персонажей или Атлантов не добавлено. Анимация конвоя, дождь, подсветка и интерфейс выполнены кодом. `transport_ambience.gd` создаёт оригинальный зацикленный звук роторов и ветра математически, без внешних семплов. Снимки в `docs/screenshots/convoy/` получены из настоящего работающего Godot viewport и показывают UI версии 0.11.0.

## 0.12.0 — коллизии и тяжёлый шаг

Новых растровых моделей не добавлено. Контуры `collision_profiles.gd` получены из непрозрачных силуэтов уже используемых `at01_oplot_atlas.png` и `klyk_atlas.png`, упрощены до выпуклых форм и преобразуются теми же масштабом и поворотом, что и графика. Новый низкий шаг генерируется математически в `AudioManager`, без внешних семплов. Кадры `heavy_tide` сняты из работающего Godot viewport; бирюзовые линии присутствуют только в тестовом режиме аудита коллизий.

## 0.13.0 — ударная масса

Атласы и панорамы сохранены. Траектории рук, бег, восстановительные шаги, боевые состояния, боковые водяные веера, пена и HUD выполнены кодом Godot. Новые изображения и внешние звуки не добавлены. `docs/screenshots/impact_mass/` — реальные снимки работающего viewport, снятые `tests/capture_dynamic.tscn`; постановочные импульсы в этом сценарии проверяют позы. Длительность и исход настоящего боя отдельно проверяются физическим `nightfall_tests.tscn`.

## 0.13.1 — контакт и кадр

Новых растровых исходников и звуков не добавлено. Камера, короткая подсветка руки, затухающий сегмент здоровья и контактная дуга выполнены кодом. `screenshots/contact_polish/` сняты из работающего Godot: реальные движения стиков и контакты кулаков с Клыком, без прямого вызова урона. Метаданные столкновений записывает `tests/capture_readability.tscn`.

## 0.14.0 — физический риг

Новых изображений и сторонних ресурсов не добавлено. Клык использует существующий `klyk_atlas.png`: каждый силуэт закреплён на собственном RigidBody2D, спрайт и измеренный коллайдер имеют один локальный трансформ. Голова, плечи, бёдра, колени и стопы соединены физическими суставами; вращения рисунков для имитации инерции нет. В `screenshots/live_rig/` находятся кадры настоящего viewport Godot, а не концепт-арт.
