extends Node
## Functional integration tests in the real Godot SceneTree. Use a disposable OS user data dir.

var passed := 0
var failures := PackedStringArray()
var app: Control

func _ready() -> void:
	call_deferred("_run")

func check(condition: bool, message: String) -> void:
	if condition:
		passed += 1
		print("PASS ",message)
	else:
		failures.append(message)
		printerr("FAIL ",message)

func settle(frames: int = 3) -> void:
	for i in range(frames): await get_tree().process_frame

func click(button: Control) -> void:
	var position := get_viewport().get_final_transform() * button.get_global_rect().get_center()
	var motion := InputEventMouseMotion.new()
	motion.position = position
	motion.global_position = position
	Input.parse_input_event(motion)
	await settle(1)
	var down := InputEventMouseButton.new()
	down.position = position
	down.global_position = position
	down.button_index = MOUSE_BUTTON_LEFT
	down.button_mask = MOUSE_BUTTON_MASK_LEFT
	down.pressed = true
	Input.parse_input_event(down)
	await settle(1)
	var up := InputEventMouseButton.new()
	up.position = position
	up.global_position = position
	up.button_index = MOUSE_BUTTON_LEFT
	up.pressed = false
	Input.parse_input_event(up)
	await settle()

func _run() -> void:
	check(Engine.get_version_info()["major"] == 4 and Engine.get_version_info()["minor"] == 7,"Godot 4.7 runtime")
	check(tr("SETTINGS") == "НАСТРОЙКИ","Russian Translation resource loaded")
	_compile_scripts("res://scripts")
	SettingsManager.reset_defaults()
	SettingsManager.set_value("video/reduced_motion",true)
	app = preload("res://scenes/menu/main_menu.tscn").instantiate()
	add_child(app)
	await settle(5)
	check(NavigationManager.current_route == &"home","App opens the home route")
	check(NavigationManager.host.get_child_count() == 1,"One active screen")
	# Pointer events exercise the actual hitboxes, rather than directly invoking callbacks.
	for pair in [["Campaign","campaign"],["Operations","operations"],["Hangar","hangar"],["Archive","archive"],["Settings","settings"]]:
		var home := NavigationManager.current_screen
		await click(home.get_node("Margin/Layout/Left/Menu/"+pair[0]))
		check(NavigationManager.current_route == StringName(pair[1]),"Pointer opens "+pair[1])
		await click(NavigationManager.current_screen.get_node("Margin/Column/Header/Back"))
		check(NavigationManager.current_route == &"home","Header returns from "+pair[1])
	await click(NavigationManager.current_screen.get_node("Margin/Layout/Left/Menu/Quit"))
	check(is_instance_valid(NavigationManager.active_modal),"Exit confirmation opens")
	NavigationManager.confirm_exit()
	check(NavigationManager.modal_host.get_child_count() == 1,"Repeated confirmation has one modal")
	await click(NavigationManager.active_modal.get_node("Center/Panel/Margin/Column/Actions/Cancel"))
	check(not is_instance_valid(NavigationManager.active_modal),"Exit cancellation dismisses modal")
	NavigationManager.go(&"settings")
	await settle()
	var settings := NavigationManager.current_screen
	var audio: SettingsTab = settings.tab_host.get_child(0)
	for key: String in SettingsManager.BUSES:
		var slider: HSlider = audio.bindings[key]["node"]
		slider.value = .31
		var bus := AudioServer.get_bus_index(SettingsManager.BUSES[key])
		check(is_equal_approx(db_to_linear(AudioServer.get_bus_volume_db(bus)),.31),"Audio bus applies "+key)
		slider.value = 0
		check(AudioServer.is_bus_mute(bus),"Zero safely mutes "+key)
		slider.value = .72
		check(not AudioServer.is_bus_mute(bus),"Volume restores "+key)
	for index in range(4):
		await click(settings.tabs.get_child(index))
		check(settings.active_tab == index and settings.tab_host.get_child_count() == 1,"Tab hitbox and lifetime "+str(index))
	settings._select_tab(1)
	await settle()
	var video: SettingsTab = settings.tab_host.get_child(0)
	var quality: OptionButton = video.bindings["video/quality"]["node"]
	quality.item_selected.emit(2)
	check(app.get_node("MenuBackground").quality == 2,"Quality controls environment")
	check(app.get_node("MenuBackground").rain_budget(2,false) == 80,"High preset has 80 rain streaks")
	check(app.get_node("MenuBackground").rain_budget(0,false) == 0,"Low preset has no moving rain")
	SettingsManager.set_value("video/reduced_motion",false)
	check(not app.get_node("MenuBackground").is_processing(),"Full-screen pages suspend the hidden menu animation")
	SettingsManager.set_value("video/reduced_motion",true)
	check(not app.get_node("MenuBackground").is_processing(),"Reduced motion stops background processing")
	for cap in [30,60,0]:
		SettingsManager.set_value("video/fps",cap)
		check(Engine.max_fps == cap,"FPS cap applied "+str(cap))
	SettingsManager.set_value("video/fps",60)
	settings._select_tab(2)
	await settle()
	var controls: SettingsTab = settings.tab_host.get_child(0)
	for scheme in [0,1]:
		SettingsManager.set_value("input/scheme",scheme)
		check(SettingsManager.input_config().scheme == scheme,"Scheme config "+str(scheme))
	check(not SettingsManager.input_config().sensor_available(),"No desktop accelerometer success is claimed")
	controls._calibrate()
	check(is_instance_valid(NavigationManager.active_modal),"Unavailable sensor explains calibration")
	NavigationManager.back()
	await settle()
	SettingsManager.set_value("input/tilt_sensitivity",2.25)
	SettingsManager.set_value("input/tilt_deadzone",.21)
	check(is_equal_approx(SettingsManager.input_config().tilt_sensitivity,2.25),"Sensitivity stored in input resource")
	check(is_equal_approx(SettingsManager.input_config().tilt_deadzone,.21),"Deadzone stored in input resource")
	SettingsManager.set_value("ui/scale",1.25)
	check(app.effective_scale > 1.0,"UI zoom applied without reload")
	SettingsManager.set_value("ui/high_contrast",true)
	check(app.get_node("ContrastShade").color.a > .3,"High contrast changes rendered overlay")
	check(SettingsManager.flush(),"ConfigFile write succeeds")
	SettingsManager.values = SettingsManager.DEFAULTS.duplicate(true)
	SettingsManager.reload_from_disk()
	check(is_equal_approx(float(SettingsManager.get_value("audio/master")),.72),"Audio survives disk reload")
	check(SettingsManager.get_value("input/scheme") == 1,"Scheme survives disk reload")
	check(SettingsManager.get_value("ui/scale") == 1.25,"Scale survives disk reload")
	SettingsManager.apply_all()
	# Clamp invalid types/ranges and refuse unsupported enumerated values.
	SettingsManager.set_value("audio/master",-5.0)
	check(SettingsManager.get_value("audio/master") == 0.0,"Negative volume clamps")
	SettingsManager.set_value("video/fps",144)
	check(SettingsManager.get_value("video/fps") == 60,"Unsupported FPS uses safe default")
	SettingsManager.set_value("ui/scale",99.0)
	check(SettingsManager.get_value("ui/scale") == 1.0,"Unsupported scale uses safe default")
	SettingsManager.set_value("input/tilt_deadzone","bad")
	check(SettingsManager.get_value("input/tilt_deadzone") == .12,"Wrong setting type recovers")
	SettingsManager.set_value("audio/master",NAN)
	check(SettingsManager.get_value("audio/master") == .8,"Nonfinite float recovers")
	NavigationManager.back()
	await settle()
	# Warm all script/resource caches before measuring live node counts.
	for route: StringName in [&"campaign",&"operations",&"hangar",&"archive",&"settings",&"home"]:
		NavigationManager.go(route)
		await settle()
	var baseline := int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT))
	var memory_before := int(Performance.get_monitor(Performance.MEMORY_STATIC))
	var memory_middle := memory_before
	for i in range(40):
		NavigationManager.go([&"campaign",&"operations",&"hangar",&"archive",&"settings"][i%5])
		await settle(2)
		NavigationManager.back()
		await settle(2)
		if i == 19: memory_middle = int(Performance.get_monitor(Performance.MEMORY_STATIC))
	check(NavigationManager.host.get_child_count() == 1,"40 round trips keep one screen")
	var final_nodes := int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT))
	check(final_nodes <= baseline+2,"Live node count stable: %d -> %d" % [baseline,final_nodes])
	var memory_after := int(Performance.get_monitor(Performance.MEMORY_STATIC))
	check(memory_after-memory_middle < 2097152,"No sustained static-memory growth over last 20 round trips")
	var config := RunConfig.new()
	check(config.validation_errors().size() == 3,"Missing battle content cannot form a launchable session")
	var catalog := load("res://resources/future_gameplay/catalog.tres") as ContentCatalog
	check(catalog.atlants.size() == 1 and catalog.atlants[0].starter_atlant and catalog.missions.size() == 1 and catalog.missions[0].id == &"M01" and catalog.missions[0].can_launch(),"Catalog has the real starter AT-01 and playable M01 route")
	SettingsManager.reset_defaults()
	check(SettingsManager.get_value("audio/master") == .8 and SettingsManager.get_value("input/scheme") == 0,"Reset restores defaults")
	check(SettingsManager.get_value("ui/scale") == 1.0 and SettingsManager.get_value("input/calibrated") == false,"Reset clears scale and calibration")
	var result := {"engine":Engine.get_version_info()["string"],"passed":passed,"failures":failures,"node_count_before":baseline,"node_count_after":final_nodes,"static_memory_before":memory_before,"static_memory_midpoint":memory_middle,"static_memory_after":memory_after}
	var file := FileAccess.open("user://test_results.json",FileAccess.WRITE)
	if file != null: file.store_string(JSON.stringify(result,"  "))
	print("RESULT ",JSON.stringify(result))
	AudioManager.shutdown()
	await get_tree().create_timer(.12).timeout
	NavigationManager.current_screen = null
	app.queue_free()
	await settle()
	get_tree().quit(0 if failures.is_empty() else 1)

func _compile_scripts(directory: String) -> void:
	for name in DirAccess.get_files_at(directory):
		if name.ends_with(".gd"):
			var script := load(directory.path_join(name)) as GDScript
			check(script != null and script.can_instantiate(),"Compile "+name)
	for name in DirAccess.get_directories_at(directory): _compile_scripts(directory.path_join(name))
