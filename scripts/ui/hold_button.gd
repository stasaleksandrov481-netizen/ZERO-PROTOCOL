extends "res://scripts/ui/ui_button.gd"
signal hold_changed(held: bool)
var touch_index := -1
var held := false
func _ready() -> void:
 super._ready()
 button_down.connect(func() -> void: if touch_index < 0: _hold(true))
 button_up.connect(func() -> void: if touch_index < 0: _hold(false))
func _input(event: InputEvent) -> void:
 if disabled or not is_visible_in_tree():
  if held: release()
  return
 if event is InputEventScreenTouch:
  var point: Vector2 = get_global_transform_with_canvas().affine_inverse()*event.position
  if event.pressed and touch_index < 0 and Rect2(Vector2.ZERO,size).has_point(point):
   touch_index = event.index;_hold(true);get_viewport().set_input_as_handled()
  elif not event.pressed and event.index == touch_index:
   release();get_viewport().set_input_as_handled()
 elif event is InputEventScreenDrag and event.index == touch_index:
  var point: Vector2 = get_global_transform_with_canvas().affine_inverse()*event.position
  if not Rect2(Vector2.ZERO,size).grow(32).has_point(point): release()
  get_viewport().set_input_as_handled()
func _hold(value: bool) -> void:
 if held == value: return
 held = value;set_pressed_no_signal(value);hold_changed.emit(value);queue_redraw()
func release() -> void: touch_index = -1;_hold(false)
func _notification(what: int) -> void:
 if what == NOTIFICATION_APPLICATION_FOCUS_OUT: release()
