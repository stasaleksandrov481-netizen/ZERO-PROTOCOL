extends Control
## Cinematic composition with a stable dialogue area and native keyboard/touch controls.
const UI = preload("res://scripts/ui/rift_ui.gd")
const Textures = preload("res://scripts/systems/texture_source.gd")
const Backdrop = preload("res://scripts/ui/prologue_backdrop.gd")
signal answer_selected(index: int)
signal continue_requested
signal skip_requested
signal previous_requested
var backdrop: Control
var body: Label
var scene_title: Label
var chapter: Label
var cue: Label
var speaker: Label
var role: Label
var face: TextureRect
var transmitted: Label
var reply_caption: Label
var selected_line: Label
var answer_buttons: Array[Button] = []
var continue_button: Button
var reveal_button: Button
var skip_button: Button
var back_button: Button
var instant_button: Button
var summary: HBoxContainer
var footer: Label
var panel: Control
var portraits: Texture2D
var entry: Dictionary = {}
var index := 0
var phase := "question"
var instant_text := false
var pulse := 0.0
var panel_tween: Tween
func _ready() -> void:
 theme = UI.design_theme()
 mouse_filter = Control.MOUSE_FILTER_STOP
 backdrop = Backdrop.new();add_child(backdrop);backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 back_button = UI.icon_button("back",func() -> void: previous_requested.emit(),"Предыдущая реплика");add_child(back_button)
 var wordmark := UI.micro("ENTERA / ОПЛОТ");wordmark.name = "Wordmark";add_child(wordmark)
 skip_button = UI.button("К СВОДКЕ ЗАДАНИЯ",func() -> void: skip_requested.emit());skip_button.quiet = true;skip_button.add_theme_font_size_override("font_size",11);add_child(skip_button)
 instant_button = UI.button("ТЕКСТ СРАЗУ",_toggle_instant);instant_button.quiet = true;instant_button.add_theme_font_size_override("font_size",11);add_child(instant_button)
 chapter = UI.micro("");chapter.add_theme_color_override("font_color",UI.RED);add_child(chapter)
 scene_title = UI.heading("",37);scene_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART;add_child(scene_title)
 cue = UI.micro("");add_child(cue)
 var route_note := UI.label("ВНЕШНЯЯ ОТМЕЛЬ\nДОК-17",12,Color("b0c9cf"));route_note.name = "RouteNote";route_note.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT;add_child(route_note)
 panel = Control.new();panel.mouse_filter = Control.MOUSE_FILTER_IGNORE;add_child(panel)
 var plate := UI.Surface.new();plate.opacity = .95;plate.accent = UI.CYAN;plate.mouse_filter = Control.MOUSE_FILTER_IGNORE;panel.add_child(plate);plate.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 face = TextureRect.new();face.expand_mode = TextureRect.EXPAND_IGNORE_SIZE;face.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED;panel.add_child(face)
 transmitted = UI.micro("● ВХОДЯЩИЙ / ШИФРОВАНИЕ АКТИВНО");transmitted.add_theme_font_size_override("font_size",10);panel.add_child(transmitted)
 speaker = UI.heading("",20);panel.add_child(speaker)
 role = UI.micro("");role.add_theme_font_size_override("font_size",10);panel.add_child(role)
 reply_caption = UI.micro("ВЫБЕРИТЕ ОТВЕТ");reply_caption.add_theme_color_override("font_color",UI.RED);panel.add_child(reply_caption)
 selected_line = UI.paragraph("",13,UI.CYAN);panel.add_child(selected_line)
 body = UI.paragraph("",20,UI.TEXT);body.size_flags_horizontal = Control.SIZE_FILL;panel.add_child(body)
 for i in range(2):
  var button := UI.button("",func() -> void: answer_selected.emit(i))
  button.name = "Answer%d"%i;button.alignment = HORIZONTAL_ALIGNMENT_LEFT;button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART;button.add_theme_font_size_override("font_size",15);panel.add_child(button);answer_buttons.append(button)
 continue_button = UI.primary("ПРОДОЛЖИТЬ",func() -> void: continue_requested.emit());continue_button.name = "Continue";continue_button.add_theme_font_size_override("font_size",14);panel.add_child(continue_button)
 reveal_button = UI.button("ПОКАЗАТЬ РЕПЛИКУ ЦЕЛИКОМ",reveal_text);reveal_button.quiet = true;reveal_button.add_theme_font_size_override("font_size",10);panel.add_child(reveal_button)
 summary = UI.row(16);panel.add_child(summary)
 for item: Array in [["01 / ВАША ЗАДАЧА","Открыть морской подход","Дойдите до огней ДОК-17 справа. После стыковки выберите соседнюю базу на карте."],["02 / ВАША ГРУППА","Первый + Кедр","Вы на АТ-01. Даниил — рядом, на АТ-02. Эхо ведёт группу по радиоканалу."],["03 / ПЕРВЫЕ ДЕЙСТВИЯ","Принять удар. Проверить руки.","Два стика — руки. Стрелки внизу или A / D — шаг. Остальное подскажут на берегу."]]:
  var col := UI.column(9);summary.add_child(col)
  col.add_child(UI.section_title(item[0]));col.add_child(UI.paragraph(item[1],20,UI.TEXT));col.add_child(UI.paragraph(item[2],14,UI.MUTED))
 footer = UI.micro("");footer.add_theme_font_size_override("font_size",10);add_child(footer)
 portraits = Textures.png("res://assets/ui/radio_personnel.png")
 var ambience := preload("res://scripts/systems/transport_ambience.gd").new();ambience.name = "ConvoyAmbience";add_child(ambience)
 resized.connect(_layout);_layout()
func present(value: Dictionary,scene_index: int,state: String,selected: int,pilot: String) -> void:
 entry = value;index = scene_index;phase = state;backdrop.shot = index
 var final := state == "summary"
 chapter.text = "ОПЕРАЦИЯ 01 / ПЕРЕД СБРОСОМ" if final else str(value.caption)
 scene_title.text = "ДО ВСТРЕЧИ НА БЕРЕГУ" if final else str(value.title)
 cue.text = "ПОГРАНИЧНЫЙ ПОЯС · 2089 · 22:45" if final else str(value.cue)
 speaker.text = str(value.speaker);role.text = str(value.role)
 transmitted.text = "● ОТВЕТ ПОЛУЧЕН / ГРУППОВОЙ КАНАЛ" if state == "reply" else "● ВХОДЯЩИЙ / ШИФРОВАНИЕ АКТИВНО"
 body.text = str(value.replies[clampi(selected,0,1)]) if state == "reply" else str(value.body).replace("{pilot}",pilot)
 body.visible_characters = -1 if instant_text or bool(SettingsManager.get_value("video/reduced_motion")) else 0
 reply_caption.text = "ПЕРВЫЙ / ВАША РЕПЛИКА" if state == "reply" else "ВЫБЕРИТЕ ОТВЕТ"
 selected_line.text = "ПИЛОТ: %s / ПЕРВЫЙ\nДопуск подписан. Группа ждёт вашей готовности."%pilot if final else "«%s»"%value.answers[clampi(selected,0,1)]
 for i in range(answer_buttons.size()): answer_buttons[i].text = "%02d   %s"%[i+1,value.answers[i]];answer_buttons[i].visible = state == "question"
 selected_line.visible = state in ["reply","summary"]
 continue_button.visible = state != "question"
 continue_button.text = "НАЧАТЬ ВЫСАДКУ  →" if final else ("ПРОВЕРИТЬ ГОТОВНОСТЬ  →" if index == 4 else "ПРОДОЛЖИТЬ  →")
 summary.visible = final;skip_button.visible = not final
 for node: Control in [face,transmitted,speaker,role,body,reply_caption]: node.visible = not final
 reveal_button.visible = not final
 footer.text = "ДОПУСК ПОДПИСАН   /   ОСНОВНЫЕ СВЕДЕНИЯ БУДУТ В ЖУРНАЛЕ" if final else "КАНАЛ %02d / 05   ·   ВЫБОР: 1 / 2   ·   ПРОБЕЛ: ПОКАЗАТЬ ТЕКСТ"%[index+1]
 if portraits != null:
  var cell := portraits.get_size()*.5;var who := int(value.portrait)
  var region := AtlasTexture.new();region.atlas = portraits;region.region = Rect2(Vector2(who%2,who/2)*cell+Vector2(cell.x*.15,0),Vector2(cell.x*.7,cell.y));region.filter_clip = true;face.texture = region
 _layout()
 call_deferred("_layout")
 if is_instance_valid(panel_tween): panel_tween.kill()
 if not bool(SettingsManager.get_value("video/reduced_motion")):
  panel.modulate.a = .35;panel_tween = create_tween();panel_tween.tween_property(panel,"modulate:a",1.0,.28).set_trans(Tween.TRANS_SINE)
 else: panel.modulate.a = 1
 if state == "reply" or final: continue_button.grab_focus()
func _layout() -> void:
 if not is_instance_valid(panel): return
 var compact := size.y < 620
 var m := 28.0 if compact else 36.0
 var w := size.x-2*m
 back_button.position = Vector2(m,18);back_button.size = Vector2(46,42)
 $Wordmark.position = Vector2(m+62,29);$Wordmark.size = Vector2(300,25)
 instant_button.position = Vector2(size.x-m-346,18);instant_button.size = Vector2(154,42)
 skip_button.position = Vector2(size.x-m-180,18);skip_button.size = Vector2(180,42)
 chapter.position = Vector2(m,85);chapter.size = Vector2(w*.60,22)
 scene_title.position = Vector2(m,112);scene_title.size = Vector2(w*.57,104);scene_title.add_theme_font_size_override("font_size",29 if compact else 37)
 var ph := 282.0 if compact else 320.0
 panel.position = Vector2(m,size.y-ph-43);panel.size = Vector2(w,ph)
 cue.position = Vector2(m,minf(198 if compact else 222,panel.position.y-25));cue.size = Vector2(520,20)
 $RouteNote.position = Vector2(size.x-m-220,minf(202 if compact else 275,panel.position.y-44));$RouteNote.size = Vector2(220,40)
 var inset := 18.0 if compact else 23.0
 var portrait := Vector2(69,88) if compact else Vector2(82,104)
 face.position = Vector2(inset,22);face.size = portrait
 var text_x := inset+portrait.x+18
 transmitted.position = Vector2(text_x,18);transmitted.size = Vector2(w-text_x-22,19)
 speaker.position = Vector2(text_x,40);speaker.size = Vector2(w-text_x-22,29);speaker.add_theme_font_size_override("font_size",19 if compact else 22)
 role.position = Vector2(text_x,72);role.size = Vector2(w-text_x-22,18)
 body.position = Vector2(text_x,98);body.size = Vector2(w-text_x-inset,90 if compact else 102);body.add_theme_font_size_override("font_size",18 if compact else 21)
 reply_caption.position = Vector2(inset,ph-112);reply_caption.size = Vector2(w-2*inset,20)
 selected_line.position = Vector2(inset,ph-84);selected_line.size = Vector2(w-285,62)
 for i in range(2):
  answer_buttons[i].position = Vector2(inset+i*((w-2*inset-12)*.5+12),ph-82)
  answer_buttons[i].size = Vector2((w-2*inset-12)*.5,60)
 continue_button.position = Vector2(w-270,ph-82);continue_button.size = Vector2(248,60)
 if phase == "summary": continue_button.position = Vector2(w-294,ph-82);continue_button.size.x = 272
 reveal_button.position = Vector2(w-290,ph-121);reveal_button.size = Vector2(268,30)
 summary.position = Vector2(inset,26);summary.size = Vector2(w-2*inset,ph-125)
 footer.position = Vector2(m,size.y-27);footer.size = Vector2(w,20)
 queue_redraw()
func _process(delta: float) -> void:
 if not bool(SettingsManager.get_value("video/reduced_motion")): pulse += minf(delta,.05)
 if is_instance_valid(body): reveal_button.visible = phase != "summary" and body.visible_characters >= 0 and body.visible_characters < body.get_total_character_count()
 queue_redraw()
func reveal_text() -> void: body.visible_characters = -1
func _toggle_instant() -> void:
 instant_text = not instant_text;instant_button.text = "ТЕКСТ: СРАЗУ" if instant_text else "ТЕКСТ С ЭФФЕКТОМ"
 if instant_text: reveal_text()
func _draw() -> void:
 if not is_instance_valid(panel): return
 var m := 28.0 if size.y < 620 else 36.0
 draw_line(Vector2(m,73),Vector2(size.x-m,73),Color(.48,.68,.76,.22),1)
 # Segment marks communicate progress without an unexplained packet counter.
 for i in range(5):
  var x := size.x-m-110+i*24
  draw_line(Vector2(x,size.y-26),Vector2(x+17,size.y-26),Color("d5b16d") if i <= index else Color("344b59"),2)
 if phase != "summary":
  var y := panel.position.y+panel.size.y-107
  for i in range(26):
   var height := 3+absf(sin(pulse*2.1+i*.7)*sin(i*1.3+pulse*.4))*10
   var x := panel.position.x+265+i*2.7
   draw_line(Vector2(x,y-height),Vector2(x,y),Color(.57,.78,.82,.48),1)
func _input(event: InputEvent) -> void:
 if NavigationManager.transitioning or not is_visible_in_tree(): return
 if not event is InputEventKey or not event.pressed or event.echo: return
 if event.keycode in [KEY_1,KEY_KP_1,KEY_2,KEY_KP_2] and phase == "question":
  answer_selected.emit(0 if event.keycode in [KEY_1,KEY_KP_1] else 1);get_viewport().set_input_as_handled()
 elif event.keycode == KEY_SPACE:
  if phase != "summary" and body.visible_characters >= 0 and body.visible_characters < body.get_total_character_count(): reveal_text()
  elif phase != "question": continue_requested.emit()
  get_viewport().set_input_as_handled()
