extends Node

var app: Control
var screen: Control
var output := ""

func _ready() -> void: call_deferred("_run")

func _run() -> void:
	output = OS.get_environment("RIFT_CAPTURE_DIR")
	if output == "": output = "user://range_previews"
	DirAccess.make_dir_recursive_absolute(output)
	SettingsManager.reset_defaults()
	SettingsManager.set_value("video/reduced_motion",true)
	app = preload("res://scenes/menu/main_menu.tscn").instantiate()
	add_child(app)
	await get_tree().create_timer(.25).timeout
	await _shot("home")
	NavigationManager.go(&"test")
	await get_tree().create_timer(.2).timeout
	screen = NavigationManager.current_screen
	if screen.paused: screen._toggle_pause()
	for i in range(5):
		await get_tree().create_timer(.8).timeout
		print("RIG ",i," core=",screen.robot.core.position," v=",screen.robot.core.linear_velocity," load=",screen.robot.load_ratio)
	await _shot("range_idle")
	screen.left_stick.value = Vector2(1,-.25)
	screen.right_stick.value = Vector2(.7,-.7)
	await get_tree().create_timer(1.3).timeout
	await _shot("range_arms")
	screen.left_stick.release()
	screen.right_stick.release()
	Input.action_press("future_move_right")
	await get_tree().create_timer(2.0).timeout
	print("WALK core=",screen.robot.core.position," v=",screen.robot.core.linear_velocity)
	await _shot("range_walk")
	Input.action_release("future_move_right")
	NavigationManager.back()
	await get_tree().create_timer(.3).timeout
	NavigationManager.go(&"settings")
	await get_tree().create_timer(.3).timeout
	await _shot("settings_no_pilot")
	NavigationManager.back()
	await get_tree().create_timer(.15).timeout
	SettingsManager.reset_defaults()
	AudioManager.shutdown()
	await get_tree().create_timer(.2).timeout
	app.queue_free()
	await get_tree().process_frame
	get_tree().quit()

func _shot(name: String) -> void:
	if DisplayServer.get_name() == "headless": return
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(output.path_join(name+".png"))
