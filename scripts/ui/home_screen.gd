extends Control
const UI = preload("res://scripts/ui/rift_ui.gd")
var buttons: VBoxContainer
var logo: TextureRect
var status_column: VBoxContainer
var start_button: Button
var panel: Control
func _ready() -> void:
 theme = UI.design_theme();mouse_filter = Control.MOUSE_FILTER_IGNORE
 var margin := MarginContainer.new();margin.name = "Margin";add_child(margin);margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 for edge in ["left","right"]: margin.add_theme_constant_override("margin_"+edge,40)
 for edge in ["top","bottom"]: margin.add_theme_constant_override("margin_"+edge,28)
 var layout := UI.row(36);layout.name = "Layout";margin.add_child(layout)
 var left := UI.column(14);left.name = "Left";left.size_flags_horizontal = Control.SIZE_FILL;left.custom_minimum_size.x = 304;layout.add_child(left)
 logo = TextureRect.new();logo.name = "Logo";logo.texture = load("res://assets/ui/rift_logo.svg");logo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE;logo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED;logo.custom_minimum_size = Vector2(304,102);left.add_child(logo)
 left.add_child(UI.micro("ENTERA / ПРОГРАММА «ОПЛОТ»"));left.add_child(UI.spacer(10))
 buttons = UI.column(8);buttons.name = "Menu";left.add_child(buttons)
 var items := [["Campaign","КАМПАНИЯ","campaign","campaign"],["Operations","ЗАДАНИЯ","operations","operations"],["Hangar","АНГАР","hangar","hangar"],["Archive","АРХИВ","archive","archive"],["Settings","НАСТРОЙКИ","settings","settings"],["Quit","ВЫХОД","quit","quit"]]
 for item: Array in items:
  var b := UI.button(item[1],_activate.bind(StringName(item[2]),item[0]));b.name = item[0];b.quiet = true;b.alignment = HORIZONTAL_ALIGNMENT_LEFT;b.custom_minimum_size = Vector2(304,51);b.add_theme_font_override("font",UI.BOLD);b.add_theme_font_size_override("font_size",17)
  var icon_path := "res://assets/icons/"+str(item[3])+".svg"
  if ResourceLoader.exists(icon_path): b.icon = load(icon_path);b.expand_icon = true;b.add_theme_constant_override("icon_max_width",23);b.add_theme_constant_override("h_separation",20)
  buttons.add_child(b)
 var filler := Control.new();filler.size_flags_vertical = Control.SIZE_EXPAND_FILL;left.add_child(filler)
 left.add_child(UI.micro("2089 / ZERO PROTOCOL   ·   ВЕР. 0.10.0"))
 var right := UI.column(14);right.name = "Right";layout.add_child(right)
 var top := UI.row(12);top.name = "Top";top.alignment = BoxContainer.ALIGNMENT_END;right.add_child(top)
 var identity := UI.column(3);identity.size_flags_horizontal = Control.SIZE_SHRINK_END;top.add_child(identity)
 identity.add_child(UI.section_title((Expedition.pilot_name+" / ПЕРВЫЙ").to_upper() if Expedition.started else "ПРОГРАММА «ОПЛОТ»"))
 identity.add_child(UI.micro("%s / %d CR"%[Expedition.current_base,Expedition.credits] if Expedition.started else "ДОК-17 / ПЕРВИЧНЫЙ ДОПУСК"))
 var about := UI.icon_button("history",func() -> void: NavigationManager.show_info("RIFT: ZERO PROTOCOL","2089. Программа «Оплот».\nМорская высадка и свободная сеть баз.\n\nВерсия 0.10.0 / Godot 4.7.2"),"Об игре");about.name = "About";top.add_child(about)
 var space := Control.new();space.size_flags_vertical = Control.SIZE_EXPAND_FILL;right.add_child(space)
 status_column = UI.column(12)
 status_column.add_child(UI.section_title("ГЛАВА I / ПОГРАНИЧНЫЙ ПОЯС"))
 status_column.add_child(UI.heading("НОЧНОЙ БЕРЕГ",26))
 var trip: Dictionary = Expedition.active_route()
 var checkpoints := {"landing":"МОРЕ · ВЫСАДКА С ВЕРТОЛЁТОВ","base":Expedition.current_base+" · ВЫБОР МАРШРУТА","dock":"МОРСКОЙ ПОДХОД · ПЕРВЫЙ ВЫХОД","road":str(trip.get("id","R01"))+" · ГРУППА В ПУТИ","barrier":"ПОДХОД К ДОКУ","fight":str(trip.get("id","R01"))+" · КОНТАКТ С ИСКАЖЁННЫМ","arrival":str(trip.get("to","A01"))+" · ПОДХОД К ДОКУ","mayak":"БАЗА · ВЫБОР МАРШРУТА"}
 status_column.add_child(UI.paragraph(checkpoints.get(Expedition.checkpoint,"ДОК-17"),14))
 start_button = UI.primary("ПРОДОЛЖИТЬ РЕЙС" if Expedition.started and bool(Expedition.flags.get("ROUTE_ACTIVE",false)) else ("ОТКРЫТЬ КАРТУ" if Expedition.started else "НАЧАТЬ КАМПАНИЮ"),func() -> void:
  if Expedition.started and bool(Expedition.flags.get("ROUTE_ACTIVE",false)): NavigationManager.go(&"expedition")
  else: NavigationManager.go(&"campaign"))
 status_column.add_child(start_button)
 if Expedition.started:
  var actions := UI.row(8);status_column.add_child(actions)
  actions.add_child(UI.button("НОВАЯ ИГРА",_new_game));actions.add_child(UI.button("КАРТА",func() -> void: NavigationManager.go(&"campaign")))
 panel = UI.panel(status_column,22);panel.name = "Status";panel.custom_minimum_size.x = 350;panel.size_flags_horizontal = Control.SIZE_SHRINK_END;right.add_child(panel)
 var test := UI.button("ПОЛИГОН / ТЕСТ",func() -> void: NavigationManager.last_home_focus = "Test";NavigationManager.go(&"test"));test.name = "Test";test.custom_minimum_size = Vector2(350,50);test.size_flags_horizontal = Control.SIZE_SHRINK_END;right.add_child(test)
 resized.connect(_layout_density);_layout_density()
func _layout_density() -> void:
 if not is_instance_valid(buttons): return
 var compact := size.y < 640
 logo.custom_minimum_size.y = 82 if compact else 102
 buttons.add_theme_constant_override("separation",5 if compact else 8)
 for b: Control in buttons.get_children(): b.custom_minimum_size.y = 46 if compact else 51
func _activate(route: StringName,id: String) -> void:
 NavigationManager.last_home_focus = id
 if route == &"quit": NavigationManager.confirm_exit()
 else: NavigationManager.go(route)
func _new_game() -> void:
 NavigationManager.go(&"enlistment")
func focus_initial() -> void:
 if NavigationManager.last_home_focus == "Test": $Margin/Layout/Right/Test.grab_focus();return
 var node := buttons.get_node_or_null(NodePath(NavigationManager.last_home_focus))
 if node != null: node.grab_focus()
 else: start_button.grab_focus()
