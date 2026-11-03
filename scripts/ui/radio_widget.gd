extends Control
const UI = preload("res://scripts/ui/rift_ui.gd")
signal history_requested
var dispatcher: RefCounted
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
 mouse_filter = Control.MOUSE_FILTER_IGNORE
 callsign = UI.heading("ЭХО",22);add_child(callsign)
 role = UI.label("",10,UI.MUTED);role.add_theme_font_override("font",UI.MONO);add_child(role)
 body = UI.paragraph("",17,UI.TEXT);body.size_flags_horizontal = Control.SIZE_FILL;add_child(body)
 next_button = UI.icon_button("next",_advance,"Следующая реплика");add_child(next_button)
 history_button = UI.icon_button("history",func() -> void: history_requested.emit(),"Журнал связи");add_child(history_button)
 collapse_button = UI.button("−",_collapse);collapse_button.quiet = true;collapse_button.tooltip_text = "Свернуть канал";add_child(collapse_button)
 idle_button = UI.button("СВЯЗЬ / ЖУРНАЛ",func() -> void:
  if active: collapsed = false;_visibility()
  else: history_requested.emit())
 idle_button.quiet = true;idle_button.add_theme_font_size_override("font_size",12);add_child(idle_button)
 resized.connect(_layout);_layout();_visibility()
func bind(value: RefCounted) -> void:
 dispatcher = value;dispatcher.message_started.connect(_message);dispatcher.message_finished.connect(func(_id: String) -> void: _sync());dispatcher.state_changed.connect(_sync)
 _sync()
func _message(value: Dictionary) -> void:
 if portraits == null: _load_portraits()
 message = value;person = who(str(value.speaker));var data: Dictionary = PEOPLE[person]
 accent = data.color;callsign.text = data.name;role.text = data.role;body.text = str(value.body)
 active = true;collapsed = false;_layout();_visibility()
func _sync() -> void:
 if not is_instance_valid(dispatcher): return
 active = not dispatcher.current.is_empty();_visibility();queue_redraw()
func _visibility() -> void:
 var expanded := active and not collapsed
 for node: Control in [callsign,role,body,next_button,history_button,collapse_button]:
  if is_instance_valid(node): node.visible = expanded
 if is_instance_valid(idle_button): idle_button.visible = not expanded
 queue_redraw()
func _layout() -> void:
 if not is_instance_valid(body): return
 callsign.position = Vector2(111,27);callsign.size = Vector2(size.x-222,30)
 role.position = Vector2(111,56);role.size = Vector2(size.x-122,16)
 body.position = Vector2(111,78);body.size = Vector2(size.x-125,82)
 history_button.position = Vector2(size.x-104,7);history_button.size = Vector2(46,42)
 collapse_button.position = Vector2(size.x-52,7);collapse_button.size = Vector2(42,42)
 next_button.position = Vector2(52,size.y-50);next_button.size = Vector2(44,42)
 idle_button.position = Vector2(size.x-186,0);idle_button.size = Vector2(186,44)
func _process(delta: float) -> void:
 if active and not bool(SettingsManager.get_value("video/reduced_motion")):
  clock += delta;queue_redraw()
func _draw() -> void:
 if not active or collapsed: return
 var w := size.x;var h := size.y
 var p := PackedVector2Array([Vector2.ZERO,Vector2(w-10,0),Vector2(w,10),Vector2(w,h),Vector2(10,h),Vector2(0,h-10)])
 draw_colored_polygon(p,Color(.026,.045,.058,.94));var edge := p;edge.append(p[0]);draw_polyline(edge,Color(.34,.48,.51,.7),1,true)
 draw_line(Vector2(0,1),Vector2(89,1),accent,2)
 draw_string(UI.MONO,Vector2(14,18),"ОПЛОТ / RX 01",HORIZONTAL_ALIGNMENT_LEFT,-1,10,Color("8ea7aa"))
 var rect := Rect2(12,32,84,104)
 if portraits != null and person != "unknown":
  var cell := Vector2(portraits.get_size())*.5
  draw_texture_rect_region(portraits,rect,Rect2(Vector2(PEOPLE[person].cell)*cell+Vector2(cell.x*.1,0),Vector2(cell.x*.8,cell.y)))
 else:
  draw_rect(rect,Color("15242c"))
  for i in range(15): draw_line(rect.position+Vector2(0,i*7),rect.position+Vector2(rect.size.x,i*7),Color(.5,.65,.65,.06),1)
  draw_arc(rect.get_center(),22,0,TAU,28,accent,1,true)
 draw_rect(rect,Color(.60,.74,.74,.35),false,1)
 for i in range(4): draw_rect(Rect2(13+i*6,143,3,3+i*2),Color(accent,.9 if person != "unknown" or i == 0 else .18))
 draw_string(UI.MONO,Vector2(43,154),"ПРИЁМ",HORIZONTAL_ALIGNMENT_LEFT,-1,9,accent)
 var amount: float = dispatcher.fraction() if is_instance_valid(dispatcher) else 0.0
 draw_line(Vector2(198,h-20),Vector2(w-18,h-20),Color(.3,.44,.47,.35),2)
 draw_line(Vector2(198,h-20),Vector2(198+(w-216)*(1-amount),h-20),accent,2)
 for i in range(21):
  var pulse := .25+absf(sin(clock*3.6+i*.77)*sin(i*2.31+clock*.8))*.75
  var height := 3+pulse*11
  draw_line(Vector2(111+i*3.8,h-20-height*.5),Vector2(111+i*3.8,h-20+height*.5),Color(accent,.7),1.6)
 if not message.is_empty() and int(message.pages)>1:
  draw_string(UI.MONO,Vector2(w-91,20),"%d/%d"%[int(message.page),int(message.pages)],HORIZONTAL_ALIGNMENT_RIGHT,25,9,UI.MUTED)
func _advance() -> void:
 if is_instance_valid(dispatcher): dispatcher.advance()
func _collapse() -> void: collapsed = true;_visibility()
func hit_rect() -> Rect2:
 return Rect2(Vector2.ZERO,size) if active and not collapsed else idle_button.get_rect()
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
