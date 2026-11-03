extends Node
var app: Control
var failures := PackedStringArray()
var directory := ""

func _ready() -> void: call_deferred("_run")
func _run() -> void:
	directory = OS.get_environment("RIFT_CAPTURE_DIR")
	if directory != "": DirAccess.make_dir_recursive_absolute(directory)
	SettingsManager.reset_defaults()
	SettingsManager.set_value("video/reduced_motion",true)
	app = preload("res://scenes/menu/main_menu.tscn").instantiate()
	add_child(app)
	await settle()
	NavigationManager.go(&"test")
	await settle()
	for scale_value in [0.9,1.0,1.1,1.25]:
		SettingsManager.set_value("ui/scale",scale_value)
		await settle()
		var screen := NavigationManager.current_screen
		for name: String in ["LeftStick","RightStick","Top/Back","Top/Pause","Top/Reset","Top/Impulse","Top/Balance"]:
			var control: Control = screen.get_node("HUD/"+name)
			if not get_viewport().get_visible_rect().grow(2).encloses(control.get_global_rect()): failures.append(name+" outside screen at "+str(scale_value))
		if screen.get_node("HUD/Top").size.x > screen.size.x-46: failures.append("Top bar overflow")
		if directory != "" and scale_value in [1.0,1.25] and DisplayServer.get_name() != "headless":
			await RenderingServer.frame_post_draw
			get_viewport().get_texture().get_image().save_png(directory.path_join("range_ui_%d.png" % roundi(scale_value*100)))
	var result := {"window":str(get_window().size),"failures":failures,"scales":[.9,1.0,1.1,1.25]}
	print("RANGE_LAYOUT_RESULT ",JSON.stringify(result))
	if directory != "":
		var f := FileAccess.open(directory.path_join("range_layout.json"),FileAccess.WRITE)
		f.store_string(JSON.stringify(result,"  "))
	NavigationManager.back()
	await settle()
	SettingsManager.reset_defaults()
	AudioManager.shutdown()
	await get_tree().create_timer(.2).timeout
	app.queue_free()
	await settle()
	get_tree().quit(0 if failures.is_empty() else 1)

func settle() -> void:
	for i in range(6): await get_tree().process_frame
