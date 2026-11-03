extends Node
## Visual QA harness. Run this scene with -- --capture-dir=<absolute path>.

func _ready() -> void:
	call_deferred("_capture")

func _capture() -> void:
	var output := OS.get_environment("RIFT_CAPTURE_DIR")
	if output == "": output = "user://previews"
	DirAccess.make_dir_recursive_absolute(output)
	var app := preload("res://scenes/menu/main_menu.tscn").instantiate()
	add_child(app)
	await get_tree().create_timer(.7).timeout
	await _shot(output.path_join("main_menu.png"))
	NavigationManager.go(&"settings")
	await get_tree().create_timer(.45).timeout
	await _shot(output.path_join("settings_audio.png"))
	var screen := NavigationManager.current_screen
	for index in range(1,4):
		screen._select_tab(index)
		await get_tree().create_timer(.15).timeout
		await _shot(output.path_join("settings_%s.png" % ["audio","video","controls","interface"][index]))
	NavigationManager.back()
	await get_tree().create_timer(.4).timeout
	NavigationManager.confirm_exit()
	await get_tree().create_timer(.15).timeout
	await _shot(output.path_join("exit_dialog.png"))
	NavigationManager.back()
	await get_tree().process_frame
	AudioManager.shutdown()
	await get_tree().create_timer(.12).timeout
	NavigationManager.current_screen = null
	app.queue_free()
	await get_tree().process_frame
	get_tree().quit()

func _shot(path: String) -> void:
	await RenderingServer.frame_post_draw
	var image := get_viewport().get_texture().get_image()
	var error := image.save_png(path)
	print("CAPTURE ",path," ",error_string(error))
