extends Node
var output := OS.get_environment("RIFT_CAPTURE_DIR")
var app: Control
func _ready() -> void: call_deferred("_run")
func ticks(n: int) -> void:
 for i in range(n): await get_tree().physics_frame
func shot(id: String) -> void:
 for i in range(6): await get_tree().process_frame
 await RenderingServer.frame_post_draw
 get_viewport().get_texture().get_image().save_png(output+id+".png");print("CAPTURE ",id)
func _run() -> void:
 if output.is_empty(): output = ProjectSettings.globalize_path("user://qa/weight/")
 if not output.ends_with("/"): output += "/"
 DirAccess.make_dir_recursive_absolute(output)
 app = load("res://scenes/menu/main_menu.tscn").instantiate();add_child(app);app.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 for i in range(25): await get_tree().process_frame
 Expedition.new_campaign("Стас","Александров",[[Vector2(.1,.3),Vector2(.6,.5)]],{})
 await NavigationManager.go(&"expedition");await ticks(700)
 var game = NavigationManager.current_screen
 game.get_node("HUD").dispatcher.clear();if is_instance_valid(game.field_guide): game.field_guide.dismiss()
 await shot("sea_idle")
 Input.action_press("future_move_right");await ticks(250);game.environment.splash(game.robot.parts.RightFoot.global_position.x,.9);await ticks(12);await shot("sea_step")
 Input.action_release("future_move_right")
 get_window().content_scale_size = Vector2i(1024,459);get_window().size = Vector2i(1024,459)
 await ticks(20);await shot("sea_phone")
 get_window().content_scale_size = Vector2i(1280,720);get_window().size = Vector2i(1280,720);await ticks(20)
 var dx: float = game.enemy.position.x-500-game.robot.core.position.x
 for body in game.robot.parts.values(): body.position.x += dx
 game.stage = "fight";game.enemy.set_enabled(true);Input.action_press("future_move_right");await ticks(240)
 game.right_stick.touch_index = 17;game.right_stick.value = Vector2(-.6,.45);await ticks(90);game.right_stick.value = Vector2(.95,-.55);await ticks(220);await shot("contact")
 var audit := preload("res://tests/collision_audit.gd").new();audit.robot = game.robot;audit.enemy = game.enemy;audit.z_index = 80;game.get_node("WorldView/World/Range").add_child(audit);await ticks(2);await shot("collision_audit");audit.queue_free()
 game.right_stick.release();Input.action_release("future_move_right");await ticks(480);await shot("released")
 await NavigationManager.go(&"home")
 for i in range(5): await get_tree().process_frame
 AudioManager.shutdown();NavigationManager.current_screen = null;app.queue_free()
 for i in range(8): await get_tree().process_frame
 get_tree().quit()
