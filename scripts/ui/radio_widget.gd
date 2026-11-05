extends Control
const UI = preload("res://scripts/ui/rift_ui.gd")
signal history_requested
var dispatcher: RefCounted
class TransmissionFace extends Control:
 var radio: Control
 func _draw() -> void: radio.draw_transmission(self)
var face: Control
var compact_name: Label
var compact_body: Label
var combat_mode := false
var manual_open := false
var face_fade := 0.0
var content_fade := 1.0
var swapping := false
var ending := false
var pending_message: Dictionary = {}
var active := false
var collapsed := false
var message: Dictionary = {}
var callsign: Label
var role: Label
var body: Label
var next_button: Button
var history_button: Button
var collapse_button: Button
var idle_button: Button
var clock := 0.0
var portraits: Texture2D
var person := "echo"
var accent := Color("94c2c5")
const PEOPLE := {
 "echo":{"name":"ЭХО","role":"НИКА ЛЕБЕДЕВА / ДИСПЕТЧЕР","cell":Vector2i(0,0),"color":Color("a4ccce")},
 "kedr":{"name":"КЕДР","role":"ДАНИИЛ КРАВЦОВ / ПИЛОТ","cell":Vector2i(1,0),"color":Color("d4b789")},
 "vetrova":{"name":"ВЕТРОВА","role":"КОМАНДИР СЕКТОРА","cell":Vector2i(0,1),"color":Color("de9691")},
 "taya":{"name":"ТАЯ","role":"ГЛАВНЫЙ МЕХАНИК / ДОК-17","cell":Vector2i(1,1),"color":Color("d8ae85")},
 "unknown":{"name":"НЕИЗВЕСТНЫЙ","role":"АВАРИЙНАЯ ЧАСТОТА / ПОМЕХИ","cell":Vector2i(-1,-1),"color":Color("c6b587")}
}
func _ready() -> void:
 theme = UI.design_theme()
 mouse_filter = Control.MOUSE_FILTER_IGNORE
 face = TransmissionFace.new();face.radio = self;face.mouse_filter = Control.MOUSE_FILTER_IGNORE;add_child(face)
 callsign = UI.heading("ЭХО",22);face.add_child(callsign)
 role = UI.label("",10,UI.MUTED);role.add_theme_font_override("font",UI.MONO);face.add_child(role)
 body = UI.paragraph("",17,UI.TEXT);body.size_flags_horizontal = Control.SIZE_FILL;face.add_child(body)
 next_button = UI.icon_button("next",_advance,"Следующая страница");face.add_child(next_button)
 history_button = UI.icon_button("history",func() -> void: history_requested.emit(),"Журнал связи");face.add_child(history_button)
 collapse_button = UI.button("−",_collapse);collapse_button.quiet = true;collapse_button.tooltip_text = "Свернуть канал";face.add_child(collapse_button)
 idle_button = UI.button("",func() -> void:
  if active: collapsed = false;manual_open = true;_visibility()
  else: history_requested.emit())
 idle_button.quiet = true;add_child(idle_button)
 compact_name = UI.label("СВЯЗЬ / ЖУРНАЛ",11,UI.CYAN);compact_name.mouse_filter = Control.MOUSE_FILTER_IGNORE;idle_button.add_child(compact_name)
 compact_body = UI.paragraph("Канал свободен",13,UI.MUTED);compact_body.add_theme_constant_override("line_spacing",0);compact_body.mouse_filter = Control.MOUSE_FILTER_IGNORE;idle_button.add_child(compact_body)
 resized.connect(_layout);_layout();_visibility()
func bind(value: RefCounted) -> void:
 dispatcher = value;dispatcher.page_fits = _page_fits;dispatcher.message_started.connect(_message);dispatcher.message_finished.connect(func(_id: String) -> void: _sync());dispatcher.state_changed.connect(_sync)
 _sync()
func _page_fits(text: String) -> bool:
 var bounds := UI.FONT.get_multiline_string_size(text,HORIZONTAL_ALIGNMENT_LEFT,maxf(220,size.x-125),17)
 return bounds.y <= 76
func _message(value: Dictionary) -> void:
 if portraits == null: _load_portraits()
 active = true;ending = false
 if face_fade <= .01 and not combat_mode:
  _apply_message(value);content_fade = 0;swapping = false
 elif not message.is_empty() and (str(message.get("id","")) != str(value.id) or int(message.get("page",0)) != int(value.page)):
  pending_message = value.duplicate(true);swapping = true
 else: _apply_message(value)
 _visibility()
func _apply_message(value: Dictionary) -> void:
 message = value.duplicate(true);person = who(str(value.speaker));var data: Dictionary = PEOPLE[person]
 accent = data.color;callsign.text = data.name;role.text = data.role;body.text = str(value.body)
 _update_compact();_layout()
func _update_compact() -> void:
 if not is_instance_valid(compact_name) or ending: return
 compact_name.text = str(PEOPLE[person].name)+" / СВЯЗЬ" if active else "СВЯЗЬ / ЖУРНАЛ"
 compact_name.modulate = accent if active else Color.WHITE
 compact_body.add_theme_color_override("font_color",UI.TEXT if active else UI.MUTED)
 var preview := str(message.get("body","")) if active else "Канал свободен"
 while UI.FONT.get_multiline_string_size(preview,HORIZONTAL_ALIGNMENT_LEFT,268,13).y > 34:
  var split := preview.rfind(" ")
  if split < 1:
   preview = preview.left(maxi(1,preview.length()-2))+"…";continue
  preview = preview.left(split).rstrip("…")+"…"
 compact_body.text = preview
func _sync() -> void:
 if not is_instance_valid(dispatcher): return
 if active and dispatcher.current.is_empty():
  ending = true;swapping = false;pending_message = {}
 active = not dispatcher.current.is_empty()
 if not active: manual_open = false
 _update_compact();_visibility()
func set_combat_mode(value: bool) -> void:
 if combat_mode == value: return
 combat_mode = value;_visibility()
func wants_expanded() -> bool: return active and not collapsed and (not combat_mode or manual_open)
func obscures_diagnostics() -> bool: return face_fade > .10
func _visibility() -> void:
 if not is_instance_valid(face): return
 var expanded := wants_expanded()
 face.visible = expanded or face_fade > .01
 face.modulate.a = face_fade*content_fade
 idle_button.visible = not expanded and face_fade <= .05
 compact_name.self_modulate.a = content_fade;compact_body.modulate.a = content_fade
 for button: Button in [next_button,history_button,collapse_button]: button.disabled = face_fade < .80
 face.queue_redraw()
func _layout() -> void:
 if not is_instance_valid(body): return
 face.size = size
 callsign.position = Vector2(111,27);callsign.size = Vector2(size.x-222,30)
 role.position = Vector2(111,56);role.size = Vector2(size.x-122,16)
 body.position = Vector2(111,78);body.size = Vector2(size.x-125,82)
 history_button.position = Vector2(size.x-104,7);history_button.size = Vector2(46,42)
 collapse_button.position = Vector2(size.x-52,7);collapse_button.size = Vector2(42,42)
 next_button.position = Vector2(52,size.y-50);next_button.size = Vector2(44,42)
 idle_button.position = Vector2(size.x-300,0);idle_button.size = Vector2(300,76)
 compact_name.position = Vector2(15,9);compact_name.size = Vector2(268,18)
 compact_body.position = Vector2(15,30);compact_body.size = Vector2(268,36)
func _process(delta: float) -> void:
 if is_instance_valid(dispatcher) and dispatcher.paused: return
 var reduced := bool(SettingsManager.get_value("video/reduced_motion"))
 if ending:
  content_fade = 0 if reduced else move_toward(content_fade,0,delta/.16)
  if content_fade <= .001: ending = false;_update_compact()
 elif swapping:
  content_fade = 0 if reduced else move_toward(content_fade,0,delta/ .16)
  if content_fade <= .001:
   _apply_message(pending_message);pending_message = {};swapping = false
 else: content_fade = 1 if reduced else move_toward(content_fade,1,delta/.24)
 var target := 1.0 if wants_expanded() else 0.0
 face_fade = target if reduced else move_toward(face_fade,target,delta/.28)
 face.position.y = 0 if reduced else (1-face_fade)*6
 if active and not reduced: clock += delta
 _visibility()
func draw_transmission(canvas: Control) -> void:
 if message.is_empty(): return
 var w := size.x;var h := size.y
 var p := PackedVector2Array([Vector2.ZERO,Vector2(w-10,0),Vector2(w,10),Vector2(w,h),Vector2(10,h),Vector2(0,h-10)])
 canvas.draw_colored_polygon(p,Color(.026,.045,.058,.94));var edge := p;edge.append(p[0]);canvas.draw_polyline(edge,Color(.34,.48,.51,.7),1,true)
 canvas.draw_line(Vector2(0,1),Vector2(89,1),accent,2)
 canvas.draw_string(UI.MONO,Vector2(14,18),"ОПЛОТ / RX 01",HORIZONTAL_ALIGNMENT_LEFT,-1,10,Color("8ea7aa"))
 var rect := Rect2(12,32,84,104)
 if portraits != null and person != "unknown":
  var cell := Vector2(portraits.get_size())*.5
  canvas.draw_texture_rect_region(portraits,rect,Rect2(Vector2(PEOPLE[person].cell)*cell+Vector2(cell.x*.1,0),Vector2(cell.x*.8,cell.y)))
 else:
  canvas.draw_rect(rect,Color("15242c"))
  for i in range(15): canvas.draw_line(rect.position+Vector2(0,i*7),rect.position+Vector2(rect.size.x,i*7),Color(.5,.65,.65,.06),1)
  canvas.draw_arc(rect.get_center(),22,0,TAU,28,accent,1,true)
 canvas.draw_rect(rect,Color(.60,.74,.74,.35),false,1)
 for i in range(4): canvas.draw_rect(Rect2(13+i*6,143,3,3+i*2),Color(accent,.9 if person != "unknown" or i == 0 else .18))
 canvas.draw_string(UI.MONO,Vector2(43,154),"ПРИЁМ",HORIZONTAL_ALIGNMENT_LEFT,-1,9,accent)
 var amount: float = dispatcher.fraction() if is_instance_valid(dispatcher) else 0.0
 canvas.draw_line(Vector2(198,h-20),Vector2(w-18,h-20),Color(.3,.44,.47,.35),2)
 canvas.draw_line(Vector2(198,h-20),Vector2(198+(w-216)*(1-amount),h-20),accent,2)
 for i in range(14):
  var pulse := .25+absf(sin(clock*1.6+i*.77)*sin(i*2.31+clock*.8))*.75
  var height := 2+pulse*5
  canvas.draw_line(Vector2(111+i*3.8,h-20-height*.5),Vector2(111+i*3.8,h-20+height*.5),Color(accent,.32),1.2)
 if not message.is_empty() and int(message.pages)>1:
  canvas.draw_string(UI.MONO,Vector2(w-54,h-33),"%d/%d"%[int(message.page),int(message.pages)],HORIZONTAL_ALIGNMENT_RIGHT,32,10,UI.MUTED)
func _advance() -> void:
 if is_instance_valid(dispatcher): dispatcher.advance()
func _collapse() -> void: collapsed = true;manual_open = false;_visibility()
func hit_rect() -> Rect2:
 return Rect2(Vector2.ZERO,size) if wants_expanded() or face_fade > .10 else idle_button.get_rect()
static func who(speaker: String) -> String:
 var text := speaker.to_upper()
 if "КЕДР" in text or "ДАНИИЛ" in text: return "kedr"
 if "ВЕТРОВА" in text: return "vetrova"
 if "ТАЯ" in text: return "taya"
 if "ЭХО" in text or "НИКА" in text: return "echo"
 return "unknown"

func _load_portraits() -> void:
 var path := "res://assets/ui/radio_personnel.png"
 if FileAccess.file_exists(path):
  var image := Image.new()
  if image.load_png_from_buffer(FileAccess.get_file_as_bytes(path)) == OK: image.generate_mipmaps();portraits = ImageTexture.create_from_image(image)
 elif ResourceLoader.exists(path): portraits = load(path)
