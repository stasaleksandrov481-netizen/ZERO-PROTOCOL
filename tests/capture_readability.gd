extends Node
var output := OS.get_environment("RIFT_CAPTURE_DIR")
var app: Control
var contacts := 0
var strongest := 0.0
var records: Array[Dictionary] = []
func _ready() -> void: call_deferred("_run")
func ticks(n: int) -> void:
 for i in range(n): await get_tree().physics_frame
func shot(id: String,game: Control) -> void:
 await get_tree().process_frame;await RenderingServer.frame_post_draw
 get_viewport().get_texture().get_image().save_png(output+id+".png")
 records.append({"id":id,"contacts":contacts,"maximum_strength":strongest,"health":game.enemy.health,"camera_zoom":game.camera.zoom.x,"size":get_viewport().size})
 print("CAPTURE ",id," contacts=",contacts," strength=",strongest," zoom=",game.camera.zoom.x)
func place(actor: Node2D,x: float) -> void:
 actor.reset_stance();var origin: Transform2D = actor.initial_poses.Core
 for key: String in actor.parts:
  var pose: Transform2D = actor.initial_poses[key];pose.origin.x += x-origin.origin.x
  actor.parts[key].reset_pose = pose;actor.parts[key].reset_requested = true
func _run() -> void:
 if output.is_empty(): output = ProjectSettings.globalize_path("user://qa/readability/")
 if not output.ends_with("/"): output += "/"
 DirAccess.make_dir_recursive_absolute(output)
 app = load("res://scenes/menu/main_menu.tscn").instantiate();add_child(app);app.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 for i in range(25): await get_tree().process_frame
 Expedition.new_campaign("Стас","Александров",[[Vector2(.1,.3),Vector2(.6,.6)]],{});await NavigationManager.go(&"expedition");await ticks(700)
 var game = NavigationManager.current_screen;var hud = game.get_node("HUD")
 hud.dispatcher.clear();if is_instance_valid(game.field_guide): game.field_guide.dismiss()
 game.chatter.contact = true;game.chatter.first_walk = true
 place(game.robot,game.enemy.position.x-560);place(game.companion,game.enemy.position.x-910)
 game.enemy.rng.seed = 9;game.enemy.balance.rng.seed = 12;game.robot.balance.rng.seed = 7
 game.set_camera_zoom(1.12);game.stage = "fight";game.enemy.set_enabled(true)
 game.robot.impact.connect(func(_p: Vector2,strength: float,_d: Vector2,body: PhysicsBody2D) -> void:
  if body == game.enemy: contacts += 1;strongest = maxf(strongest,strength))
 var captured := false
 for i in range(1600):
  var distance: float = game.enemy.position.x-game.robot.core.position.x
  Input.action_release("future_move_right");Input.action_release("future_move_left")
  if not game.robot.fallen:
   if distance > 340: Input.action_press("future_move_right")
   elif distance < 290: Input.action_press("future_move_left")
   for hand: int in [0,1]:
    var stick = game.left_stick if hand == 0 else game.right_stick
    stick.touch_index = 81+hand
    var phase: int = (i+hand*90)%180
    var aim := Vector2(-.85,.6) if phase < 65 else Vector2(1,-.42)
    stick._update_value(stick.origin+aim*stick.radius)
  await ticks(1)
  if i == 180: await shot("combat_framing",game)
  if not captured and strongest >= .55 and game.hit_feedback.kick_age > .04 and game.hit_feedback.kick_age < .13:
   await shot("heavy_contact",game);captured = true
   get_window().content_scale_size = Vector2i(1024,459);get_window().size = Vector2i(1024,459)
  if captured and i > 500 and game.hit_feedback.kick_age < .15:
   await shot("contact_phone",game);break
 Input.action_release("future_move_right");Input.action_release("future_move_left");game._release_input()
 await ticks(30);await shot("combat_phone",game)
 var log_file := FileAccess.open(output+"contacts.json",FileAccess.WRITE);log_file.store_string(JSON.stringify(records,"  "));log_file.close()
 await NavigationManager.go(&"home");AudioManager.shutdown();await ticks(8);get_tree().quit()
