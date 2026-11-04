extends "res://scripts/ui/ui_button.gd"
## Owned touch input also works as the third finger while both hand sticks are held.
var touch_index := -1
func _ready() -> void:
 super._ready();toggle_mode = true;mouse_filter = Control.MOUSE_FILTER_IGNORE
func _activate() -> void:
 set_pressed_no_signal(not button_pressed);pressed.emit();queue_redraw()
func _input(event: InputEvent) -> void:
 if event is InputEventScreenTouch and not event.pressed and event.index == touch_index:
  touch_index = -1;get_viewport().set_input_as_handled();return
 if disabled or not is_visible_in_tree(): return
 if event is InputEventScreenTouch and event.pressed and touch_index < 0:
  if get_global_rect().has_point(event.position):
   touch_index = event.index;_activate();get_viewport().set_input_as_handled()
 elif event is InputEventMouseButton and event.device != InputEvent.DEVICE_ID_EMULATION and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
  if get_global_rect().has_point(event.position): _activate();grab_focus();get_viewport().set_input_as_handled()
 elif event is InputEventKey and event.pressed and not event.echo and has_focus() and event.keycode in [KEY_ENTER,KEY_SPACE]:
  _activate();get_viewport().set_input_as_handled()
func _notification(what: int) -> void:
 if what in [NOTIFICATION_APPLICATION_FOCUS_OUT,NOTIFICATION_APPLICATION_PAUSED]: touch_index = -1
