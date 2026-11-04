extends Control
## Optional live hints react to the player's real inputs and never block the mission.
const UI = preload("res://scripts/ui/rift_ui.gd")
var phase := 0
var hands := [false,false]
var origin_x := 0.0
var complete := false
var dismissed := false
var clock := 0.0
var caption: Label
var body: Label
var close_button: Button
signal finished
func _ready() -> void:
 mouse_filter = Control.MOUSE_FILTER_IGNORE
 caption = UI.section_title("ПРОВЕРЬТЕ ПРИВОДЫ");caption.add_theme_font_size_override("font_size",11);add_child(caption)
 body = UI.paragraph("",13,UI.TEXT);body.size_flags_horizontal = Control.SIZE_FILL;add_child(body)
 close_button = UI.button("×",dismiss);close_button.quiet = true;close_button.tooltip_text = "Скрыть подсказку";add_child(close_button)
 resized.connect(_layout);_layout();_refresh()
func _layout() -> void:
 if not is_instance_valid(body): return
 caption.position = Vector2(17,14);caption.size = Vector2(size.x-70,20)
 body.position = Vector2(17,40);body.size = Vector2(size.x-66,size.y-49)
 close_button.position = Vector2(size.x-48,6);close_button.size = Vector2(40,40)
 queue_redraw()
func observe(actor: Node2D,delta: float) -> void:
 if dismissed: return
 if phase == 0:
  for i in range(2):
   if actor.hand_engaged[i] and actor.hand_input[i].length() > .2: hands[i] = true
  if hands[0] and hands[1]: phase = 1;origin_x = actor.core.position.x
 elif phase == 1 and absf(actor.core.position.x-origin_x) > 100:
  phase = 2;complete = true;finished.emit()
 elif phase == 2:
  clock += delta
  if clock > 4: dismiss()
 _refresh()
func _refresh() -> void:
 if not is_instance_valid(body): return
 if phase == 0:
  caption.text = "01 / ПРОВЕРЬТЕ ОБЕ РУКИ"
  body.text = "%s Левая   %s Правая\nСдвиньте каждый стик. На ПК — ЛКМ / ПКМ."%["✓" if hands[0] else "○","✓" if hands[1] else "○"]
 elif phase == 1:
  caption.text = "02 / СДЕЛАЙТЕ ПЕРВЫЕ ШАГИ"
  body.text = "Стрелки внизу или A / D — ходьба.\nНа телефоне: двойной тап с удержанием сбоку."
 else:
  caption.text = "ПРОВЕРКА ЗАВЕРШЕНА"
  body.text = "Приводы отвечают. Держитесь огней справа.\nКедр и диспетчер остаются с вами."
 queue_redraw()
func dismiss() -> void: dismissed = true;hide()
func _draw() -> void:
 var points := PackedVector2Array([Vector2(0,0),Vector2(size.x-10,0),Vector2(size.x,10),size,Vector2(10,size.y),Vector2(0,size.y-10)])
 draw_colored_polygon(points,Color(.018,.043,.057,.93));points.append(points[0]);draw_polyline(points,Color(.44,.64,.71,.42),1,true)
 draw_line(Vector2(1,1),Vector2(53,1),UI.RED if not complete else UI.CYAN,2)
