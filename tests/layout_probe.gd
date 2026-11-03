extends Node
## Real resize/layout checks. Screenshot output is optional and never used as the UI itself.

var failures := PackedStringArray()
var shots := ""
var app: Control

func _ready() -> void:
	call_deferred("_run")

func _run() -> void:
	shots = OS.get_environment("RIFT_CAPTURE_DIR")
	if shots != "": DirAccess.make_dir_recursive_absolute(shots)
	SettingsManager.reset_defaults()
	SettingsManager.set_value("video/reduced_motion",true)
	app = preload("res://scenes/menu/main_menu.tscn").instantiate()
	add_child(app)
	await _settle()
	for scale_value in [0.9,1.0,1.1,1.25]:
		SettingsManager.set_value("ui/scale",scale_value)
		await _settle()
		var home := NavigationManager.current_screen
		for button: Control in home.buttons.get_children(): _inside(button, "Home "+button.name)
		_inside(home.get_node("Margin/Layout/Left/Logo"),"Logo")
		_inside(home.get_node("Margin/Layout/Left/Version"),"Version")
		_inside(home.get_node("Margin/Layout/Right/Top/About"),"About")
		_inside(home.get_node("Margin/Layout/Right/Status"),"Foundation status")
		if scale_value == 1.0: await _shot("main_menu")
		NavigationManager.go(&"settings")
		await _settle()
		var settings := NavigationManager.current_screen
		for index in range(4):
			settings._select_tab(index)
			await _settle()
			for button: Control in settings.tabs.get_children(): _inside(button,"Tab "+button.name)
			_inside(settings.get_node("Margin/Column/Header/Back"),"Settings Back")
			_inside(settings.get_node("Margin/Column/Footer/Reset"),"Settings Reset")
			var scroll: ScrollContainer = settings.get_node("Margin/Column/Scroll")
			if settings.tab_host.size.x > scroll.size.x+1: failures.append("Horizontal overflow in tab %d at %.2f" % [index,scale_value])
			if scale_value == 1.0 and index in [0,2]: await _shot("settings_"+str(index))
			# Long control pages must remain scrollable down to calibration.
			if index == 2:
				scroll.scroll_vertical = 10000
				await _settle()
				var controls: Control = settings.tab_host.get_child(0)
				var rect: Rect2 = controls.calibrate_button.get_global_rect()
				if not scroll.get_global_rect().encloses(rect): failures.append("Calibration is not reachable by scrolling")
				if scale_value == 1.0: await _shot("calibration")
		NavigationManager.back()
		await _settle()
	SettingsManager.set_value("ui/scale",1.0)
	NavigationManager.go(&"campaign")
	await _settle()
	_inside(NavigationManager.current_screen.get_node("Margin/Column/BackMenu"),"Section Back")
	await _shot("campaign")
	NavigationManager.back()
	await _settle()
	NavigationManager.confirm_exit()
	await _settle()
	_inside(NavigationManager.active_modal.get_node("Center/Panel"),"Exit modal")
	await _shot("exit_dialog")
	NavigationManager.back()
	var result := {"viewport":str(get_viewport().get_visible_rect().size),"window":str(get_window().size),"scales":[.9,1.0,1.1,1.25],"failures":failures}
	print("LAYOUT_RESULT ",JSON.stringify(result))
	if shots != "":
		var f := FileAccess.open(shots.path_join("layout_result.json"),FileAccess.WRITE)
		f.store_string(JSON.stringify(result,"  "))
	SettingsManager.reset_defaults()
	AudioManager.shutdown()
	await get_tree().create_timer(.12).timeout
	app.queue_free()
	await _settle()
	get_tree().quit(0 if failures.is_empty() else 1)

func _inside(control: Control, message: String) -> void:
	var bounds := get_viewport().get_visible_rect().grow(1)
	if not bounds.encloses(control.get_global_rect()):
		failures.append(message+" out of viewport: "+str(control.get_global_rect()))

func _settle() -> void:
	for i in range(5): await get_tree().process_frame

func _shot(name: String) -> void:
	if shots == "" or DisplayServer.get_name() == "headless": return
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(shots.path_join(name+".png"))
