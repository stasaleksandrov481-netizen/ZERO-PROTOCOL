extends Node
var output := ""
func _ready() -> void: call_deferred("run")
func ticks(count: int) -> void:
 for i in range(count): await get_tree().physics_frame
func shot(name_value: String) -> void:
 await RenderingServer.frame_post_draw
 get_viewport().get_texture().get_image().save_png(output.path_join(name_value+".png"))
func run() -> void:
 output = OS.get_environment("RIFT_CAPTURE_DIR");DirAccess.make_dir_recursive_absolute(output)
 SettingsManager.reset_defaults();SettingsManager.set_value("video/reduced_motion",true)
 var app = load("res://scenes/menu/main_menu.tscn").instantiate();add_child(app)
 for i in range(5): await get_tree().process_frame
 await NavigationManager.go(&"test")
 var s = NavigationManager.current_screen
 if not s.has_method("is_range_ready") or not s.is_range_ready():get_tree().quit(1);return
 await ticks(240)
 await shot("at01_2d_idle")
 s.right_stick.value = Vector2(.28,-.30)
 s.left_stick.value = Vector2(.75,-.12)
 await ticks(210)
 await shot("at01_2d_bent")
 print("CAPTURE2D ",s.robot.core.position," elbow=",s.robot.parts.RightForearm.rotation-s.robot.parts.RightUpperArm.rotation)
 AudioManager.shutdown();await get_tree().create_timer(.15).timeout
 get_tree().quit()
