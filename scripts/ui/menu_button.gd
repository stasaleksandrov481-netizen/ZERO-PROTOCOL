extends Button
## Thin chamfer, corner marks and a real Godot focus/pressed state over a real hitbox.

func _ready() -> void:
	for state: String in ["hover", "pressed", "focus"]:
		var style := get_theme_stylebox(state).duplicate() as StyleBoxFlat
		style.bg_color = Color(0.25,0.045,0.065,0.75)
		style.content_margin_left = 26
		style.content_margin_right = 20
		style.content_margin_top = 8
		style.content_margin_bottom = 8
		add_theme_stylebox_override(state,style)
	for signal_name in ["mouse_entered", "mouse_exited", "focus_entered", "focus_exited", "button_down", "button_up"]:
		connect(signal_name, queue_redraw)
	queue_redraw()

func _draw() -> void:
	var active := has_focus() or is_hovered()
	var c := RiftUI.RED if active else Color("526070")
	c.a = 0.95 if active else 0.30
	var points := PackedVector2Array([Vector2(1,1),Vector2(size.x-1,1),Vector2(size.x-1,size.y-11),Vector2(size.x-11,size.y-1),Vector2(1,size.y-1),Vector2(1,1)])
	draw_polyline(points,c,1.0,true)
	if active:
		draw_line(Vector2(-4,9),Vector2(-4,size.y-9),c,2.0)
		draw_line(Vector2(4,-3),Vector2(32,-3),c,1.0)
