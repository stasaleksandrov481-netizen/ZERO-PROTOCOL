extends Node
var app: Control
var screen
var output := ""
var contact_saved := false
func _ready() -> void: call_deferred("run")
func ticks(count: int) -> void:
 for i in range(count): await get_tree().physics_frame
func shot(name_value: String) -> void:
 await RenderingServer.frame_post_draw
 get_viewport().get_texture().get_image().save_png(output.path_join(name_value+".png"))
func on_strike(_point: Vector3,_strength: float) -> void:
 if contact_saved: return
 contact_saved = true
 shot("horizon_hit")
func run() -> void:
 output = OS.get_environment("RIFT_CAPTURE_DIR")
 DirAccess.make_dir_recursive_absolute(output)
 SettingsManager.reset_defaults()
 SettingsManager.set_value("video/reduced_motion",true)
 app = load("res://scenes/menu/main_menu.tscn").instantiate()
 add_child(app)
 for i in range(5): await get_tree().process_frame
 await NavigationManager.go(&"test")
 screen = NavigationManager.current_screen
 await ticks(240)
 await shot("horizon_range")
 Input.action_press("future_move_left")
 await ticks(21)
 Input.action_release("future_move_left")
 await shot("horizon_turn")
 screen._reset()
 await ticks(120)
 Input.action_press("future_move_right")
 await ticks(230)
 Input.action_release("future_move_right")
 await ticks(60)
 screen.robot.strike.connect(on_strike)
 SettingsManager.set_value("video/reduced_motion",false)
 screen.left_stick.value = Vector2(-.7,.5)
 screen.right_stick.value = Vector2(-.7,.4)
 await ticks(100)
 screen.left_stick.value = Vector2(1,.38)
 screen.right_stick.value = Vector2(1,.1)
 await ticks(185)
 await shot("horizon_punch")
 print("CAPTURE_PHYSICS ",JSON.stringify({"hits":screen.dummy.hit_count,"dummy_tilt":screen.dummy.max_deflection,"contact_saved":contact_saved}))
 screen._reset()
 await ticks(180)
 screen.robot.stabilized = false
 screen.robot.core.apply_central_impulse(Vector3(140,160,0))
 screen.robot.core.apply_torque_impulse(Vector3(0,0,55))
 await ticks(300)
 await shot("horizon_fall")
 SettingsManager.reset_defaults()
 AudioManager.shutdown()
 await get_tree().create_timer(.15).timeout
 get_tree().quit()
