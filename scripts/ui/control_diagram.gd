extends Control
## Non-combat instruction graphic; the circles are explanatory, not working joysticks.

func _ready() -> void:
	custom_minimum_size = Vector2(0,156)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	SettingsManager.changed.connect(func(key: StringName, _value: Variant) -> void:
		if key == &"input/scheme": queue_redraw())

func _draw() -> void:
	var font := RiftUI.FONT
	var x1 := size.x*.16
	var x2 := size.x*.84
	for x in [x1,x2]:
		draw_arc(Vector2(x,61),31,0,TAU,40,RiftUI.LINE,2,true)
		draw_circle(Vector2(x,61),10,Color("485c72"))
		draw_line(Vector2(x,61),Vector2(x+14,49),RiftUI.CYAN,2,true)
	var middle := Vector2(size.x*.5,61)
	draw_line(middle-Vector2(50,0),middle+Vector2(50,0),RiftUI.RED,2,true)
	for sign_value: float in [-1,1]:
		var tip := middle+Vector2(50*sign_value,0)
		draw_line(tip,tip+Vector2(-8*sign_value,-7),RiftUI.RED,2,true)
		draw_line(tip,tip+Vector2(-8*sign_value,7),RiftUI.RED,2,true)
	var scheme := int(SettingsManager.get_value("input/scheme"))
	_centered(font,tr("LEFT_HAND"),Vector2(x1,116),15,RiftUI.TEXT)
	_centered(font,tr("RIGHT_HAND"),Vector2(x2,116),15,RiftUI.TEXT)
	_centered(font,tr("DOUBLE_TAP") if scheme == 0 else tr("TILT_PHONE"),Vector2(size.x*.5,116),15,RiftUI.CYAN)
	_centered(font,tr("ILLUSTRATION_ONLY"),Vector2(size.x*.5,145),12,RiftUI.MUTED)

func _centered(font: Font, text: String, center: Vector2, font_size: int, color: Color) -> void:
	var width := font.get_string_size(text,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size).x
	draw_string(font,center-Vector2(width*.5,0),text,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size,color)
