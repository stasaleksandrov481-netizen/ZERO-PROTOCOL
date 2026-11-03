extends Node
## Keyboard, synthetic mobile touch, platform Back notification and real confirmed exit.

var failures := PackedStringArray()
var app: Control

func _ready() -> void: call_deferred("_run")

func _run() -> void:
	SettingsManager.reset_defaults()
	SettingsManager.set_value("video/reduced_motion",true)
	app = preload("res://scenes/menu/main_menu.tscn").instantiate()
	add_child(app)
	await _settle()
	NavigationManager.current_screen.buttons.get_node("Campaign").grab_focus()
	await _key(KEY_ENTER)
	_check(NavigationManager.current_route == &"campaign","Enter activates focused menu button")
	await _key(KEY_ESCAPE)
	_check(NavigationManager.current_route == &"home","Escape returns from section")
	var target: Control = NavigationManager.current_screen.buttons.get_node("Settings")
	var point := get_viewport().get_final_transform() * target.get_global_rect().get_center()
	for pressed in [true,false]:
		var touch := InputEventScreenTouch.new()
		touch.index = 0
		touch.position = point
		touch.pressed = pressed
		Input.parse_input_event(touch)
		await _settle()
	_check(NavigationManager.current_route == &"settings","Synthetic touch activates Settings")
	app.notification(NOTIFICATION_WM_GO_BACK_REQUEST)
	await _settle()
	_check(NavigationManager.current_route == &"home","Android Back notification returns home")
	app.notification(NOTIFICATION_WM_GO_BACK_REQUEST)
	await _settle()
	_check(is_instance_valid(NavigationManager.active_modal),"Android Back at home opens exit confirmation")
	await _key(KEY_ESCAPE)
	_check(not is_instance_valid(NavigationManager.active_modal),"Escape dismisses top modal")
	SettingsManager.reset_defaults()
	var result := {"passed":6-failures.size(),"failures":failures,"hardware_touch_tested":false}
	print("INPUT_RESULT ",JSON.stringify(result))
	if not failures.is_empty():
		AudioManager.shutdown()
		await get_tree().create_timer(.12).timeout
		get_tree().quit(1)
		return
	NavigationManager.quit_requested.connect(func() -> void:
		var cfg := ConfigFile.new()
		var valid := cfg.load(SaveService.SETTINGS_PATH) == OK
		print("CONFIRMED_EXIT_SAVED ",valid))
	NavigationManager.confirm_exit()
	await _settle()
	NavigationManager.active_modal.dismiss(true)

func _key(code: Key) -> void:
	for pressed in [true,false]:
		var event := InputEventKey.new()
		event.keycode = code
		event.physical_keycode = code
		event.pressed = pressed
		Input.parse_input_event(event)
		await _settle()

func _settle() -> void:
	for i in range(4): await get_tree().process_frame

func _check(value: bool, message: String) -> void:
	print("PASS " if value else "FAIL ",message)
	if not value: failures.append(message)
