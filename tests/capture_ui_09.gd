extends Node
var directory := ""
func _ready() -> void: call_deferred("run")
func frames(n: int) -> void:
 for i in range(n): await get_tree().process_frame
func ticks(n: int) -> void:
 for i in range(n): await get_tree().physics_frame
func shot(name_value: String) -> void:
 RenderingServer.force_draw(false);RenderingServer.force_draw(false);get_viewport().get_texture().get_image().save_png(directory+"/"+name_value+".png")
func run() -> void:
 directory = OS.get_environment("RIFT_CAPTURE_DIR");DirAccess.make_dir_recursive_absolute(directory)
 if OS.get_environment("RIFT_PHONE") == "1": get_window().size = Vector2i(1024,459)
 SettingsManager.reset_defaults();SettingsManager.set_value("video/reduced_motion",true)
 var app = load("res://scenes/menu/main_menu.tscn").instantiate();add_child(app);await frames(5)
 RenderingServer.render_loop_enabled = false
 await shot("home")
 await NavigationManager.go(&"campaign");await frames(5);await shot("map")
 await NavigationManager.go(&"settings");await frames(5);await shot("settings")
 for route: StringName in [&"operations",&"hangar",&"archive"]:
  await NavigationManager.go(route);await ticks(360);await frames(4);
  await shot(String(route))
 Expedition.begin("Первый");Expedition.mark_checkpoint("fight")
 await NavigationManager.go(&"expedition");await ticks(260)
 var s = NavigationManager.current_screen
 if not s.has_method("is_range_ready") or not s.is_range_ready(): get_tree().quit(1);return
 await shot("combat")
 s._toggle_pause();await frames(3);await shot("pause");s._toggle_pause()
 s.open_radio_history();await frames(3);await shot("history");s._resume_ui()
 s._show_debrief("МАЯК / ГРУЗ ДОСТАВЛЕН","Невель: «Генераторы на месте. Первый рейс принят».",false);await frames(3);await shot("report")
 AudioManager.shutdown();get_tree().quit()
