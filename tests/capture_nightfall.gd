extends Node
var root_app: Control
var OUTPUT := OS.get_environment("RIFT_CAPTURE_DIR")
func _ready() -> void: call_deferred("_run")
func _wait_frames(count: int = 4) -> void:
 for i in range(count): await get_tree().process_frame
func _shot(name_value: String) -> void:
 await _wait_frames(3);await RenderingServer.frame_post_draw
 var image := get_viewport().get_texture().get_image();image.save_png(OUTPUT+name_value+".png");print("CAPTURE ",name_value)
func _go(route: StringName) -> void:
 await NavigationManager.go(route);await _wait_frames(5)
func _run() -> void:
 if OUTPUT.is_empty(): OUTPUT = ProjectSettings.globalize_path("user://qa/nightfall/")
 if not OUTPUT.ends_with("/"): OUTPUT += "/"
 DirAccess.make_dir_recursive_absolute(OUTPUT)
 root_app = load("res://scenes/menu/main_menu.tscn").instantiate();add_child(root_app);root_app.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 await _wait_frames(25)
 await _shot("01_home")
 await _go(&"campaign");await _shot("02_campaign")
 await _go(&"enlistment");await _shot("03_profile")
 var flow: Control = NavigationManager.current_screen
 flow.form_first.text = "Стас";flow.form_family.text = "Александров";flow._identity_next();await _wait_frames();await _shot("04_contract")
 flow.signature_pad._start(Vector2(35,60))
 for i in range(35): flow.signature_pad._append(Vector2(35+i*5,60+sin(i*.45)*17))
 flow.signature_pad.drawing = false;await _shot("05_signature")
 flow._sign_next();await _wait_frames();flow.type_clock = 100;await _shot("06_briefing")
 for i in range(5): flow._answer(0);await _wait_frames()
 await _wait_frames(20)
 if NavigationManager.current_route != &"expedition": print("EXPEDITION FAILED: ",NavigationManager.current_route);get_tree().quit(1);return
 var game: Control = NavigationManager.current_screen
 print("GAME READY ",game.is_range_ready())
 await _shot("07_landing")
 await get_tree().create_timer(6).timeout
 await _shot("08_sea")
 print("STABLE Y ",game.robot.core.position.y," X ",game.robot.core.position.x)
 game.get_node("HUD").dispatcher.clear()
 await _shot("09_sea_hud")
 game._set_paused(true,false);game.get_node("HUD").show_pause();await _shot("10_pause");game._set_paused(false)
 game._enemy_defeated()
 for part in game.robot.parts.values(): part.position.x += 4600
 await _wait_frames(15)
 game._interact();await _wait_frames();await _shot("11_docked")
 await _go(&"campaign");await _shot("12_network")
 for dest: String in ["A03","A01","A02"]:
  if Expedition.flags.get("ROUTE_ACTIVE",false): Expedition.arrive()
  if not Expedition.depart(dest): print("ROUTE SKIP ",dest);continue
  await _go(&"expedition");await get_tree().create_timer(.8).timeout
  NavigationManager.current_screen.get_node("HUD").dispatcher.clear()
  await _shot("13_route_"+dest)
  await _go(&"campaign")
 await _go(&"hangar");await _wait_frames(10);await _shot("14_hangar")
 await _go(&"settings");await _shot("15_settings")
 await _go(&"home")
 get_tree().quit()
