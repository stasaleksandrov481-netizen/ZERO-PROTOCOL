extends Node
## Integration checks of the actual articulated 3D rig and real pointer ownership.

var passed := 0
var failures := PackedStringArray()
var app: Control
var screen: Control
var robot: AtlantController
var steps := 0
var overloads := 0
var metrics: Dictionary = {}
var engine_errors

func _ready() -> void: call_deferred("_run")

func check(ok: bool, message: String) -> void:
	if ok: passed += 1
	else: failures.append(message)
	print("PASS " if ok else "FAIL ",message)

func ticks(count: int) -> void:
	for i in range(count): await get_tree().physics_frame

func frames(count: int = 3) -> void:
	for i in range(count): await get_tree().process_frame

func _run() -> void:
	engine_errors = NavigationManager.RangeErrors.new()
	OS.add_logger(engine_errors)
	SettingsManager.reset_defaults()
	SettingsManager.set_value("video/reduced_motion",true)
	app = preload("res://scenes/menu/main_menu.tscn").instantiate()
	add_child(app)
	await frames(5)
	check(app.get_node("MenuBackground/Pilot").visible,"Pilot appears in main menu")
	NavigationManager.go(&"settings")
	await frames()
	check(not app.get_node("MenuBackground/Pilot").visible,"Pilot hidden in settings")
	NavigationManager.back()
	await frames()
	check(app.get_node("MenuBackground/Pilot").visible,"Pilot returns with menu")
	var home := NavigationManager.current_screen
	home.get_node("Margin/Layout/Right/Test").pressed.emit()
	await frames(5)
	check(NavigationManager.current_route == &"test","Test button opens the range")
	screen = NavigationManager.current_screen
	robot = screen.robot
	if screen.paused: screen._toggle_pause()
	check(not app.get_node("MenuBackground").visible,"Menu backdrop is absent from empty range")
	check(robot.parts.size() == 11,"Rig has 11 real rigid bodies")
	check(robot.get_node("Joints").get_child_count() == 10,"Rig has 10 real hinge joints")
	var ground: StaticBody3D = screen.arena_view.get_node("Range/Floor")
	check(ground.get_node("Collision").shape.size.y == 3.0,"Floor collision is a solid 3m slab")
	check(screen.camera.projection == Camera3D.PROJECTION_ORTHOGONAL,"Camera is orthographic")
	check(screen.camera.rotation.is_equal_approx(Vector3.ZERO),"Camera looks exactly sideways without isometric tilt")
	var near_mesh: MeshInstance3D = robot.parts["RightForearm"].get_node("Visual/ArmorAndMechanisms")
	var far_mesh: MeshInstance3D = robot.parts["LeftForearm"].get_node("Visual/ArmorAndMechanisms")
	check(far_mesh.mesh.surface_get_material(0).albedo_color.r < near_mesh.mesh.surface_get_material(0).albedo_color.r,"Far left limbs use darker materials")
	robot.footstep.connect(func(_strength: float) -> void: steps += 1)
	robot.overload.connect(func(_point: Vector3,_strength: float) -> void: overloads += 1)
	await ticks(300)
	check(robot.core.position.y > 5.8 and robot.core.position.y < 6.8,"Standing height settles")
	check(absf(robot.core.rotation.z) < .2,"Torso is stable at idle")
	check(robot.core.linear_velocity.length() < .25,"Idle is not continuous sliding or falling")
	metrics["idle_height"] = robot.core.position.y
	var untouched_angle: float = robot.parts["RightForearm"].rotation.z
	var left_initial: float = robot.parts["LeftForearm"].rotation.z
	screen.left_stick.value = Vector2(1,-.6)
	await ticks(150)
	check(absf(wrapf(robot.parts["LeftForearm"].rotation.z-left_initial,-PI,PI)) > .45,"Left stick moves left physical arm")
	check(absf(wrapf(robot.parts["RightForearm"].rotation.z-untouched_angle,-PI,PI)) < .4,"Right arm stays independent of left stick")
	screen._reset()
	await ticks(150)
	var left_before: float = robot.parts["LeftForearm"].rotation.z
	var right_before: float = robot.parts["RightForearm"].rotation.z
	screen.right_stick.value = Vector2(.5,-1)
	await ticks(150)
	check(absf(wrapf(robot.parts["RightForearm"].rotation.z-right_before,-PI,PI)) > .45,"Right stick moves right physical arm")
	check(absf(wrapf(robot.parts["LeftForearm"].rotation.z-left_before,-PI,PI)) < .4,"Left arm stays independent of right stick")
	screen._reset()
	await ticks(120)
	# Two screen fingers must remain separate even when both are active at once.
	var left_point: Vector2 = screen.left_stick.get_global_transform_with_canvas()*(screen.left_stick.origin+Vector2(38,-24))
	var right_point: Vector2 = screen.right_stick.get_global_transform_with_canvas()*(screen.right_stick.origin+Vector2(-35,-29))
	await touch(3,left_point,true)
	await touch(7,right_point,true)
	check(screen.left_stick.touch_index == 3 and screen.right_stick.touch_index == 7,"Two simultaneous touch IDs are owned independently")
	check(screen.left_stick.value.length() > .4 and screen.right_stick.value.length() > .4,"Both joystick vectors remain active together")
	await touch(3,left_point,false)
	check(screen.left_stick.value == Vector2.ZERO and screen.right_stick.touch_index == 7,"Releasing left finger does not release right stick")
	await touch(7,right_point,false)
	check(screen.right_stick.value == Vector2.ZERO,"Right stick releases its finger")
	screen._reset()
	await ticks(120)
	var start_x := robot.core.position.x
	var knee_before: float = robot.parts["RightThigh"].rotation.z
	Input.action_press("future_move_right")
	await ticks(240)
	Input.action_release("future_move_right")
	metrics["walk_right_displacement"] = robot.core.position.x-start_x
	metrics["walk_right_speed"] = robot.core.linear_velocity.x
	check(robot.core.position.x-start_x > 3.0,"Walking advances the articulated body to the right")
	check(robot.core.linear_velocity.x > 1.5 and robot.core.linear_velocity.x < 4,"Walking has bounded nonzero velocity")
	check(absf(robot.parts["RightThigh"].rotation.z-knee_before) > .12,"Legs articulate during walking")
	check(steps > 0,"Footsteps come from physical floor contacts")
	check(robot.core.position.y > 5.5,"Walking maintains stance height")
	var closest_front := 10.0
	var maximum_yaw := 0.0
	Input.action_press("future_move_left")
	for i in range(105):
		await get_tree().physics_frame
		closest_front = minf(closest_front,absf(robot.model_yaw))
		maximum_yaw = maxf(maximum_yaw,absf(robot.model_yaw))
	Input.action_release("future_move_left")
	check(closest_front < .06 and robot.model_yaw < -1.4,"Direction change passes through the front-facing pose")
	check(maximum_yaw <= PI*.5+.01,"Turn never passes through the back-facing half")
	metrics["closest_frontal_yaw"] = closest_front
	var planar := true
	for part: AtlantPart in robot.parts.values():
		var initial: Transform3D = robot.initial_poses[String(part.name)]
		planar = planar and absf(part.position.z-initial.origin.z) < .03
		planar = planar and absf(part.rotation.x) < .02 and absf(part.rotation.y) < .02
	check(planar,"All physical body parts stay in the side-view movement planes")
	screen._toggle_pause()
	var paused_position := robot.core.position
	await ticks(30)
	check(robot.core.position.is_equal_approx(paused_position),"Pause freezes the complete physical rig")
	screen._reset()
	await ticks(150)
	check(not screen.paused and absf(robot.core.position.x) < .4,"Reset also resumes a paused test")
	# Actual external impulse, with balance support disabled, must change the physical state.
	robot.stabilized = false
	var before_impulse := robot.core.position
	robot.core.apply_central_impulse(Vector3(140,180,0))
	await ticks(200)
	metrics["impulse_displacement"] = robot.core.position.distance_to(before_impulse)
	check(robot.core.position.distance_to(before_impulse) > 1.0,"Unstabilized rig reacts to a real external impulse")
	var finite := true
	for part: AtlantPart in robot.parts.values(): finite = finite and part.position.is_finite() and part.linear_velocity.is_finite()
	check(finite,"Collision and fall keep all body states finite")
	robot.stabilized = true
	screen._reset()
	await ticks(240)
	check(robot.core.position.y > 5.8 and absf(robot.core.rotation.z) < .2,"Reset restores the standing rig after the fall")
	# Walking gesture uses the free screen area, outside joystick hitboxes.
	var walking_point := Vector2(get_viewport().get_visible_rect().size.x*.78,230)
	await touch(3,left_point,true)
	await touch(7,right_point,true)
	await touch(9,walking_point,true)
	await touch(9,walking_point,false)
	await touch(9,walking_point,true)
	await ticks(20)
	check(screen.mobile_walk == 1,"Double-tap and hold activates walking on the free right side")
	check(screen.left_stick.touch_index == 3 and screen.right_stick.touch_index == 7,"Walking finger coexists with both hand joystick fingers")
	await touch(9,screen.left_stick.get_global_rect().get_center(),false)
	check(screen.mobile_walk == 0,"Walking releases even over a joystick")
	await touch(3,left_point,false)
	await touch(7,right_point,false)
	# Short cycling checks cleanup of the dedicated 3D world and its physics nodes.
	NavigationManager.back()
	await frames(5)
	var baseline := int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT))
	for i in range(8):
		NavigationManager.go(&"test")
		await frames(4)
		NavigationManager.back()
		await frames(4)
	var final_nodes := int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT))
	check(final_nodes <= baseline+2,"Eight range visits free their 3D worlds and physical bodies")
	check(NavigationManager.host.get_child_count() == 1,"Only one routed screen remains")
	check(not AudioManager.test_active,"Menu audio is restored after leaving the range")
	metrics["foot_contacts"] = steps
	metrics["overload_events"] = overloads
	metrics["nodes_before_cycle"] = baseline
	metrics["nodes_after_cycle"] = final_nodes
	OS.remove_logger(engine_errors)
	check(engine_errors.snapshot().is_empty(),"No engine or script errors during range controls and lifecycle")
	var result := {"engine":Engine.get_version_info()["string"],"passed":passed,"failures":failures,"metrics":metrics,"physical_android_tested":false}
	var f := FileAccess.open("user://range_test_results.json",FileAccess.WRITE)
	f.store_string(JSON.stringify(result,"  "))
	print("RANGE_RESULT ",JSON.stringify(result))
	SettingsManager.reset_defaults()
	AudioManager.shutdown()
	await get_tree().create_timer(.2).timeout
	app.queue_free()
	await frames()
	get_tree().quit(0 if failures.is_empty() else 1)

func touch(index: int, point: Vector2, pressed: bool) -> void:
	var event := InputEventScreenTouch.new()
	event.index = index
	event.position = get_viewport().get_final_transform()*point
	event.pressed = pressed
	Input.parse_input_event(event)
	await frames(2)
