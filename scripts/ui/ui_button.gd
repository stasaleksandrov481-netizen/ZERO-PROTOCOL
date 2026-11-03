extends Button
## Native input/focus with an angular, state-aware skin.
@export var primary := false
@export var quiet := false
func _ready() -> void:
 mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
 focus_mode = Control.FOCUS_ALL
 custom_minimum_size.y = maxf(46,custom_minimum_size.y)
 restyle()
 for id: String in ["mouse_entered","mouse_exited","focus_entered","focus_exited","button_down","button_up"]: connect(id,queue_redraw)
func restyle() -> void:
 for id: String in ["normal","hover","pressed","disabled","focus"]:
  var s := StyleBoxFlat.new();s.corner_detail = 1;s.set_corner_radius_all(7)
  s.content_margin_left = 18;s.content_margin_right = 18;s.content_margin_top = 9;s.content_margin_bottom = 9
  s.set_border_width_all(1)
  s.bg_color = Color("131e25") if not quiet else Color(.04,.07,.09,.38)
  s.border_color = Color("38474e")
  if primary: s.bg_color = Color("263442");s.border_color = Color("b59352")
  if id == "hover": s.bg_color = Color("243239");s.border_color = Color("b3c1c2")
  if id == "pressed": s.bg_color = Color("34505b");s.border_color = Color("f1cd83")
  if id == "disabled": s.bg_color = Color(.04,.07,.09,.45);s.border_color = Color("25333b")
  if id == "focus": s.bg_color = Color.TRANSPARENT;s.border_color = Color("bbc9c7");s.set_border_width_all(2)
  add_theme_stylebox_override(id,s)
 add_theme_color_override("font_color",Color("d8dfdc"))
 add_theme_color_override("font_hover_color",Color("f2f1e8"))
 add_theme_color_override("font_disabled_color",Color("697a80"))
func _draw() -> void:
 if disabled: return
 var active := is_hovered() or has_focus() or button_pressed
 var c := Color("d8b36b") if primary else Color("9faeae")
 c.a = .85 if active else .32
 draw_line(Vector2(11,size.y-3),Vector2(minf(size.x-11,48),size.y-3),c,2,true)
