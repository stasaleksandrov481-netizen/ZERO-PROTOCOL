"""Regenerate the authored menu scene, individual screen resources and Russian keys."""
from pathlib import Path
import json
ROOT=Path(__file__).resolve().parents[1]
def put(p,s): (ROOT/p).write_text(s,encoding='utf-8')
def q(v): return json.dumps(v,ensure_ascii=False)

translations={
 'BOOT_STATUS':'ИНИЦИАЛИЗАЦИЯ СИСТЕМ', 'RETRY':'Повторить', 'BACK':'Назад', 'CANCEL':'Отмена',
 'CAMPAIGN':'КАМПАНИЯ','OPERATIONS':'ОПЕРАЦИИ','HANGAR':'АНГАР','ARCHIVE':'АРХИВ','SETTINGS':'НАСТРОЙКИ','QUIT':'ВЫХОД',
 'ABOUT':'О ПРОЕКТЕ','ABOUT_TITLE':'RIFT: ZERO PROTOCOL',
 'ABOUT_BODY':'Версия 0.2.1 • Тестовый полигон\n\nДоступен первый базовый Атлант АТ-01: независимые руки, ходьба и физические суставы на пустом полигоне. Кампания, противники и миссии ещё в разработке.\n\nБез подключения к сети. Настройки хранятся только на этом устройстве.',
 'QUIT_TITLE':'Завершить сеанс?', 'QUIT_BODY':'Настройки будут сохранены. Выйти из RIFT: ZERO PROTOCOL?',
 'VERSION':'РАЗРАБОТКА / 0.2.1', 'FOUNDATION_STAMP':'ЭТАП 02 / ТЕСТ ФИЗИКИ',
 'FOUNDATION_TITLE':'ПОЛИГОН · БАЗОВЫЙ АТ-01', 'FOUNDATION_NOTE':'Две руки · Ходьба · Суставы',
 'SETTINGS_SUBTITLE':'ПАРАМЕТРЫ УСТРОЙСТВА', 'TAB_AUDIO':'ЗВУК','TAB_VIDEO':'ГРАФИКА','TAB_CONTROLS':'УПРАВЛЕНИЕ','TAB_INTERFACE':'ИНТЕРФЕЙС',
 'AUDIO_TITLE':'ЗВУКОВАЯ СРЕДА','AUDIO_HINT':'Настройте музыку ангара, атмосферу окружения и отклик интерфейса.',
 'MASTER':'Общая громкость','MUSIC':'Музыка','SFX':'Эффекты окружения','UI_AUDIO':'Звуки интерфейса',
 'MUSIC_HINT':'Низкий атмосферный фон ангара','SFX_HINT':'Дождь и воздух ангара','UI_AUDIO_HINT':'Нажатия и подтверждения','TEST_SOUND':'Проверить звук интерфейса',
 'VIDEO_TITLE':'ГРАФИКА И ДВИЖЕНИЕ','VIDEO_HINT':'Изменения применяются сразу. Подберите качество и частоту кадров для своего устройства.',
 'QUALITY':'Качество окружения','LOW':'Низкое','MEDIUM':'Среднее','HIGH':'Высокое',
 'QUALITY_HINT':'Дождь, движущиеся лучи, дымка и глубина фона',
 'FPS_CAP':'Ограничение кадров','UNCAPPED':'Без ограничения','FPS_HINT':'Без лимита расход энергии может увеличиться',
 'REDUCED':'Уменьшить движение и мерцание','REDUCED_HINT':'Останавливает дождь, параллакс, движение света и плавные переходы.',
 'RENDERER':'РЕНДЕРЕР / COMPATIBILITY', 'RENDERER_HINT':'Совместимый режим для мобильных устройств. Качество меняет атмосферу меню; рендерер выбирается при запуске проекта.',
 'CONTROLS_TITLE':'ДВЕ РУКИ. ДВА СПОСОБА ДВИЖЕНИЯ.', 'CONTROLS_HINT':'Выберите схему для тестового полигона. Оба джойстика управляют руками, способ ходьбы выбираете вы.',
 'WALK_SCHEME':'Передвижение','SCHEME_A_SHORT':'A · Двойные касания','SCHEME_B_SHORT':'B · Наклон телефона',
 'WALK_HINT':'Оба джойстика независимо управляют руками', 'SENSITIVITY':'Чувствительность наклона','SENSITIVITY_HINT':'Сила отклика движения на наклон',
 'DEADZONE':'Мёртвая зона','DEADZONE_HINT':'Небольшой наклон, который не вызывает движение',
 'CALIBRATION':'Калибровка наклона','CALIBRATE':'Калибровать',
 'NO_SENSOR':'Датчик недоступен. Для игры без наклона выберите схему A.',
 'NO_SENSOR_DETAIL':'На этом устройстве нет доступных показаний акселерометра. В редакторе на ПК это ожидаемо.\n\nВыбор схемы B сохранён. Для управления без датчика предусмотрена схема A с двойными касаниями.',
 'SENSOR_READY':'Датчик доступен. Удерживайте телефон в удобном положении.',
 'SENSOR_CALIBRATED':'Нейтральное положение сохранено на устройстве.',
 'HOLD_STILL':'Удерживайте телефон неподвижно…','CALIBRATION_FAILED':'Положение нестабильно или датчик отключён. Повторите калибровку.',
 'CALIBRATION_DONE':'Нейтральное положение сохранено.',
 'LEFT_HAND':'ЛЕВАЯ РУКА','RIGHT_HAND':'ПРАВАЯ РУКА','DOUBLE_TAP':'ДВОЙНОЕ КАСАНИЕ','TILT_PHONE':'НАКЛОН ТЕЛЕФОНА','ILLUSTRATION_ONLY':'Схема управления · проверяйте в разделе «Тест»',
 'INTERFACE_TITLE':'ЧИТАЕМОСТЬ И ДОСТУПНОСТЬ','INTERFACE_HINT':'Подстройте размер элементов и контраст под свой экран.',
 'UI_SCALE':'Масштаб интерфейса','SCALE_HINT':'На небольшом окне масштаб ограничивается доступным местом',
 'HIGH_CONTRAST':'Повышенный контраст','CONTRAST_HINT':'Затемняет окружение и усиливает контраст основных элементов.',
 'LANGUAGE':'ЯЗЫК ИНТЕРФЕЙСА','LANGUAGE_HINT':'Русский перевод доступен полностью. Другие языки пока не предлагаются.',
 'SAVING':'Сохранение…','SAVED':'СОХРАНЕНО НА УСТРОЙСТВЕ','SAVE_FAILED':'НЕ УДАЛОСЬ СОХРАНИТЬ','RESET':'Сбросить настройки',
 'RESET_TITLE':'Восстановить настройки?','RESET_BODY':'Громкость, качество, интерфейс и параметры управления вернутся к значениям по умолчанию. Это действие сохранится на устройстве.',
 'RESET_ACCEPT':'Восстановить','RESET_DONE':'Настройки по умолчанию восстановлены.',
 'SECTION_SUBTITLE':'RIFT: ZERO PROTOCOL / РАЗРАБОТКА', 'IN_DEVELOPMENT':'РАЗДЕЛ В РАЗРАБОТКЕ',
 'CAMPAIGN_SUMMARY':'Кампания станет историей столкновения двух миров. Сейчас здесь подготовлено место для выбора сюжетных заданий.',
 'OPERATIONS_SUMMARY':'Отдельные задания и испытания получат собственный экран выбора. Доступных операций на этом этапе нет.',
 'HANGAR_SUMMARY':'Здесь будет выбор и оснащение Атлантов. Машины, сборки и улучшения пока не добавлены.',
 'ARCHIVE_SUMMARY':'Здесь появятся досье, записи и материалы о мире RIFT. Новые сюжетные записи пока не добавлены.',
 'CAMPAIGN_EMPTY':'Нет доступных сюжетных заданий', 'OPERATIONS_EMPTY':'Нет доступных операций',
 'HANGAR_EMPTY':'Нет доступных машин','ARCHIVE_EMPTY':'Архив пока не заполнен',
 'SECTION_NOTE':'Раздел откроется на следующем этапе. Меню и настройки уже доступны.',
 'BACK_MENU':'Вернуться в главное меню',
 'CAMP_CARD_1':'ВЫБОР ЗАДАНИЯ','CAMP_CARD_2':'ПРОХОЖДЕНИЕ','CAMP_CARD_3':'ИСТОРИЯ',
 'OPS_CARD_1':'ОТДЕЛЬНЫЕ ЗАДАЧИ','OPS_CARD_2':'ИСПЫТАНИЯ','OPS_CARD_3':'УСЛОВИЯ',
 'HANG_CARD_1':'АТЛАНТЫ','HANG_CARD_2':'ВООРУЖЕНИЕ','HANG_CARD_3':'МОДУЛИ',
 'ARCH_CARD_1':'ДОСЬЕ','ARCH_CARD_2':'ЗАПИСИ','ARCH_CARD_3':'МАТЕРИАЛЫ',
 'PLANNED':'Пока недоступно'
}
messages=',\n'.join(f'{q(k)}: {q(v)}' for k,v in translations.items())
put('resources/localization/ui_ru.tres','[gd_resource type="Translation" format=3]\n\n[resource]\nlocale = "ru"\nmessages = {\n'+messages+'\n}\n')
put('resources/localization/README.md','Все русские ключи находятся в ui_ru.tres. Дополнительные Translation-ресурсы регистрируются в SettingsManager после полного перевода. Экран настройки языка сейчас показывает только русский.\n')

header='''[gd_scene load_steps=11 format=3]
[ext_resource type="Script" path="res://scripts/ui/home_screen.gd" id="1"]
[ext_resource type="Script" path="res://scripts/ui/menu_button.gd" id="2"]
[ext_resource type="Texture2D" path="res://assets/ui/rift_logo.svg" id="3"]
'''
for i,name in enumerate(['campaign','operations','hangar','archive','settings','quit'],4):
    header+=f'[ext_resource type="Texture2D" path="res://assets/icons/{name}.svg" id="{i}"]\n'
header+='''[sub_resource type="StyleBoxFlat" id="MenuNormal"]
bg_color = Color(0.03,0.05,0.075,0.35)
content_margin_left = 26.0
content_margin_right = 20.0
content_margin_top = 8.0
content_margin_bottom = 8.0

[node name="HomeScreen" type="Control"]
layout_mode = 3
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
script = ExtResource("1")

[node name="Margin" type="MarginContainer" parent="."]
layout_mode = 1
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
theme_override_constants/margin_left = 48
theme_override_constants/margin_right = 32
theme_override_constants/margin_top = 28
theme_override_constants/margin_bottom = 24

[node name="Layout" type="HBoxContainer" parent="Margin"]
layout_mode = 2
theme_override_constants/separation = 48

[node name="Left" type="VBoxContainer" parent="Margin/Layout"]
custom_minimum_size = Vector2(300,0)
layout_mode = 2
theme_override_constants/separation = 14

[node name="Logo" type="TextureRect" parent="Margin/Layout/Left"]
custom_minimum_size = Vector2(300,114)
layout_mode = 2
texture = ExtResource("3")
expand_mode = 1
stretch_mode = 5
mouse_filter = 2

[node name="LogoGap" type="Control" parent="Margin/Layout/Left"]
custom_minimum_size = Vector2(0,16)
layout_mode = 2
mouse_filter = 2

[node name="Menu" type="VBoxContainer" parent="Margin/Layout/Left"]
layout_mode = 2
theme_override_constants/separation = 6
'''
for i,(name,key) in enumerate([('Campaign','CAMPAIGN'),('Operations','OPERATIONS'),('Hangar','HANGAR'),('Archive','ARCHIVE'),('Settings','SETTINGS'),('Quit','QUIT')]):
    header+=f'''
[node name="{name}" type="Button" parent="Margin/Layout/Left/Menu"]
custom_minimum_size = Vector2(300,52)
layout_mode = 2
theme_override_constants/h_separation = 20
theme_override_constants/icon_max_width = 26
theme_override_font_sizes/font_size = 17
theme_override_styles/normal = SubResource("MenuNormal")
theme_override_styles/focus = SubResource("MenuNormal")
text = "{key}"
icon = ExtResource("{i+4}")
alignment = 0
expand_icon = true
script = ExtResource("2")
'''
header+='''
[node name="Fill" type="Control" parent="Margin/Layout/Left"]
layout_mode = 2
size_flags_vertical = 3
mouse_filter = 2

[node name="Version" type="Label" parent="Margin/Layout/Left"]
layout_mode = 2
theme_override_colors/font_color = Color(0.49,0.56,0.64,1)
theme_override_font_sizes/font_size = 12
text = "VERSION"

[node name="Right" type="VBoxContainer" parent="Margin/Layout"]
layout_mode = 2
size_flags_horizontal = 3
mouse_filter = 2

[node name="Top" type="HBoxContainer" parent="Margin/Layout/Right"]
layout_mode = 2
alignment = 2
mouse_filter = 2

[node name="About" type="Button" parent="Margin/Layout/Right/Top"]
custom_minimum_size = Vector2(160,48)
layout_mode = 2
theme_override_font_sizes/font_size = 12
text = "ABOUT"

[node name="Space" type="Control" parent="Margin/Layout/Right"]
layout_mode = 2
size_flags_vertical = 3
mouse_filter = 2

[node name="Test" type="Button" parent="Margin/Layout/Right"]
custom_minimum_size = Vector2(300,58)
layout_mode = 2
size_flags_horizontal = 8
theme_override_font_sizes/font_size = 20
text = "ТЕСТ"
script = ExtResource("2")

[node name="Status" type="PanelContainer" parent="Margin/Layout/Right"]
custom_minimum_size = Vector2(300,0)
layout_mode = 2
size_flags_horizontal = 8
mouse_filter = 2

[node name="Inset" type="MarginContainer" parent="Margin/Layout/Right/Status"]
layout_mode = 2
mouse_filter = 2
theme_override_constants/margin_left = 20
theme_override_constants/margin_right = 20
theme_override_constants/margin_top = 16
theme_override_constants/margin_bottom = 16

[node name="Column" type="VBoxContainer" parent="Margin/Layout/Right/Status/Inset"]
layout_mode = 2
theme_override_constants/separation = 8
mouse_filter = 2

[node name="Stage" type="Label" parent="Margin/Layout/Right/Status/Inset/Column"]
layout_mode = 2
theme_override_colors/font_color = Color(0.92,0.32,0.38,1)
theme_override_font_sizes/font_size = 12
text = "FOUNDATION_STAMP"

[node name="Title" type="Label" parent="Margin/Layout/Right/Status/Inset/Column"]
layout_mode = 2
theme_override_font_sizes/font_size = 15
text = "FOUNDATION_TITLE"

[node name="Note" type="Label" parent="Margin/Layout/Right/Status/Inset/Column"]
layout_mode = 2
theme_override_colors/font_color = Color(0.65,0.71,0.77,1)
theme_override_font_sizes/font_size = 13
text = "FOUNDATION_NOTE"
'''
put('scenes/menu/home_screen.tscn',header)

for name in ['audio','video','controls','interface']:
    put(f'scenes/settings/{name}_tab.tscn',f'''[gd_scene load_steps=2 format=3]
[ext_resource type="Script" path="res://scripts/ui/{name}_tab.gd" id="1"]
[node name="{name.title()}Tab" type="VBoxContainer"]
size_flags_horizontal = 3
script = ExtResource("1")
''')

for name,title,prefix in [('campaign','CAMPAIGN','CAMP'),('operations','OPERATIONS','OPS'),('hangar','HANGAR','HANG'),('archive','ARCHIVE','ARCH')]:
    keys=', '.join(q(f'{prefix}_CARD_{i}') for i in range(1,4))
    put(f'scenes/screens/{name}_screen.tscn',f'''[gd_scene load_steps=3 format=3]
[ext_resource type="PackedScene" path="res://scenes/screens/section_screen.tscn" id="1"]
[ext_resource type="Texture2D" path="res://assets/icons/{name}.svg" id="2"]
[node name="{name.title()}Screen" instance=ExtResource("1")]
title_key = "{title}"
summary_key = "{title}_SUMMARY"
empty_key = "{title}_EMPTY"
card_keys = PackedStringArray({keys})
section_icon = ExtResource("2")
''')
print('Menu, screen resources and Russian localization generated.')
