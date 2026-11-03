extends Control
const UI = preload("res://scripts/ui/rift_ui.gd")
var map: Control
var details: VBoxContainer
var launch: Button
var selected := "A02"
var graph_buttons: Dictionary = {}
var status: Label
class NetworkField extends Control:
 var screen: Control
 var zoom := 1.0
 var pan := Vector2.ZERO
 var dragging := false
 var phase := 0.0
 func _ready() -> void: mouse_filter = Control.MOUSE_FILTER_STOP;clip_contents = true;resized.connect(queue_redraw)
 func point(id: String) -> Vector2:
  var pos: Vector2 = Expedition.NODES[id].map
  return Vector2(20+pos.x*(size.x/3-42),84+pos.y*(size.y-156))*zoom+pan
 func _process(delta: float) -> void: phase += delta*.08;queue_redraw()
 func _draw() -> void:
  draw_rect(Rect2(Vector2.ZERO,size),Color("07121a"))
  var region := size.x/3.0
  for x in range(0,int(size.x),26): draw_line(Vector2(x,0),Vector2(x,size.y),Color(.3,.58,.66,.055),1)
  for y in range(0,int(size.y),26): draw_line(Vector2(0,y),Vector2(size.x,y),Color(.3,.58,.66,.055),1)
  for k in range(10):
   var line := PackedVector2Array()
   for j in range(42): line.append(Vector2(float(j)/41*size.x,80+k*37+sin(float(j)*.42+k)*13))
   draw_polyline(line,Color(.30,.58,.58,.055),1,true)
  for edge: Array in Expedition.MAP_LINKS:
   var a := point(edge[0]);var b := point(edge[1]);var is_adjacent: bool = Expedition.current_base in [edge[0],edge[1]]
   var chosen: bool = selected_edge(edge)
   var c := Color("d6af65") if chosen else (Color("638b99") if is_adjacent else Color("304b5b"))
   draw_line(a,b,Color(c,.10),7,true);draw_line(a,b,c,1.4 if is_adjacent else 1,true)
  for i in range(3):
   var x := float(i)*region
   if i > 0:
    draw_rect(Rect2(x,0,region,size.y),Color("0b151f"))
    for j in range(36):
     var cx := x+fposmod(float(j)*83.7+sin(phase+j)*11,region)
     var cy := fposmod(float(j)*67.4+cos(phase+j)*9,size.y)
     draw_circle(Vector2(cx,cy),45+fposmod(j*17.0,65),Color(.12,.19,.25,.075))
    for y in range(18,int(size.y),23): draw_line(Vector2(x+10,y),Vector2(x+region-10,y-24),Color(.4,.53,.65,.025),5)
    draw_string(UI.MONO,Vector2(x+18,size.y*.48),"КОНТУР ЗАКРЫТ",HORIZONTAL_ALIGNMENT_LEFT,-1,12,Color("64808f"))
    draw_string(UI.FONT,Vector2(x+18,size.y*.48+25),"Навигационные данные",HORIZONTAL_ALIGNMENT_LEFT,-1,12,Color("4f6978"))
    draw_string(UI.FONT,Vector2(x+18,size.y*.48+43),"недоступны",HORIZONTAL_ALIGNMENT_LEFT,-1,12,Color("4f6978"))
   draw_line(Vector2(x,0),Vector2(x,size.y),Color("2a414f"),1)
   draw_string(UI.MONO,Vector2(x+16,27),["01 / ПОГРАНИЧНЫЙ ПОЯС","02 / НЕИЗВЕСТНЫЙ СЕКТОР","03 / НЕИЗВЕСТНЫЙ СЕКТОР"][i],HORIZONTAL_ALIGNMENT_LEFT,-1,10,UI.CYAN if i == 0 else Color("607888"))
   draw_line(Vector2(x+14,44),Vector2(x+region-15,44),Color("9a8050") if i == 0 else Color("273846"),1)
  draw_string(UI.MONO,Vector2(15,size.y-17),"● ТЕКУЩАЯ БАЗА    ◇ ДОСТУПНЫЙ ПЕРЕХОД",HORIZONTAL_ALIGNMENT_LEFT,-1,10,Color("9eb7bb"))
 func selected_edge(edge: Array) -> bool: return Expedition.current_base in [edge[0],edge[1]] and screen.selected in [edge[0],edge[1]]
 func _gui_input(event: InputEvent) -> void:
  if event is InputEventMouseButton and event.pressed and event.button_index in [MOUSE_BUTTON_WHEEL_UP,MOUSE_BUTTON_WHEEL_DOWN]:
   accept_event()
class OutpostButton extends Button:
 var id := ""
 var selected := false
 var adjacent := false
 var current := false
 var visited := false
 func _ready() -> void:
  for state: String in ["normal","hover","pressed","focus"]: add_theme_stylebox_override(state,StyleBoxEmpty.new())
  mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
  mouse_entered.connect(queue_redraw);mouse_exited.connect(queue_redraw);focus_entered.connect(queue_redraw);focus_exited.connect(queue_redraw)
 func _draw() -> void:
  var c := Color("e9bf69") if selected else (Color("9ce1d9") if current else (Color("91b7c7") if adjacent else Color("496676")))
  var p := Vector2(19,18)
  draw_circle(p,18,Color("091923"));draw_arc(p,17,0,TAU,32,Color(c,.3),1,true)
  var points := PackedVector2Array([p+Vector2(0,-11),p+Vector2(10,0),p+Vector2(0,11),p+Vector2(-10,0),p+Vector2(0,-11)])
  draw_polyline(points,c,2 if selected or current else 1,true)
  if current: draw_circle(p,4,c)
  elif visited: draw_rect(Rect2(p-Vector2(3,3),Vector2(6,6)),c)
  if selected or is_hovered() or has_focus(): draw_arc(p,21,0,TAU,36,c,1,true)
  draw_string(UI.MONO,Vector2(7,47),id,HORIZONTAL_ALIGNMENT_LEFT,-1,10,c)
func _ready() -> void:
 theme = UI.design_theme();_build()
func _build() -> void:
 var bg := ColorRect.new();bg.color = Color("050d14");add_child(bg);bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 var margin := MarginContainer.new();margin.name = "Margin";add_child(margin);margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 for edge in ["left","right","top","bottom"]: margin.add_theme_constant_override("margin_"+edge,24)
 var column := UI.column(14);column.name = "Column";margin.add_child(column)
 var header := UI.row(16);header.name = "Header";column.add_child(header)
 var back := UI.icon_button("back",NavigationManager.back,"Главное меню");back.name = "Back";header.add_child(back)
 var title := UI.column(2);header.add_child(title);title.add_child(UI.heading("КАМПАНИЯ / СЕТЬ БАЗ",27));title.add_child(UI.micro("ГЛАВА I  /  2089  /  НОЧНОЙ БЕРЕГ"))
 var new_game := UI.button("НОВАЯ ИГРА",_new_game);header.add_child(new_game)
 if not Expedition.started:
  var introduction := UI.row(16);column.add_child(introduction)
  introduction.add_child(UI.paragraph("Вступите в программу «Оплот». Личное дело, электронная подпись, инструктаж и первая высадка с моря.",17,UI.TEXT))
  introduction.add_child(UI.primary("СОЗДАТЬ ПИЛОТА",func() -> void: NavigationManager.go(&"enlistment")))
 var body := UI.row(18);body.size_flags_vertical = Control.SIZE_EXPAND_FILL;column.add_child(body)
 map = NetworkField.new();map.screen = self;map.custom_minimum_size.y = 320;map.size_flags_horizontal = Control.SIZE_EXPAND_FILL;map.size_flags_vertical = Control.SIZE_EXPAND_FILL;body.add_child(map)
 for id: String in Expedition.NODES:
  var b := OutpostButton.new();b.id = id;b.tooltip_text = id+" / "+str(Expedition.NODES[id].name);b.pressed.connect(_select.bind(id));map.add_child(b);graph_buttons[id] = b
 var side := UI.column(10);side.custom_minimum_size.x = 270;side.size_flags_horizontal = Control.SIZE_FILL;body.add_child(side)
 side.add_child(UI.micro("ОПЕРАТИВНЫЙ ПЛАНШЕТ"));side.add_child(UI.heading(Expedition.pilot_name.to_upper() if Expedition.started else "НОВЫЙ ПИЛОТ",20));side.add_child(UI.micro("ПОЗЫВНОЙ: ПЕРВЫЙ"));side.add_child(UI.rule())
 details = UI.column(10);side.add_child(details)
 var fill := Control.new();fill.size_flags_vertical = Control.SIZE_EXPAND_FILL;side.add_child(fill)
 status = UI.paragraph("",14);side.add_child(status)
 launch = UI.primary("ВЫБРАТЬ МАРШРУТ",_launch);side.add_child(launch)
 side.add_child(UI.micro("%d CR  /  СПЛАВ %d"%[Expedition.credits,Expedition.alloy]))
 column.add_child(UI.micro("СОСЕДНИЕ УЗЛЫ СОЕДИНЕНЫ ПУТЯМИ. МОЖНО ВЕРНУТЬСЯ. РЕГИОНЫ II–III ПОКА В ТУМАНЕ."))
 map.resized.connect(_place_nodes)
 if Expedition.current_base == selected: selected = "A01" if selected != "A01" else "A02"
 _select(selected);call_deferred("_place_nodes")
func _place_nodes() -> void:
 for id: String in graph_buttons:
  var b: Button = graph_buttons[id];b.position = map.point(id)-Vector2(19,18);b.size = Vector2(38,52)
 map.queue_redraw()
func _select(id: String) -> void:
 selected = id
 for node in details.get_children(): details.remove_child(node);node.queue_free()
 var info: Dictionary = Expedition.NODES[id]
 details.add_child(UI.micro(id+" / БАЗА"));details.add_child(UI.heading(info.name,25));details.add_child(UI.section_title(info.type));details.add_child(UI.paragraph(info.services,15))
 var route: Dictionary = Expedition.route_between(Expedition.current_base,id)
 if not route.is_empty():
  details.add_child(UI.rule());details.add_child(UI.micro(str(route.id)+" / "+str(route.name).to_upper()));details.add_child(UI.paragraph("Условия: ночь · дождь\nРиск: умеренный\nЗа первый проход: %d CR"%(0 if Expedition.flags.get("REWARD_"+str(route.id),false) else int(route.reward)),15,UI.TEXT))
 for key: String in graph_buttons:
  var b = graph_buttons[key];b.selected = key == id;b.current = key == Expedition.current_base;b.visited = key in Expedition.visited;b.adjacent = not Expedition.route_between(Expedition.current_base,key).is_empty();b.queue_redraw()
 if not Expedition.started:
  launch.text = "НОВАЯ ИГРА";launch.disabled = false;status.text = "Сначала оформите допуск пилота."
 elif Expedition.flags.get("ROUTE_ACTIVE",false):
  launch.text = "ПРОДОЛЖИТЬ ВЫХОД";launch.disabled = false;status.text = "Есть незавершённый выход. Контрольная точка сохранена."
 else:
  launch.disabled = not Expedition.can_depart(id);launch.text = "ВЫЙТИ НА "+id
  status.text = "Вы на этой базе." if id == Expedition.current_base else ("Доступен переход в обе стороны." if not route.is_empty() else "До этой базы нужно пройти через соседние узлы.")
 map.queue_redraw()
func _launch() -> void:
 if not Expedition.started: NavigationManager.go(&"enlistment")
 elif Expedition.flags.get("ROUTE_ACTIVE",false): NavigationManager.go(&"expedition")
 elif Expedition.depart(selected): NavigationManager.go(&"expedition")
 else: status.text = Expedition.last_error if not Expedition.last_error.is_empty() else "Этот переход недоступен."
func _new_game() -> void:
 if Expedition.started: NavigationManager.show_confirm("НОВАЯ ИГРА","Оформить новое личное дело? Текущая кампания будет заменена только после подписи и инструктажа.","СОЗДАТЬ ПИЛОТА",func() -> void: NavigationManager.go(&"enlistment"))
 else: NavigationManager.go(&"enlistment")
func focus_initial() -> void: $Margin/Column/Header/Back.grab_focus()
