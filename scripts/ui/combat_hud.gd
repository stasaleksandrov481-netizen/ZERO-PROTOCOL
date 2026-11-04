extends Control
const UI = preload("res://scripts/ui/rift_ui.gd")
const Stick = preload("res://scripts/gameplay/virtual_hand_stick.gd")
const Hold = preload("res://scripts/ui/hold_button.gd")
const RadioView = preload("res://scripts/ui/radio_widget.gd")
const Dispatch = preload("res://scripts/systems/radio_dispatch.gd")
signal move_changed(axis: float)
signal resume_requested
signal restart_requested
signal leave_requested
signal order_selected(value: String)
var actor: Node2D
var enemy: Node2D
var run_button: Button
var enemy_intent: Label
var enemy_health: ProgressBar
var mission := false
var paused := false
var overlay := ""
var dispatcher := Dispatch.new()
var radio: Control
var objective: Label
var objective_meta: Label
var integrity_text: Label
var progress: ProgressBar
var interact: Button
var left_walk: Button
var right_walk: Button
var crew: Button
var title: Label
var header: Control
var health := 100.0
var convoy := 100.0
var frame_clock := 0.0
var left_held := false
var right_held := false
var modal_layer: Control
var modal_panel: Control
var order_panel: Control
var settings_overlay: Control
var modal_center: CenterContainer
var previous_focus: Control
var layout_ready := false
var last_radio_id := ""
var last_objective := ""
var objective_tween: Tween
var history_records: VBoxContainer
var history_tabs: Dictionary = {}
func _ready() -> void:
 mouse_filter = Control.MOUSE_FILTER_IGNORE;theme = UI.design_theme()
 header = Control.new();header.name = "Top";header.mouse_filter = Control.MOUSE_FILTER_IGNORE;add_child(header)
 _named(header,UI.icon_button("campaign",Callable(),"Карта кампании"),"Back")
 _named(header,UI.label("АТ-01  /  ОПЛОТ  0.00 М/С",11,Color("86a6b4")),"Status")
 var balance := CheckButton.new();balance.text = "Стабилизация";balance.button_pressed = true;_named(header,balance,"Balance")
 _named(header,UI.button("СБРОС"),"Reset");_named(header,UI.button("ТОЛЧОК"),"Impulse")
 _named(header,UI.icon_button("pause",Callable(),"Пауза"),"Pause")
 _named(header,UI.icon_button("settings",func() -> void:
  get_parent()._set_paused(true);show_settings(),"Настройки"),"Settings")
 crew = UI.button("КЕДР / ПРИКРЫВАЙ");crew.add_theme_font_size_override("font_size",11);_named(header,crew,"Crew");crew.hide()
 title = UI.label("ПОЛИГОН / АТ-01",20,UI.TEXT);title.clip_text = true;_named(self,title,"Title")
 var zoom := Control.new();zoom.name = "Zoom";zoom.mouse_filter = Control.MOUSE_FILTER_IGNORE;add_child(zoom)
 _named(zoom,UI.button("−"),"Out");_named(zoom,UI.button("100%"),"Reset");_named(zoom,UI.button("+"),"In")
 for key: String in ["Out","Reset","In"]: zoom.get_node(key).add_theme_font_size_override("font_size",14)
 for index in range(2):
  var stick := Stick.new();stick.caption = "ЛЕВАЯ РУКА" if index == 0 else "ПРАВАЯ РУКА";stick.hand_index = index
  _named(self,stick,"LeftStick" if index == 0 else "RightStick")
 var help := UI.label("",11,UI.MUTED);help.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER;help.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART;_named(self,help,"Help")
 var goal := UI.column(4);goal.name = "Objectives";goal.mouse_filter = Control.MOUSE_FILTER_IGNORE;add_child(goal)
 var caption := UI.label("ТЕКУЩАЯ ЗАДАЧА   ///",10,Color("d7b167"));goal.add_child(caption)
 objective = UI.paragraph("Проверьте приводы и стойку",14,UI.TEXT);goal.add_child(objective)
 objective_meta = UI.label("АТ-01 «ОПЛОТ»",10,Color("7c9ca9"));objective_meta.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART;goal.add_child(objective_meta);objective_meta.hide()
 progress = ProgressBar.new();progress.max_value = 4800;progress.show_percentage = false;progress.hide();goal.add_child(progress)
 integrity_text = UI.label("",12,UI.MUTED);integrity_text.hide();add_child(integrity_text)
 interact = UI.primary("ВЗАИМОДЕЙСТВИЕ");_named(self,interact,"Interact");interact.hide()
 left_walk = Hold.new();left_walk.text = "◀ ШАГ";right_walk = Hold.new();right_walk.text = "ШАГ ▶"
 for b: Button in [left_walk,right_walk]: b.add_theme_font_size_override("font_size",12);b.modulate.a = .84;add_child(b)
 left_walk.tooltip_text = "Шаг влево / удерживать";right_walk.tooltip_text = "Шаг вправо / удерживать"
 left_walk.hold_changed.connect(func(value: bool) -> void: left_held = value;_movement())
 right_walk.hold_changed.connect(func(value: bool) -> void: right_held = value;_movement())
 run_button = preload("res://scripts/ui/run_toggle.gd").new();run_button.text = "БЕГ";run_button.pressed.connect(func() -> void: AudioManager.play_ui());run_button.add_theme_font_size_override("font_size",13);run_button.tooltip_text = "Бег / Shift. При падении: встать / R.";add_child(run_button)
 enemy_intent = UI.label("",13,UI.RED);enemy_intent.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER;add_child(enemy_intent);enemy_intent.hide()
 enemy_health = ProgressBar.new();enemy_health.show_percentage = false;enemy_health.custom_minimum_size.y = 4;add_child(enemy_health);enemy_health.hide()
 radio = RadioView.new();radio.name = "Radio";add_child(radio);radio.bind(dispatcher);radio.history_requested.connect(func() -> void: history_requested())
 dispatcher.message_started.connect(func(message: Dictionary) -> void:
  if str(message.id) != last_radio_id: last_radio_id = str(message.id);AudioManager.play_radio())
 modal_layer = Control.new();modal_layer.name = "Overlay";modal_layer.z_index = 50;add_child(modal_layer);modal_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);modal_layer.hide()
 layout_ready = true;resized.connect(layout_hud);layout_hud()
func _named(parent: Node,node: Node,id: String) -> void: node.name = id;parent.add_child(node)
func configure_mission() -> Dictionary:
 mission = true;crew.show();$Top/Balance.hide();$Top/Reset.hide();$Top/Impulse.hide();radio.show();$Objectives.show();objective_meta.show();layout_hud()
 return {"objective":objective,"integrity_text":integrity_text,"progress":progress,"interact":interact,"left_walk":left_walk,"right_walk":right_walk,"radio_name":radio.callsign,"radio_body":radio.body,"radio_panel":radio}
func layout_hud() -> void:
 if not layout_ready: return
 header.position = Vector2.ZERO;header.size = Vector2(size.x,64)
 $Top/Back.position = Vector2(17,12);$Top/Back.size = Vector2(58,46)
 title.position = Vector2(101,12);title.size = Vector2(size.x-530,28)
 $Top/Status.position = Vector2(102,41);$Top/Status.size = Vector2(500,18)
 $Top/Settings.position = Vector2(size.x-67,13);$Top/Settings.size = Vector2(48,44)
 $Top/Pause.position = Vector2(size.x-130,13);$Top/Pause.size = Vector2(48,44)
 $Zoom.position = Vector2(size.x-315,13);$Zoom.size = Vector2(164,43)
 $Zoom/Out.position = Vector2.ZERO;$Zoom/Out.size = Vector2(43,43)
 $Zoom/Reset.position = Vector2(44,0);$Zoom/Reset.size = Vector2(76,43)
 $Zoom/In.position = Vector2(121,0);$Zoom/In.size = Vector2(43,43)
 $Top/Balance.position = Vector2(25,115);$Top/Balance.size = Vector2(188,42)
 $Top/Reset.position = Vector2(25,165);$Top/Reset.size = Vector2(92,42)
 $Top/Impulse.position = Vector2(125,165);$Top/Impulse.size = Vector2(95,42)
 crew.position = Vector2(size.x*.5-105,size.y-60);crew.size = Vector2(210,42)
 var stick_size := floorf(clampf(size.y*.389,210,295))
 $LeftStick.size = Vector2.ONE*stick_size;$RightStick.size = Vector2.ONE*stick_size
 $LeftStick.position = Vector2(34,size.y-stick_size-55);$RightStick.position = Vector2(size.x-stick_size-34,size.y-stick_size-55)
 $Objectives.position = Vector2(35,96);$Objectives.size = Vector2(203,76)
 left_walk.position = Vector2(size.x*.5-197,size.y-60);left_walk.size = Vector2(76,42)
 right_walk.position = Vector2(size.x*.5+121,size.y-60);right_walk.size = Vector2(76,42)
 interact.position = Vector2(size.x*.5-150,size.y-126);interact.size = Vector2(300,48)
 $Help.position = Vector2(size.x*.5-195,size.y-173);$Help.size = Vector2(390,44)
 run_button.position = Vector2(size.x*.5-64,size.y-116);run_button.size = Vector2(128,44)
 var enemy_card := _enemy_card()
 enemy_intent.position = enemy_card.position+Vector2(8,4);enemy_intent.size = Vector2(enemy_card.size.x-16,26)
 enemy_health.position = enemy_card.position+Vector2(44,34);enemy_health.size = Vector2(enemy_card.size.x-88,5)
 # Active calls replace the right diagnostic card, leaving both fighters visible.
 radio.position = Vector2(size.x-442,85);radio.size = Vector2(420,194);radio.visible = mission
 radio.idle_button.position = Vector2(224,0);radio.idle_button.size = Vector2(196,44)
 if not mission: title.text = "ПОЛИГОН / АТ-01";$Objectives.hide()
 if is_instance_valid(modal_panel): modal_panel.custom_minimum_size.x = minf(650,size.x-64)
 if is_instance_valid(order_panel): order_panel.position = Vector2(size.x*.5-125,size.y-270)
func _process(delta: float) -> void:
 dispatcher.paused = paused or overlay != "";dispatcher.tick(delta);frame_clock += delta
 if is_instance_valid(radio.idle_button): radio.idle_button.position = Vector2(radio.size.x-196,0);radio.idle_button.size = Vector2(196,44)
 if is_instance_valid(actor):
  $LeftStick.drive_load = actor.arm_load[0];$RightStick.drive_load = actor.arm_load[1]
  $LeftStick.queue_redraw();$RightStick.queue_redraw()
  run_button.text = ("ВСТАТЬ" if OS.has_feature("android") else "ВСТАТЬ / R") if actor.fallen else ("БЕГ ВКЛ." if run_button.button_pressed else ("БЕГ" if OS.has_feature("android") else "БЕГ / SHIFT"))
  run_button.visible = not interact.visible and overlay == ""
 if is_instance_valid(enemy):
  enemy_intent.visible = enemy.enabled and enemy.state != "dead";enemy_health.visible = enemy_intent.visible
  enemy_intent.text = str(enemy.telegraph) if not str(enemy.telegraph).is_empty() else "КЛЫК / БРОНЯ И ЦЕЛОСТНОСТЬ"
  enemy_health.max_value = enemy.MAX_HEALTH;enemy_health.value = enemy.health
 if mission and objective.text != last_objective:
  last_objective = objective.text
  if is_instance_valid(objective_tween): objective_tween.kill()
  if not bool(SettingsManager.get_value("video/reduced_motion")):
   objective.modulate.a = .35;objective_tween = create_tween();objective_tween.tween_property(objective,"modulate:a",1.0,.38)
  else: objective.modulate.a = 1
 queue_redraw()
func _plate(rect: Rect2,alpha: float = .76,accent: bool = false) -> void:
 var p := PackedVector2Array([rect.position+Vector2(11,0),rect.position+Vector2(rect.size.x,0),rect.end-Vector2(0,11),rect.end-Vector2(11,0),rect.position+Vector2(0,rect.size.y),rect.position+Vector2(0,11)])
 draw_colored_polygon(p,Color(.015,.042,.061,alpha));p.append(p[0]);draw_polyline(p,Color(.46,.67,.76,.55),1,true)
 draw_line(rect.position+Vector2(5,11),rect.position+Vector2(14,2),Color("d6ab5d") if accent else Color("6d9aa9"),2,true)
 draw_line(rect.position+Vector2(16,4),rect.position+Vector2(65,4),Color(.48,.68,.75,.20),1,true)
func _enemy_card() -> Rect2:
 var width := clampf(size.x-716.0,240,388)
 var center := minf(size.x*.5,size.x-454-width*.5)
 return Rect2(center-width*.5,79,width,45)
func _draw() -> void:
 if not layout_ready: return
 var w := size.x
 var compact := size.y < 620
 _plate(Rect2(16,12,w-335,48),.54)
 draw_line(Vector2(83,20),Vector2(83,51),Color("c3a15c"),2)
 if enemy_intent.visible: _plate(_enemy_card(),.76,true)
 if mission:
  _plate(Rect2(22,89,225,91),.80,true)
  # A quiet route trace gives direction and distance without covering the world.
  var route_ratio := clampf(float(progress.value)/maxf(1,progress.max_value),0,1)
  draw_line(Vector2(36,174),Vector2(231,174),Color(.38,.58,.66,.25),2)
  draw_line(Vector2(36,174),Vector2(36+195*route_ratio,174),Color("d4b06d"),2)
  var diag_y := 189.0
  _plate(Rect2(22,diag_y,225,92 if compact else 124),.80,true)
  draw_string(UI.FONT,Vector2(36,diag_y+17),"АТ-01 / ТЕЛЕМЕТРИЯ",HORIZONTAL_ALIGNMENT_LEFT,-1,11,Color("a7c1c9"))
  draw_line(Vector2(36,diag_y+24),Vector2(231,diag_y+24),Color(.48,.67,.73,.25),1)
  var load_value: float = actor.load_ratio if is_instance_valid(actor) else 0
  var mobility: String = {"stagger":"ОПОРА","falling":"СБИТА","down":"НА ЗЕМЛЕ","rising":"ПОДЪЁМ"}.get(actor.balance.state,"НОРМА" if health > 30 else "КРИТИЧНО") if is_instance_valid(actor) else "НОРМА"
  var labels := ["ЦЕЛОСТНОСТЬ","РЕАКТОР","ДАВЛЕНИЕ","МОБИЛЬНОСТЬ"]
  var values := ["%d %%"%ceili(health),"%.1f МВт"%(4.2+load_value*1.5),"%.1f МПа"%(22+load_value*12),mobility]
  for i in range(4):
   var y := diag_y+40+i*(15.0 if compact else 22.0)
   draw_circle(Vector2(40,y-4),3,Color("80b7c5"));draw_string(UI.FONT,Vector2(52,y),labels[i],HORIZONTAL_ALIGNMENT_LEFT,-1,10,Color("96afb9"))
   draw_string(UI.MONO,Vector2(167,y),values[i],HORIZONTAL_ALIGNMENT_LEFT,-1,11,(Color("a5d3ab") if mobility == "НОРМА" else Color("d7b167")) if i == 3 else UI.TEXT)
  if not radio.active or radio.collapsed: _hull_diagram(Rect2(w-223,143,201,122 if compact else 162))
 draw_polyline(PackedVector2Array([Vector2(0,size.y-42),Vector2(35,size.y-42),Vector2(49,size.y-22),Vector2(293,size.y-22),Vector2(308,size.y-37)]),Color(.38,.63,.73,.35),1,true)
 draw_polyline(PackedVector2Array([Vector2(w,size.y-42),Vector2(w-35,size.y-42),Vector2(w-49,size.y-22),Vector2(w-293,size.y-22),Vector2(w-308,size.y-37)]),Color(.38,.63,.73,.35),1,true)
func _hull_diagram(rect: Rect2) -> void:
 _plate(rect,.74,true)
 var p := rect.position
 if rect.size.y < 140:
  draw_string(UI.FONT,p+Vector2(14,20),"КОНТУР ЗАЩИТЫ",HORIZONTAL_ALIGNMENT_LEFT,-1,11,UI.CYAN)
  var titles := ["ГОЛОВА","КОРПУС","П. РУКА","Л. РУКА","П. НОГА","Л. НОГА"]
  for i in range(6):
   var point := p+Vector2(14+(i%2)*92,47+(i/2)*25)
   draw_circle(point+Vector2(0,-4),2.5,Color("83bd90"));draw_string(UI.FONT,point+Vector2(9,0),titles[i],HORIZONTAL_ALIGNMENT_LEFT,-1,10,UI.MUTED)
  return
 draw_string(UI.FONT,p+Vector2(14,17),"СОСТОЯНИЕ КОРПУСА",HORIZONTAL_ALIGNMENT_LEFT,-1,10,Color("b1c7cc"))
 var good := Color("83bd90");var warn := Color("d5b265")
 var o := p+Vector2(45,74)
 draw_arc(o+Vector2(0,-27),7,0,TAU,24,good,1,true)
 draw_rect(Rect2(o+Vector2(-12,-17),Vector2(24,34)),Color(good,.13));draw_rect(Rect2(o+Vector2(-12,-17),Vector2(24,34)),good,false,1)
 for side in [-1,1]:
  draw_polyline(PackedVector2Array([o+Vector2(side*13,-13),o+Vector2(side*23,-8),o+Vector2(side*25,19),o+Vector2(side*18,23),o+Vector2(side*15,4)]),good,1,true)
  draw_polyline(PackedVector2Array([o+Vector2(side*4,17),o+Vector2(side*5,37),o+Vector2(side*12,53),o+Vector2(side*20,53),o+Vector2(side*13,32),o+Vector2(side*12,17)]),good,1,true)
 var names := ["ГОЛОВА","КОРПУС","П. РУКА","Л. РУКА","П. НОГА","Л. НОГА"]
 for i in range(6):
  var c := warn if i == 1 and health < 60 else good
  draw_string(UI.FONT,p+Vector2(84,41+i*16),names[i],HORIZONTAL_ALIGNMENT_LEFT,-1,9,Color("9eb7c0"))
  draw_rect(Rect2(p+Vector2(160,31+i*16),Vector2(28,13)),Color(c,.12));draw_rect(Rect2(p+Vector2(160,31+i*16),Vector2(28,13)),Color(c,.35),false,1)
  draw_string(UI.MONO,p+Vector2(166,41+i*16),"OK" if c == good else "!!",HORIZONTAL_ALIGNMENT_LEFT,-1,9,c)
 draw_string(UI.FONT,p+Vector2(14,150),"□ ИСПРАВНО    □ ПОВРЕЖДЕНО",HORIZONTAL_ALIGNMENT_LEFT,-1,8,Color("779592"))
func _movement() -> void: move_changed.emit(float(int(right_held)-int(left_held)))
func release_movement() -> void:
 left_walk.release();right_walk.release();left_held = false;right_held = false;move_changed.emit(0)
func contains_pointer(point: Vector2) -> bool:
 if overlay != "" or is_instance_valid(settings_overlay): return true
 var guide := get_node_or_null("FieldGuide")
 if guide != null and guide.is_visible_in_tree() and guide.close_button.get_global_rect().has_point(point): return true
 var controls: Array[Control] = [$Top/Back,$Top/Pause,$Top/Settings,$Top/Balance,$Top/Reset,$Top/Impulse,$Zoom,$LeftStick,$RightStick,interact,left_walk,right_walk,crew,run_button]
 for node: Control in controls:
  if node.is_visible_in_tree() and Rect2(Vector2.ZERO,node.size).has_point(node.get_global_transform_with_canvas().affine_inverse()*point): return true
 if mission:
  var local := radio.get_global_transform_with_canvas().affine_inverse()*point
  if radio.hit_rect().has_point(local): return true
 if is_instance_valid(order_panel) and Rect2(Vector2.ZERO,order_panel.size).has_point(order_panel.get_global_transform_with_canvas().affine_inverse()*point): return true
 return false
func _clear_modal() -> void:
 if is_instance_valid(modal_panel): modal_panel.get_parent().remove_child(modal_panel);modal_panel.queue_free()
 modal_panel = null
func _modal(kind: String) -> VBoxContainer:
 previous_focus = get_viewport().gui_get_focus_owner()
 _clear_modal();overlay = kind;modal_layer.show()
 for node in modal_layer.get_children(): modal_layer.remove_child(node);node.queue_free()
 var shade := ColorRect.new();shade.color = Color(.012,.023,.034,.86);modal_layer.add_child(shade);shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 modal_center = CenterContainer.new();modal_layer.add_child(modal_center);modal_center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 var content := UI.column(15);modal_panel = UI.panel(content,28);modal_panel.custom_minimum_size.x = minf(650,size.x-64);modal_center.add_child(modal_panel)
 call_deferred("_fit_modal")
 return content
func _fit_modal() -> void:
 if not is_instance_valid(modal_panel): return
 modal_panel.reset_size();_focus_buttons(modal_panel)
func _focus_buttons(node: Node) -> bool:
 if node is Button and not node.disabled and node.is_visible_in_tree(): node.grab_focus();return true
 for child in node.get_children():
  if _focus_buttons(child): return true
 return false
func show_pause() -> void:
 var content := _modal("pause")
 content.add_child(UI.micro("ОПЛОТ / ЛОКАЛЬНЫЙ КОНТУР"));content.add_child(UI.heading("ПАУЗА",38))
 content.add_child(UI.paragraph(title.text,16))
 if mission: content.add_child(UI.paragraph("Руки: отведите стик назад и вынесите вперёд. Вверх — удар снизу.\nШаг: стрелки / A, D. Бег: кнопка «БЕГ» / Shift. Встать: R.\nКедр: групповой канал. Важные сведения: журнал связи.",14,UI.CYAN))
 content.add_child(UI.primary("ПРОДОЛЖИТЬ",func() -> void: resume_requested.emit()))
 var row := UI.row(10);content.add_child(row)
 row.add_child(UI.button("КОНТРОЛЬНАЯ ТОЧКА" if mission else "СБРОС ПОЛИГОНА",func() -> void: restart_requested.emit()))
 row.add_child(UI.button("НАСТРОЙКИ",show_settings))
 content.add_child(UI.button("КАРТА КАМПАНИИ" if mission else "ГЛАВНОЕ МЕНЮ",func() -> void: leave_requested.emit()))
 layout_hud();call_deferred("_fit_modal")
func close_overlay() -> void:
 if is_instance_valid(settings_overlay): settings_overlay.queue_free();settings_overlay = null;call_deferred("_fit_modal");return
 overlay = "";_clear_modal();modal_layer.hide()
 if is_instance_valid(previous_focus) and previous_focus.is_visible_in_tree(): previous_focus.grab_focus()
func show_report(title_value: String,body_value: String,retry: bool,reward: Dictionary = {}) -> Control:
 var content := _modal("report")
 content.add_child(UI.micro("ENTERA / ОПЕРАТИВНЫЙ ЖУРНАЛ"))
 content.add_child(UI.heading("КОНТРОЛЬНАЯ ТОЧКА ДОСТУПНА" if retry else "РЕЙС ПРИНЯТ",14))
 var title_label := UI.heading(title_value,30);title_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART;content.add_child(title_label)
 content.add_child(UI.paragraph(body_value,17,UI.TEXT))
 if not reward.is_empty():
  var row := UI.row(12);content.add_child(row)
  for item: Array in [["CR",str(reward.get("credits",0))],["СПЛАВ",str(reward.get("alloy",0))],["ОХЛАДИТЕЛЬ",str(reward.get("coolants",0))]]:
   var block := UI.column(5);block.add_child(UI.heading(item[1],28));block.add_child(UI.micro(item[0]));var badge := UI.panel(block,14);badge.size_flags_horizontal = Control.SIZE_EXPAND_FILL;row.add_child(badge)
 content.add_child(UI.primary("ПОВТОРИТЬ С ТОЧКИ" if retry else "ОТКРЫТЬ КАРТУ",func() -> void:
  if retry: restart_requested.emit()
  else: leave_requested.emit()))
 if retry: content.add_child(UI.button("ВЕРНУТЬСЯ К КАРТЕ",func() -> void: leave_requested.emit()))
 layout_hud();call_deferred("_fit_modal");return modal_panel
func history_requested() -> void:
 get_parent().call("open_radio_history")
func show_history(log: Array) -> void:
 var content := _modal("radio")
 var head := UI.row();content.add_child(head);head.add_child(UI.heading("ЖУРНАЛ СВЯЗИ",26));head.add_child(UI.button("ЗАКРЫТЬ",func() -> void: resume_requested.emit()))
 var tabs := UI.row(8);content.add_child(tabs);history_tabs.clear()
 for item: Array in [["all","ВЕСЬ ЭФИР"],["prologue","ИНСТРУКТАЖ"],["field","ВЫХОД"]]:
  var id := str(item[0]);var button := UI.button(item[1],func() -> void: _filter_history(log,id));button.add_theme_font_size_override("font_size",12);tabs.add_child(button);history_tabs[id] = button
 var scroll := ScrollContainer.new();scroll.custom_minimum_size.y = minf(280,size.y-260);scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED;content.add_child(scroll)
 history_records = UI.column(12);scroll.add_child(history_records);_filter_history(log,"all")
 layout_hud();call_deferred("_fit_modal")
func _filter_history(log: Array,filter: String) -> void:
 for node in history_records.get_children(): history_records.remove_child(node);node.queue_free()
 for id: String in history_tabs: history_tabs[id].disabled = id == filter
 for i in range(log.size()-1,-1,-1):
  var entry: Dictionary = log[i]
  var intro := str(entry.get("id","")).begins_with("prologue_")
  if (filter == "prologue" and not intro) or (filter == "field" and intro): continue
  var record := UI.column(7)
  record.add_child(UI.micro("ДО ВЫСАДКИ / ИНСТРУКТАЖ" if intro else "ВЫХОД / %02d:%02d"%[int(entry.get("time",0))/60,int(entry.get("time",0))%60]))
  record.add_child(UI.section_title(entry.get("speaker","КАНАЛ")));record.add_child(UI.paragraph(entry.get("text",""),17,UI.TEXT));history_records.add_child(UI.panel(record,16))
 if history_records.get_child_count() == 0: history_records.add_child(UI.paragraph("В этом канале пока нет записей.",17))
func show_orders(current_order: String) -> void:
 if is_instance_valid(order_panel): order_panel.queue_free();order_panel = null;return
 var column := UI.column(8);column.add_child(UI.section_title("КОМАНДА НАПАРНИКУ"))
 for command: String in ["Прикрывай","Атакуй","Ко мне"]:
  var button := UI.button(("●  " if current_order == command else "○  ")+command.to_upper(),func() -> void:
   order_selected.emit(command);if is_instance_valid(order_panel): order_panel.queue_free();order_panel = null)
  column.add_child(button)
 order_panel = UI.panel(column,15);order_panel.custom_minimum_size = Vector2(250,180);add_child(order_panel);layout_hud()
func show_settings() -> void:
 if is_instance_valid(settings_overlay): return
 settings_overlay = load("res://scenes/settings/settings_screen.tscn").instantiate();settings_overlay.z_index = 50;modal_layer.add_child(settings_overlay);settings_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 var back: Button = settings_overlay.get_node("Margin/Column/Header/Back")
 for connection: Dictionary in back.pressed.get_connections(): back.pressed.disconnect(connection.callable)
 back.pressed.connect(func() -> void: settings_overlay.queue_free();settings_overlay = null;AudioManager.play_ui("back");call_deferred("_fit_modal"))
