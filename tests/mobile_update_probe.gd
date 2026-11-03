extends Node
## Intentionally uses no new global class names: run against a stale editor registry.
var app: Control
var failures := PackedStringArray()
var output := ""

func _ready() -> void: call_deferred("_run")

func _run() -> void:
	output = OS.get_environment("RIFT_CAPTURE_DIR")
	if output != "": DirAccess.make_dir_recursive_absolute(output)
	SettingsManager.reset_defaults()
	SettingsManager.set_value("video/reduced_motion",true)
	app = load("res://scenes/menu/main_menu.tscn").instantiate()
	add_child(app)
	await frames(8)
	NavigationManager.go(&"test")
	await frames(12)
	var screen: Control = NavigationManager.current_screen
	var ready := screen.has_method("is_range_ready") and bool(screen.call("is_range_ready"))
	check(ready,"range initialized without the new global class registry entries")
	if ready:
		check(screen.robot.parts.size() == 11,"all eleven physical parts loaded")
		check(screen.left_stick.size.x >= 150 and screen.right_stick.size.x >= 150,"both joysticks have real visible size")
		var top: Control = screen.get_node("HUD/Top")
		check(top.position.y >= 16 and top.size.x > screen.size.x*.8,"header is positioned and stretches")
		check(screen.get_node("HUD/Title").position.y >= top.position.y+top.size.y,"title does not overlap the header")
		await get_tree().create_timer(.6).timeout
		check(screen.robot.core.position.y > 5.5,"Atlas remains above the floor")
		check("м/с" in screen.get_node("HUD/Top/Status").text,"gameplay input loop is running")
		for node: Control in [screen.left_stick,screen.right_stick,screen.get_node("HUD/Top/Back"),screen.get_node("HUD/Top/Pause")]:
			check(get_viewport().get_visible_rect().grow(2).encloses(node.get_global_rect()),String(node.name)+" inside viewport")
	if output != "" and DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png(output.path_join("mobile_update_fixed.png"))
	var result := {"engine":Engine.get_version_info()["string"],"window":str(get_window().size),"ready":ready,"failures":failures}
	print("MOBILE_UPDATE_RESULT ",JSON.stringify(result))
	var path := "user://mobile_update_result.json" if output == "" else output.path_join("mobile_update_result.json")
	var file := FileAccess.open(path,FileAccess.WRITE)
	if file != null: file.store_string(JSON.stringify(result,"  "))
	if NavigationManager.current_route != &"home": NavigationManager.back()
	await frames(4)
	SettingsManager.reset_defaults()
	AudioManager.shutdown()
	await get_tree().create_timer(.15).timeout
	app.queue_free()
	await frames(3)
	get_tree().quit(0 if failures.is_empty() else 1)

func check(ok: bool, message: String) -> void:
	if not ok: failures.append(message)
	print("PASS " if ok else "FAIL ",message)

func frames(count: int) -> void:
	for i in range(count): await get_tree().process_frame
