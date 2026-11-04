extends Control
## The campaign is committed only after a real freehand signature and the briefing.
const UI = preload("res://scripts/ui/rift_ui.gd")
const Textures = preload("res://scripts/systems/texture_source.gd")
var submitting := false
var step := 0
var first_name := ""
var family_name := ""
var strokes: Array = []
var choices: Dictionary = {}
var dialogue_index := 0
var clock := 0.0
var content: VBoxContainer
var title_label: Label
var subtitle: Label
var form_first: LineEdit
var form_family: LineEdit
var error_label: Label
var next_button: Button
var signature_pad: Control
var dialogue_text: Label
var type_clock := 0.0
var step_caption: Label
var portrait_atlas: Texture2D
const BRIEFING := [
 {"speaker":"ЭХО / НИКА ЛЕБЕДЕВА","role":"ДИСПЕТЧЕР СЕТИ · ЗАЩИЩЁННЫЙ КАНАЛ","body":"{pilot}, ваша регистрация подтверждена. Вы — пилот программы «Оплот» корпорации ЭНТЕРА. В эфире ваш позывной — Первый. Машина АТ-01 принята после подготовки; сегодня ваш первый выход за периметр.","answers":["Первый на связи. К заданию готов.","Что от меня потребуется?"],"replies":["Связь уверенная. Сейчас познакомлю с группой.","Держать машину, слушать эфир и вернуться с группой. Остальному научит дорога."]},
 {"speaker":"КЕДР / ДАНИИЛ КРАВЦОВ","role":"ПИЛОТ СОПРОВОЖДЕНИЯ · АТ-02","body":"Первый, я Даниил. Позывной Кедр. У меня своя машина, АТ-02, так что в твою кабину не набиваюсь. На выходе идём парой: ты ведёшь, я прикрываю. Если понадобится помощь — скажи по групповому каналу.","answers":["Принял, Кедр. Держимся вместе.","Ты уже выходил за периметр?"],"replies":["Так надёжнее. Увидимся у воды.","Выходил. Главное — не спеши за первым силуэтом и не теряй мой сигнал."]},
 {"speaker":"ВЕТРОВА / ЕЛЕНА ВЕТРОВА","role":"КОМАНДИР ПОГРАНИЧНОГО СЕКТОРА","body":"После инцидента на «Горизонте» мы удерживаем береговые базы. Искажённые активны ночью: днём контактов почти нет. Потому боевые выходы идут в тёмное время. Что им нужно — это пока не ваша задача. Сегодня вы помогаете людям на побережье.","answers":["Какова цель первого выхода?","Ночью у нас будет поддержка?"],"replies":["Откроем морской подход к ДОК-17. С него начнётся ваш маршрут по поясу.","Диспетчер и Кедр остаются с вами. Эвакуация зависит от погоды и свободного коридора."]},
 {"speaker":"ЭХО / НИКА ЛЕБЕДЕВА","role":"ВОЗДУШНЫЙ КОНВОЙ · ПОДХОД К БЕРЕГУ","body":"Транспортные вертолёты доставят ваши машины на внешнюю отмель. Отцепление — над мелководьем. Вода до коленных шарниров, дно под ногами плотное. После посадки проверьте руки и идите к огням берегового дока. Напарник приземлится рядом.","answers":["Понятно. Что после стыковки?","Почему не посадить нас прямо в док?"],"replies":["Получите доступ к сети баз. Следующую соседнюю базу выбираете сами — пути разные.","Причальный коридор закрыт обломками. Вертолёты не смогут зависнуть внутри периметра."]},
 {"speaker":"КЕДР / ДАНИИЛ КРАВЦОВ","role":"ГРУППОВОЙ КАНАЛ · ЗА 20 СЕКУНД ДО СБРОСА","body":"Вижу твой транспорт слева. После отцепления не дёргай приводы: дай машине принять удар. Два стика — твои руки. Двойной тап с удержанием по свободной стороне — шаг; можно включить наклон в настройках. На карте нет одной обязательной дороги. Но сейчас доберёмся до берега.","answers":["Первый. К высадке готов.","Принял. Веди меня по эфиру."],"replies":["Кедр готов. Замки — на отцепление.","Буду рядом. Главное — возвращайся на связь."]}
]
class SignaturePad extends Control:
 signal changed(valid: bool)
 var lines: Array[PackedVector2Array] = []
 var drawing := false
 var finger := -1
 var length_drawn := 0.0
 func _ready() -> void:
  mouse_filter = Control.MOUSE_FILTER_STOP;custom_minimum_size = Vector2(250,136);resized.connect(queue_redraw)
 func _start(point: Vector2) -> void:
  if lines.size() >= 32: return
  drawing = true;lines.append(PackedVector2Array([point/size]));queue_redraw()
 func _append(point: Vector2) -> void:
  if not drawing or lines.is_empty() or lines[-1].size() >= 1200: return
  var normalized := point.clamp(Vector2(8,8),size-Vector2(8,8))/size
  length_drawn += (normalized-lines[-1][-1]).length()*size.x
  lines[-1].append(normalized);changed.emit(length_drawn > 8);queue_redraw()
 func _gui_input(event: InputEvent) -> void:
  if event is InputEventScreenTouch:
   if event.pressed and finger < 0: finger = event.index;_start(event.position)
   elif not event.pressed and event.index == finger: drawing = false;finger = -1
   accept_event()
  elif event is InputEventScreenDrag and event.index == finger: _append(event.position);accept_event()
  elif event is InputEventMouseButton and event.device != InputEvent.DEVICE_ID_EMULATION and event.button_index == MOUSE_BUTTON_LEFT:
   if event.pressed: _start(event.position)
   else: drawing = false
   accept_event()
  elif event is InputEventMouseMotion and drawing and finger < 0: _append(event.position);accept_event()
 func _notification(what: int) -> void:
  if what in [NOTIFICATION_APPLICATION_FOCUS_OUT,NOTIFICATION_APPLICATION_PAUSED]: drawing = false;finger = -1
 func clear_signature() -> void:
  lines.clear();length_drawn = 0;drawing = false;finger = -1;changed.emit(false);queue_redraw()
 func _draw() -> void:
  draw_rect(Rect2(Vector2.ZERO,size),Color("07131b"));draw_rect(Rect2(Vector2.ZERO,size),Color("365361"),false,1)
  draw_line(Vector2(16,size.y-25),Vector2(size.x-16,size.y-25),Color(.55,.75,.82,.25),1)
  for line: PackedVector2Array in lines:
   if line.size() > 1:
    var points := PackedVector2Array()
    for point: Vector2 in line: points.append(point*size)
    draw_polyline(points,Color(.35,.77,1,.12),7,true);draw_polyline(points,Color("b2e1ee"),2,true)
  if lines.is_empty(): draw_string(UI.FONT,Vector2(18,size.y*.49),"Нарисуйте подпись пальцем",HORIZONTAL_ALIGNMENT_LEFT,-1,14,Color("66838e"))
 func export_signature() -> Array:
  var result: Array = []
  for line: PackedVector2Array in lines: result.append(Array(line))
  return result
func _ready() -> void:
 theme = UI.design_theme();_rebuild();resized.connect(queue_redraw)
func _process(delta: float) -> void:
 clock += delta
 if is_instance_valid(dialogue_text):
  type_clock += delta;dialogue_text.visible_characters = int(type_clock*52)
 queue_redraw()
func _draw() -> void:
 draw_rect(Rect2(Vector2.ZERO,size),Color("02070c"))
 for x in range(0,int(size.x),54): draw_line(Vector2(x,0),Vector2(x,size.y),Color(.20,.40,.52,.025),1)
 # A ghosted corporate mark and scan line sit behind the digital document.
 var centre := Vector2(size.x*.80,size.y*.41)
 draw_polyline(PackedVector2Array([centre+Vector2(-140,-88),centre+Vector2(140,-88),centre+Vector2(0,155),centre+Vector2(-140,-88)]),Color(.22,.44,.56,.04),2,true)
 var scan_y := 86+fposmod(clock*10,maxf(1,size.y-128))
 draw_line(Vector2(36,scan_y),Vector2(size.x-36,scan_y),Color(.20,.52,.66,.025),1)
 var glow := Vector2(size.x*.78,size.y*.32)
 for i in range(16,0,-1): draw_circle(glow,20+i*23,Color(.08,.24,.32,.002))
 draw_line(Vector2(34,83),Vector2(size.x-34,83),Color("253a46"),1)
 draw_line(Vector2(34,size.y-37),Vector2(size.x-34,size.y-37),Color("253a46"),1)
 draw_string(UI.MONO,Vector2(35,size.y-17),"ENTERA / SECURE ENROLLMENT   •   2089",HORIZONTAL_ALIGNMENT_LEFT,-1,10,Color("547684"))
func _rebuild() -> void:
 for node in get_children(): remove_child(node);node.queue_free()
 dialogue_text = null
 var margin := MarginContainer.new();add_child(margin);margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 for edge in ["left","right"]: margin.add_theme_constant_override("margin_"+edge,38)
 margin.add_theme_constant_override("margin_top",18);margin.add_theme_constant_override("margin_bottom",49)
 var outer := UI.column(18);margin.add_child(outer)
 var header := UI.row(18);outer.add_child(header)
 header.add_child(UI.icon_button("back",_back,"Назад"))
 var heading := UI.column(2);header.add_child(heading)
 heading.add_child(UI.heading("ОПЛОТ / ДОПУСК ПИЛОТА",22));step_caption = UI.micro(["01  ИДЕНТИФИКАЦИЯ","02  ЭЛЕКТРОННОЕ СОГЛАШЕНИЕ","03  ЗАЩИЩЁННЫЙ ИНСТРУКТАЖ"][step]);heading.add_child(step_caption)
 var emblem := UI.label("ЭНТЕРА",20,UI.CYAN);emblem.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT;header.add_child(emblem)
 var scroll := ScrollContainer.new();scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED;scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL;outer.add_child(scroll)
 content = UI.column(14);content.size_flags_vertical = Control.SIZE_EXPAND_FILL;scroll.add_child(content)
 if step == 0: _identity()
 elif step == 1: _contract()
 else: _briefing()
func _speaker_portrait(index: int) -> TextureRect:
 if portrait_atlas == null: portrait_atlas = Textures.png("res://assets/ui/radio_personnel.png")
 if portrait_atlas == null: return TextureRect.new()
 var region := AtlasTexture.new();region.atlas = portrait_atlas;var cell := Vector2(portrait_atlas.get_size())*.5
 region.region = Rect2(Vector2(index%2,index/2)*cell+Vector2(cell.x*.15,0),Vector2(cell.x*.7,cell.y))
 var portrait := TextureRect.new();portrait.texture = region;portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE;portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED;portrait.custom_minimum_size = Vector2(92,108);return portrait
func _identity() -> void:
 content.add_child(UI.spacer(14));content.add_child(UI.micro("ЛИЧНОЕ ДЕЛО / НОВЫЙ ОПЕРАТОР"));content.add_child(UI.heading("КАК К ВАМ ОБРАЩАТЬСЯ?",34))
 content.add_child(UI.paragraph("Имя останется в вашем деле. В оперативном эфире — позывной «Первый».",17))
 var row := UI.row(24);content.add_child(row)
 var form := UI.column(10);form.custom_minimum_size.x = 430;row.add_child(form)
 form.add_child(UI.section_title("ИМЯ"));form_first = LineEdit.new();form_first.name = "GivenName";form_first.placeholder_text = "Имя пилота";form_first.max_length = 26;form_first.text = first_name;form_first.custom_minimum_size.y = 52;form.add_child(form_first)
 form.add_child(UI.section_title("ФАМИЛИЯ"));form_family = LineEdit.new();form_family.name = "FamilyName";form_family.placeholder_text = "Фамилия пилота";form_family.max_length = 30;form_family.text = family_name;form_family.custom_minimum_size.y = 52;form.add_child(form_family)
 error_label = UI.paragraph("",14,UI.RED);form.add_child(error_label)
 next_button = UI.primary("ПЕРЕЙТИ К СОГЛАШЕНИЮ",_identity_next);form.add_child(next_button)
 var info := UI.column(12);info.add_child(UI.section_title("ПРОГРАММА «ОПЛОТ»"));info.add_child(UI.heading("Одна машина.\nОдин пилот.\nОдна группа.",27));info.add_child(UI.paragraph("Статус: кандидат допущен\nМашина: АТ-01 «Горизонт»\nГруппа: Первый / Кедр\nСектор: Пограничный пояс",16));row.add_child(UI.panel(info,23))
 form_family.text_submitted.connect(func(_text: String) -> void: _identity_next());form_first.text_submitted.connect(func(_text: String) -> void: form_family.grab_focus())
 form_first.grab_focus()
func _identity_next() -> void:
 first_name = form_first.text.strip_edges();family_name = form_family.text.strip_edges()
 if first_name.length() < 2 or family_name.length() < 2: error_label.text = "Введите имя и фамилию — не меньше двух букв.";return
 var check := RegEx.new();check.compile("^[\\p{L}][\\p{L} '-]+$")
 if check.search(first_name) == null or check.search(family_name) == null: error_label.text = "В имени и фамилии используйте буквы, пробел или дефис.";return
 step = 1;_rebuild()
func _contract() -> void:
 var compact := size.y < 620
 if compact: content.add_theme_constant_override("separation",9)
 content.add_child(UI.micro("ECP / 2089–17   •   ВЕРСИЯ 04   •   ПЕРСОНАЛЬНЫЙ ДОСТУП"));content.add_child(UI.heading("СОГЛАШЕНИЕ ПИЛОТА",30))
 content.add_child(UI.paragraph((first_name+" "+family_name).to_upper()+"   /   ПОЗЫВНОЙ «ПЕРВЫЙ»",16,UI.CYAN))
 var row := UI.row(24);content.add_child(row);row.size_flags_vertical = Control.SIZE_EXPAND_FILL
 var text_scroll := ScrollContainer.new();text_scroll.custom_minimum_size = Vector2(430,230);text_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL;text_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED;row.add_child(text_scroll)
 var text_col := UI.column(12);text_scroll.add_child(text_col)
 var articles := [
 ["01 / ДОБРОВОЛЬНОЕ УЧАСТИЕ","Я добровольно вступаю в программу «Оплот» и принимаю обязанности пилота Атланта. Мне разъяснены устройство машины, порядок выполнения приказов и право запросить прекращение службы на безопасной базе."],
 ["02 / ОСОБЫЙ ХАРАКТЕР РИСКА","Выход за защитный периметр связан с риском травмы, потери связи, необратимого повреждения машины и гибели. Ни броня, ни поддержка группы не гарантируют безопасное возвращение."],
 ["03 / ПРЕДЕЛЫ ОТВЕТСТВЕННОСТИ","ЭНТЕРА не гарантирует сохранность жизни и имущества пилота при боевом контакте, действиях Искажённых, чрезвычайных явлениях или нарушении пилотом инструкций. Последствия добровольного боевого выхода принимаются пилотом в пределах условий программы."],
 ["04 / ПОМОЩЬ И ЭВАКУАЦИЯ","Корпорация вправе направить спасательную группу, предоставить медицинскую помощь, ремонт и эвакуацию при наличии связи, ресурсов и безопасного коридора. Возможность такой помощи определяется обстановкой; её прибытие не гарантируется."],
 ["05 / ПОДТВЕРЖДЕНИЕ","Я ознакомился с условиями. Моя рукописная отметка в защищённом поле подтверждает согласие и связывается с моим личным делом. Этот документ действует внутри программы «Оплот»."]]
 for article: Array in articles: text_col.add_child(UI.section_title(article[0]));text_col.add_child(UI.paragraph(article[1],15,UI.TEXT))
 var sign := UI.column(6 if compact else 12);sign.custom_minimum_size.x = 300;sign.size_flags_horizontal = Control.SIZE_FILL;row.add_child(sign)
 sign.add_child(UI.section_title("ЛИЧНАЯ ЭЛЕКТРОННАЯ ПОДПИСЬ"));sign.add_child(UI.paragraph("Поставьте отметку пальцем." if compact else "Поставьте любую рисованную отметку. Печатное имя не заменяет подпись.",12 if compact else 15))
 signature_pad = SignaturePad.new();signature_pad.name = "SignaturePad";sign.add_child(signature_pad)
 if compact: signature_pad.custom_minimum_size.y = 94
 var status := UI.micro("ОЖИДАЕТСЯ РУКОПИСНАЯ ОТМЕТКА");sign.add_child(status)
 var clear_button := UI.button("ОЧИСТИТЬ ПОЛЕ",func() -> void: signature_pad.clear_signature());sign.add_child(clear_button)
 if compact: clear_button.custom_minimum_size.y = 44;clear_button.add_theme_font_size_override("font_size",14)
 next_button = UI.primary("ПОДПИСАТЬ И ПРОДОЛЖИТЬ",_sign_next);next_button.name = "AcceptContract";next_button.disabled = true;sign.add_child(next_button)
 if compact: next_button.custom_minimum_size.y = 44;next_button.add_theme_font_size_override("font_size",14)
 signature_pad.changed.connect(func(valid: bool) -> void: next_button.disabled = not valid;status.text = "ПОДПИСЬ ПРИНЯТА / ГОТОВО К ОТПРАВКЕ" if valid else "ОЖИДАЕТСЯ РУКОПИСНАЯ ОТМЕТКА")
func _sign_next() -> void:
 if signature_pad.length_drawn <= 8: return
 strokes = signature_pad.export_signature();step = 2;dialogue_index = 0;_rebuild()
func _briefing() -> void:
 var compact := size.y < 620
 if compact: content.add_theme_constant_override("separation",7)
 var entry: Dictionary = BRIEFING[dialogue_index]
 if not compact: content.add_child(UI.spacer(12));content.add_child(UI.micro("● ЗАЩИЩЁННЫЙ КАНАЛ   /   %02d:%02d   /   ПАКЕТ %d–5"%[22,40+dialogue_index,dialogue_index+1]))
 var speaker_row := UI.row(22);content.add_child(speaker_row)
 var face := _speaker_portrait(1 if dialogue_index in [1,4] else (2 if dialogue_index == 2 else 0));speaker_row.add_child(face)
 if compact: face.custom_minimum_size = Vector2(64,76)
 var speaker_info := UI.column(8);speaker_row.add_child(speaker_info)
 speaker_info.add_child(UI.micro("ПРЯМОЕ ПОДКЛЮЧЕНИЕ / RX SECURE"));speaker_info.add_child(UI.heading(str(entry.speaker),22 if compact else 27));speaker_info.add_child(UI.micro(entry.role));speaker_info.add_child(UI.label("▂ ▃ ▅ ▃ ▂ ▄ ▆ ▃ ▂     СВЯЗЬ УСТОЙЧИВАЯ",11,UI.CYAN));content.add_child(UI.rule())
 if dialogue_index > 0:
  var previous: Dictionary = BRIEFING[dialogue_index-1];var selected := int(choices.get(str(dialogue_index-1),0))
  content.add_child(UI.paragraph(previous.replies[selected],15,UI.CYAN))
 dialogue_text = UI.paragraph(str(entry.body).replace("{pilot}",first_name+" "+family_name),18 if compact else 22,UI.TEXT);dialogue_text.custom_minimum_size.y = 72 if compact else 116;content.add_child(dialogue_text);type_clock = 0;dialogue_text.visible_characters = 0
 content.add_child(UI.micro("ВАШ ОТВЕТ"))
 for i in range(entry.answers.size()):
  var b := UI.button("%02d   /   %s"%[i+1,entry.answers[i]],_answer.bind(i));b.alignment = HORIZONTAL_ALIGNMENT_LEFT;b.add_theme_font_size_override("font_size",14 if compact else 16);content.add_child(b)
  if compact: b.custom_minimum_size.y = 44
 error_label = UI.paragraph("",14,UI.RED);content.add_child(error_label);error_label.visible = false
func _answer(index: int) -> void:
 if submitting: return
 choices[str(dialogue_index)] = index
 if dialogue_index+1 < BRIEFING.size(): dialogue_index += 1;_rebuild();return
 submitting = true
 if not Expedition.new_campaign(first_name,family_name,strokes,choices): error_label.visible = true;error_label.text = Expedition.last_error;submitting = false;return
 NavigationManager.go(&"expedition")
func _back() -> void:
 if step == 2:
  if dialogue_index > 0: dialogue_index -= 1
  else: step = 1
  _rebuild()
 elif step == 1: step = 0;_rebuild()
 else: NavigationManager.go(&"campaign")
func handle_back() -> bool: _back();return true
func focus_initial() -> void:
 if step == 0 and is_instance_valid(form_first): form_first.grab_focus()
