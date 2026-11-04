extends Node
var OUTPUT := OS.get_environment("RIFT_CAPTURE_DIR")
var app: Control
func _ready() -> void: call_deferred("_run")
func frames(n: int = 5) -> void:
 for i in range(n): await get_tree().process_frame
func go(route: StringName) -> void: await NavigationManager.go(route);await frames()
func shot(name_value: String) -> void:
 await frames();await RenderingServer.frame_post_draw;get_viewport().get_texture().get_image().save_png(OUTPUT+name_value+".png");print("CAPTURE ",name_value)
func move_actor(game: Control,x: float) -> void:
 game._release_input()
 for actor: Node2D in [game.robot,game.companion]:
  if not is_instance_valid(actor): continue
  var target := x if actor == game.robot else x-380
  var initial_core: Transform2D = actor.initial_poses["Core"]
  var dx := target-initial_core.origin.x
  actor.reset_cooldown = 3
  for key: String in actor.parts:
   var pose: Transform2D = actor.initial_poses[key];pose.origin.x += dx
   actor.parts[key].reset_pose = pose;actor.parts[key].reset_requested = true
func _run() -> void:
 if OUTPUT.is_empty(): OUTPUT = ProjectSettings.globalize_path("user://qa/nightfall/")
 if not OUTPUT.ends_with("/"): OUTPUT += "/"
 DirAccess.make_dir_recursive_absolute(OUTPUT)
 app = load("res://scenes/menu/main_menu.tscn").instantiate();add_child(app);app.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);await frames(20)
 Expedition.new_campaign("Тест","Пилотов",[[Vector2(.1,.5),Vector2(.6,.2)]],{})
 await go(&"expedition");await get_tree().create_timer(.8).timeout
 NavigationManager.current_screen.get_node("HUD").dispatcher.clear();await shot("landing")
 await get_tree().create_timer(5).timeout
 var game = NavigationManager.current_screen
 game.get_node("HUD").dispatcher.clear();await shot("sea")
 for x: float in [-400.0,4750.0]:
  move_actor(game,x);await frames(24)
  for zoom: float in [.45,.62,1.12]: game.set_camera_zoom(zoom);await frames(24);await shot("edge_%d_%d"%[int(x),int(zoom*100)])
 await go(&"campaign");Expedition.arrive();await go(&"home");await shot("home")
 await go(&"campaign");await shot("map")
 Expedition.depart("A03");await go(&"expedition");await get_tree().create_timer(.8).timeout
 game = NavigationManager.current_screen;game.get_node("HUD").dispatcher.clear();await shot("city")
 game.get_node("HUD/Top/Settings").pressed.emit();await frames();await shot("settings_in_game");game.get_node("HUD").close_overlay();game._set_paused(false)
 await go(&"campaign");Expedition.arrive();Expedition.depart("A04");Expedition.arrive();Expedition.depart("A02");Expedition.arrive();Expedition.depart("A04")
 await go(&"expedition");await get_tree().create_timer(.8).timeout
 NavigationManager.current_screen.get_node("HUD").dispatcher.clear();await shot("bridge")
 # Resize the actual window and logical content to exercise phone layouts.
 get_window().content_scale_size = Vector2i(1024,459);get_window().size = Vector2i(1024,459);await frames(15)
 await shot("bridge_phone")
 await go(&"enlistment");await shot("profile_phone")
 var flow = NavigationManager.current_screen;flow.form_first.text = "Стас";flow.form_family.text = "Александров";flow._identity_next();await frames();await shot("contract_phone")
 flow.signature_pad._start(Vector2(20,30));flow.signature_pad._append(Vector2(130,70));flow.signature_pad.drawing = false;flow._sign_next();flow.type_clock = 100;await shot("briefing_phone")
 await go(&"home")
 AudioManager.shutdown();NavigationManager.current_screen = null;app.queue_free();await frames(5)
 get_tree().quit()
