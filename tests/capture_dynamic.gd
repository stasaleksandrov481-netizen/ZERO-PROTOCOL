extends Node
var output := OS.get_environment("RIFT_CAPTURE_DIR")
var app: Control
func _ready() -> void: call_deferred("_run")
func ticks(n: int) -> void:
 for i in range(n): await get_tree().physics_frame
func shot(id: String) -> void:
 for i in range(5): await get_tree().process_frame
 await RenderingServer.frame_post_draw;get_viewport().get_texture().get_image().save_png(output+id+".png");print("CAPTURE ",id)
func place(actor: Node2D,x: float) -> void:
 actor.reset_stance();var core_pose: Transform2D = actor.initial_poses.Core
 for key: String in actor.parts:
  var pose: Transform2D = actor.initial_poses[key];pose.origin.x += x-core_pose.origin.x
  actor.parts[key].reset_pose = pose;actor.parts[key].reset_requested = true
func _run() -> void:
 if output.is_empty(): output = ProjectSettings.globalize_path("user://qa/dynamic/")
 if not output.ends_with("/"): output += "/"
 DirAccess.make_dir_recursive_absolute(output)
 app = load("res://scenes/menu/main_menu.tscn").instantiate();add_child(app);app.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 for i in range(25): await get_tree().process_frame
 Expedition.new_campaign("Стас","Александров",[[Vector2(.1,.3),Vector2(.6,.6)]],{});await NavigationManager.go(&"expedition");await ticks(700)
 var game = NavigationManager.current_screen;var hud = game.get_node("HUD")
 hud.dispatcher.clear();if is_instance_valid(game.field_guide): game.field_guide.dismiss()
 Input.action_press("future_move_right");Input.action_press("future_run");await ticks(350)
 game.environment.splash(game.robot.parts.RightFoot.position.x,1);await ticks(10);await shot("heavy_run")
 get_window().content_scale_size = Vector2i(1024,459);get_window().size = Vector2i(1024,459);await ticks(15);await shot("run_phone")
 get_window().content_scale_size = Vector2i(1280,720);get_window().size = Vector2i(1280,720);await ticks(15)
 Input.action_release("future_move_right");Input.action_release("future_run")
 for gesture: Dictionary in [{"id":"punch_straight","value":Vector2(1,0)},{"id":"punch_upper","value":Vector2(0,-.9)},{"id":"punch_down","value":Vector2(0,.85)}]:
  game.right_stick.touch_index = 41;game.right_stick._update_value(game.right_stick.origin+gesture.value*game.right_stick.radius);await ticks(180);await shot(gesture.id)
 game.right_stick.release()
 Input.action_release("future_move_right");Input.action_release("future_run");place(game.robot,2200);place(game.companion,1800);await ticks(180)
 game.robot.balance.rng.seed = 12;game.robot.receive_impact(.45,Vector2.LEFT);await ticks(35);await shot("player_catch")
 game.robot.receive_impact(1,Vector2.LEFT);await ticks(8);game.robot.receive_impact(1,Vector2.LEFT);await ticks(175);await shot("player_down");await ticks(150);await shot("player_rising");await ticks(450)
 game.set_camera_zoom(.52);var previous_enemy: RigidBody2D = game.enemy;game.enemy = null;previous_enemy.queue_free();await ticks(2)
 game.enemy = load("res://scripts/gameplay/klyk_2d.gd").new();game.enemy.position = Vector2(game.robot.core.position.x+760,-330);game.enemy.target = game.robot;game.get_node("WorldView/World/Range").add_child(game.enemy)
 game.enemy.landed.connect(game._enemy_landed);game.enemy.defeated.connect(game._enemy_defeated);game.enemy.planted.connect(func(point: Vector2,strength: float) -> void: game.environment.splash(point.x,strength))
 game.enemy.rng.seed = 9;game.enemy.balance.rng.seed = 12;game.enemy.charge_cooldown = 0;game.enemy._set_behavior("idle");game.stage = "fight";game.enemy.set_enabled(true);game.chatter["contact"] = true;hud.dispatcher.clear()
 for i in range(360):
  await ticks(1)
  if i%60 == 0: print("RUSH_CAPTURE_STATE ",game.enemy.behavior," balance=",game.enemy.balance.state," rot=",game.enemy.rotation," dx=",game.enemy.position.x-game.robot.core.position.x)
  if game.enemy.behavior == "rush" and game.enemy.behavior_age > .20: break
 await shot("enemy_rush")
 game.enemy.register_hit(.60,false,Vector2.RIGHT);await ticks(35);await shot("enemy_catch")
 game.enemy.register_hit(1,false,Vector2.RIGHT);await ticks(8);game.enemy.register_hit(1,false,Vector2.RIGHT);await ticks(170);await shot("enemy_down");await ticks(170);await shot("enemy_rising")
 get_window().content_scale_size = Vector2i(1024,459);get_window().size = Vector2i(1024,459);await ticks(15);await shot("combat_phone")
 await NavigationManager.go(&"home");AudioManager.shutdown();await ticks(8);NavigationManager.current_screen = null;app.queue_free();await get_tree().process_frame;get_tree().quit()
