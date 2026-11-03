# Визуальные ассеты 0.10.0

Новые фоновые изображения и транспорт созданы встроенным генератором изображений для проекта. Они включены в исходники и используются игрой непосредственно. Скриншоты в `docs/screenshots/nightfall/` сняты в Godot, а не сгенерированы.

| Файл | Назначение |
|---|---|
| `assets/environments/night_sea.png` | Ночное побережье и морская высадка |
| `assets/environments/night_city.png` | Городской укреплённый док |
| `assets/environments/night_bridge.png` | Ночной мост |
| `assets/environments/heavy_transport.png` | Отдельный прозрачный спрайт тяжёлого транспортного вертолёта |
| `assets/environments/night_coast_atlas.png` | Черновой трёхполосный атлас, оставлен как исходный материал; активные уровни используют отдельные фоны |
| `assets/creatures/klyk_atlas.png` | Предыдущий пользовательский атлас частей «Клыка», исходное изображение не изменялось |
| `docs/reference/hud_target.jpg` | Предоставленный референс HUD; исходные байты JPEG сохранены с правильным расширением |

Вода, преломление, следы, брызги, дождь, импульсы ударов, подпись, рамки и органы управления реализованы кодом и шейдерами. Акторы собираются из отдельных спрайтов; мех не нарисован внутри фоновой картинки.

## Промпты финальных фонов

Общее начало:

> Use case: stylized-concept. Production environment background for RIFT ZERO PROTOCOL. Create ONE full frame very detailed 16:9 2048x1152 cinematic game background, no collage, no multiple strips.

Море:

> A stormy moonlit sea at NIGHT off a fortified industrial coast. Foreground shallow seawater with crisp small waves and warm amber reflections fills bottom 35 percent, with flat horizon at 60 percent height. Huge distant brutalist seawall and a coastal cargo port with cranes occupy the middle distance, a low massive breakwater extending across the right, red aviation lights and amber work lights, a small gate to a distant dock on shore. Layered clouds, cool moonlight, fine rain, haze. The water must look realistic, dark steel blue, detailed and beautiful.

Город:

> A huge fortified industrial CITY DOCK at NIGHT, seen perfectly broadside from the side, similar to a beautiful realistic science fiction 2.5D game. Detailed wet brutalist concrete seawall at middle distance, control tower with amber windows near left third, iron pipes, service doors, gantries, railings, amber industrial lamps evenly spaced and red aviation beacons on top of the wall. Deep distant futuristic city silhouette, clouds, blue rain, fog. A long horizontal wet steel walking platform lies at 83 percent of frame height, sharp textures, cinematic connected coherent architecture.

Мост:

> A coastal suspension BRIDGE at NIGHT, perfectly broadside flat side view. Long level wet asphalt and steel bridge deck at 83 percent of frame height, fine railings behind the walking plane, amber streetlights and their realistic long reflections on rain-soaked asphalt. Large bridge towers with red navigation beacons, overhead support cables, cold dark stormy sea and far city skyline visible behind, bright moon veiled in layered storm clouds, heavy atmospheric blue rain. Very polished realistic industrial game environment.

Общее окончание:

> Style: photorealistic industrial science fiction matte painting, muted cold navy blue and blue grey palette, warm amber light pools and subtle red beacons. Strictly horizontal side scrolling perspective at human-visible ground level, no tilted camera, no isometric or top-down viewpoint. Connected believable infrastructure, rich crisp texture, no blurry airbrush look. ABSOLUTELY NO ROBOTS, NO PEOPLE, NO CHARACTER, NO HUD, NO interface, NO letters or numbers, NO watermark. This is a background behind separately animated giant mechs. Do not include any mech or other playable character.

## Промпт транспорта

> Production game sprite asset, one single heavy futuristic military tandem rotor transport helicopter for RIFT ZERO PROTOCOL, perfectly flat strict side view facing right. Entire machine visible and centered, wide landscape composition. Dark weathered steel and navy grey panels, intricate industrial mechanical detail, two large rotor assemblies on top, small orange navigation lights and cockpit windows, underbelly heavy lifting winch hardpoints, landing gear. Realistic cinematic science fiction painted rendering for a giant mech coastal night mission, crisp silhouette, subtle cool blue moonlight from above and amber glints. NO text, NO logo, NO people, NO environment, NO rain, NO water, NO ropes, NO cast shadow outside helicopter. Truly transparent background, ready to composite as a cutout sprite. Not a toy, not cartoon, not isometric, no three quarter view, no motion blur, no extra helicopter. The rotor blades are thin but visible horizontal structures.

Генератор вернул изображения собственного размера; указанное в текстовом запросе разрешение не принимается за фактическое. В игре используется исходное разрешение PNG и отдельная непрерывная укладка панорамных слоёв.
