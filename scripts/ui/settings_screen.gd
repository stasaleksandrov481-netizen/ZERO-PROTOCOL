extends Control
const UI = preload("res://scripts/ui/rift_ui.gd")
const TAB_SCENES := [preload("res://scenes/settings/audio_tab.tscn"),preload("res://scenes/settings/video_tab.tscn"),preload("res://scenes/settings/controls_tab.tscn"),preload("res://scenes/settings/interface_tab.tscn")]
var active_tab := -1
var tabs: BoxContainer
var tab_host: VBoxContainer
var save_label: Label
var scroll: ScrollContainer
func _ready() -> void:
 theme = UI.design_theme()
 var bg := ColorRect.new();bg.color = Color("091218");bg.mouse_filter = Control.MOUSE_FILTER_IGNORE;add_child(bg);bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 var margin := MarginContainer.new();margin.name = "Margin";add_child(margin);margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 for edge in ["left","right"]: margin.add_theme_constant_override("margin_"+edge,28)
 for edge in ["top","bottom"]: margin.add_theme_constant_override("margin_"+edge,22)
 var column := UI.column(20);column.name = "Column";margin.add_child(column)
 var header := UI.row(18);header.name = "Header";column.add_child(header)
 var back := UI.icon_button("back",NavigationManager.back,"Назад");back.name = "Back";header.add_child(back)
 var titles := UI.column(4);header.add_child(titles);titles.add_child(UI.heading("СИСТЕМЫ / ПАРАМЕТРЫ",28));titles.add_child(UI.micro("ENTERA · БОРТОВОЙ КОНТУР АТ-01"))
 var body := UI.row(24);body.size_flags_vertical = Control.SIZE_EXPAND_FILL;column.add_child(body)
 var sidebar := UI.column(12);sidebar.custom_minimum_size.x = 180;sidebar.size_flags_horizontal = Control.SIZE_FILL;body.add_child(sidebar)
 sidebar.add_child(UI.section_title("КОНФИГУРАЦИЯ"))
 tabs = UI.column(8);tabs.name = "Tabs";sidebar.add_child(tabs)
 var names := ["АУДИО","ИЗОБРАЖЕНИЕ","УПРАВЛЕНИЕ","ИНТЕРФЕЙС"]
 for i in range(4):
  var button := UI.button(names[i],_select_tab.bind(i));button.toggle_mode = true;button.quiet = true;button.alignment = HORIZONTAL_ALIGNMENT_LEFT;button.add_theme_font_size_override("font_size",14);tabs.add_child(button)
 var spacer := Control.new();spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL;sidebar.add_child(spacer)
 sidebar.add_child(UI.paragraph("Параметры применяются сразу. Настройки сохраняются автоматически.",13))
 scroll = ScrollContainer.new();scroll.name = "Scroll";scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED;scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL;scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL;body.add_child(scroll)
 tab_host = UI.column(12);tab_host.name = "TabHost";scroll.add_child(tab_host)
 var footer := UI.row(18);footer.name = "Footer";column.add_child(footer)
 save_label = UI.micro("");save_label.name = "SaveState";save_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL;footer.add_child(save_label)
 var reset := UI.button("ВОССТАНОВИТЬ ПО УМОЛЧАНИЮ",_reset);reset.name = "Reset";reset.add_theme_font_size_override("font_size",13);footer.add_child(reset)
 SettingsManager.changed.connect(_dirty);SettingsManager.saved.connect(_saved);_select_tab(0);_saved(SettingsManager.save_error.is_empty())
func _select_tab(index: int) -> void:
 if index == active_tab or index < 0 or index >= TAB_SCENES.size(): return
 active_tab = index
 for i in range(tabs.get_child_count()): tabs.get_child(i).set_pressed_no_signal(i == index)
 for node in tab_host.get_children(): tab_host.remove_child(node);node.queue_free()
 tab_host.add_child(TAB_SCENES[index].instantiate());scroll.scroll_vertical = 0;tabs.get_child(index).grab_focus();AudioManager.play_ui()
func focus_initial() -> void: tabs.get_child(maxi(0,active_tab)).grab_focus()
func _dirty(_key: StringName,_value: Variant) -> void: save_label.text = "●  СОХРАНЕНИЕ";save_label.modulate = UI.MUTED
func _saved(success: bool) -> void: save_label.text = "●  ПАРАМЕТРЫ СОХРАНЕНЫ" if success else "●  ОШИБКА СОХРАНЕНИЯ";save_label.modulate = UI.MUTED if success else UI.RED
func _reset() -> void:
 NavigationManager.show_confirm("НАСТРОЙКИ ПО УМОЛЧАНИЮ","Восстановить стандартные параметры изображения, звука и управления?","ВОССТАНОВИТЬ",func() -> void:
  SettingsManager.reset_defaults()
  if SettingsManager.save_error.is_empty(): NavigationManager.toast("Стандартные параметры восстановлены"))
