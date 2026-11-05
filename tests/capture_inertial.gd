extends Node
## Real solver captures; only the labelled setup impulses are injected by this QA scene.
var output := OS.get_environment("RIFT_CAPTURE_DIR")
var app: Control
var records: Array[Dictionary] = []
var game: Control
func _ready() -> void: call_deferred("_run")
func ticks(n: int) -> void:
 for i in range(n): await get_tree().physics_frame
func shot(id: String,setup: String = "gameplay") -> void:
 await get_tree().process_frame;await RenderingServer.frame_post_draw
 get_viewport().get_texture().get_image().save_png(output+id+".png")
 records.append({"id":id,"setup":setup,"body_angle":game.enemy.rotation,"head_relative_angle":game.enemy.head_body.rotation-game.enemy.rotation,"body_count":game.enemy.parts.size(),"joint_count":game.enemy.joints.size(),"radio_fade":game.get_node("HUD").radio.face_fade,"size":get_viewport().size})
 print("CAPTURE ",id," body=",game.enemy.rotation," head=",game.enemy.head_body.rotation-game.enemy.rotation)
func place(actor: Node2D,x: float) -> void:
 actor.reset_stance();var core_pose: Transform2D = actor.initial_poses.Core
 for key: String in actor.parts:
  var pose: Transform2D = actor.initial_poses[key];pose.origin.x += x-core_pose.origin.x
  actor.parts[key].reset_pose = pose;actor.parts[key].reset_requested = true
func reset_enemy(x: float) -> void:
 game.enemy.set_enabled(false);game.enemy.reset_stance(Vector2(x,-330));await ticks(3)
 game.enemy.set_enabled(true);game.enemy.ai_enabled = false;game.enemy.desired_speed = 0;await ticks(240)
func phone(enabled: bool) -> void:
 var viewport := Vector2i(1024,459) if enabled else Vector2i(1280,720)
 get_window().content_scale_size = viewport;get_window().size = viewport;await ticks(18)
func _run() -> void:
 if output.is_empty(): output = ProjectSettings.globalize_path("user://qa/inertial/")
 if not output.ends_with("/"): output += "/"
 DirAccess.make_dir_recursive_absolute(output)
 app = load("res://scenes/menu/main_menu.tscn").instantiate();add_child(app);app.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 for i in range(25): await get_tree().process_frame
 Expedition.new_campaign("Стас","Александров",[[Vector2(.1,.3),Vector2(.6,.6)]],{});await NavigationManager.go(&"expedition");await ticks(700)
 game = NavigationManager.current_screen;var hud = game.get_node("HUD");var enemy = game.enemy
 hud.dispatcher.clear();game.chatter.contact = true;game.chatter.first_walk = true
 if is_instance_valid(game.field_guide): game.field_guide.dismiss()
 place(game.robot,2150);place(game.companion,1750);game.set_camera_zoom(.76);await ticks(180)
 game.stage = "fight";await reset_enemy(2900)
 enemy.desired_speed = -135;enemy.behavior = "pursue";await ticks(140);await shot("enemy_stride")
 await reset_enemy(2720)
 enemy.apply_impulse(Vector2(7500,0),Vector2(0,45));await ticks(16);await shot("belly_inertia","native 7500 belly impulse, no head force")
 await reset_enemy(2720)
 var head = enemy.head_body;var jaw := Vector2(-102,72)
 var probe := RigidBody2D.new();probe.mass = 7.5;probe.gravity_scale = 0;probe.collision_layer = 2;probe.collision_mask = 4;probe.continuous_cd = RigidBody2D.CCD_MODE_CAST_SHAPE
 var collision := CollisionShape2D.new();var circle := CircleShape2D.new();circle.radius = 16;collision.shape = circle;probe.add_child(collision)
 probe.position = head.global_transform*jaw+Vector2(0,220);game.get_node("WorldView/World/Range").add_child(probe);probe.linear_velocity = Vector2(0,-750)
 var captured := false
 for i in range(130):
  await ticks(1)
  if not captured and head.rotation-enemy.rotation > .28:
   await shot("jaw_joint","upward 7.5-ton native collision probe, no head animation");captured = true
 probe.queue_free()
 await reset_enemy(2740)
 enemy.set_physics_process(false);await ticks(300);await shot("physical_ragdoll","muscles disabled, gravity and nine native joints remain")
 enemy.set_physics_process(true);enemy.balance.fall(signf(enemy.rotation));await ticks(410);await shot("ragdoll_recovery","same physical bodies with balance recovery")
 await reset_enemy(2850);enemy.set_enabled(false)
 place(game.robot,2250);place(game.companion,2290);await ticks(3);game._companion_tick(.5);await shot("player_foreground")
 game.stage = "fight";enemy.set_enabled(true);hud.dispatcher.enqueue("КЕДР","Держу левый фланг. Продолжай идти к огням дока.",2,"capture_compact");await ticks(70)
 await phone(true);await shot("radio_combat_phone")
 hud.radio.idle_button.pressed.emit();await ticks(12);await shot("radio_fade_phone")
 await ticks(40);await shot("radio_expanded_phone")
 await phone(false);await shot("radio_expanded")
 var log_file := FileAccess.open(output+"captures.json",FileAccess.WRITE);log_file.store_string(JSON.stringify(records,"  "));log_file.close()
 await NavigationManager.go(&"home");AudioManager.shutdown();await ticks(8);get_tree().quit()
