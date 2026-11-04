extends Node
var output := OS.get_environment("RIFT_CAPTURE_DIR")
var app: Control
func _ready() -> void: call_deferred("_run")
func frames(n: int = 6) -> void:
 for i in range(n): await get_tree().process_frame
func shot(id: String) -> void:
 await get_tree().create_timer(.4).timeout;await RenderingServer.frame_post_draw
 get_viewport().get_texture().get_image().save_png(output+id+".png");print("CAPTURE ",id)
func _run() -> void:
 if output.is_empty(): output = ProjectSettings.globalize_path("user://qa/prologue/")
 if not output.ends_with("/"): output += "/"
 DirAccess.make_dir_recursive_absolute(output)
 app = load("res://scenes/menu/main_menu.tscn").instantiate();add_child(app);app.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);await frames(25)
 await NavigationManager.go(&"enlistment");await frames()
 var flow = NavigationManager.current_screen
 flow.form_first.text = "Стас";flow.form_family.text = "Александров";flow._identity_next();await frames()
 flow.signature_pad._start(Vector2(25,35));flow.signature_pad._append(Vector2(145,75));flow.signature_pad.drawing = false;flow._sign_next();await frames()
 for i in range(5):
  flow.dialogue_index = i;flow.briefing_phase = "question";flow._refresh_briefing();flow.cinematic.reveal_text();await shot("prologue_%d"%i)
 flow._answer(1);flow.cinematic.reveal_text();await shot("reply")
 flow._advance_briefing();await shot("readiness")
 get_window().content_scale_size = Vector2i(1024,459);get_window().size = Vector2i(1024,459);await frames(15)
 flow.briefing_phase = "question";flow.dialogue_index = 0;flow._refresh_briefing();flow.cinematic.reveal_text();await shot("prologue_phone")
 flow._answer(1);flow.cinematic.reveal_text();await shot("reply_phone")
 flow._skip_briefing();await shot("readiness_phone")
 get_window().content_scale_size = Vector2i(800,450);get_window().size = Vector2i(800,450);await frames(15)
 flow.briefing_phase = "question";flow.dialogue_index = 2;flow._refresh_briefing();flow.cinematic.reveal_text();await shot("prologue_small")
 get_window().content_scale_size = Vector2i(1280,720);get_window().size = Vector2i(1280,720);await frames(15)
 flow._skip_briefing();flow._advance_briefing();await frames(25);await get_tree().create_timer(5.5).timeout
 var game = NavigationManager.current_screen;game.get_node("HUD").dispatcher.clear();await shot("guide")
 game.open_radio_history();await frames();await shot("journal")
 game.get_node("HUD")._filter_history(Expedition.radio_log,"prologue");await frames();await shot("journal_prologue")
 game.get_node("HUD").close_overlay();game._set_paused(false)
 game._set_paused(true);await shot("pause")
 get_window().content_scale_size = Vector2i(1024,459);get_window().size = Vector2i(1024,459);await frames(15);await shot("pause_phone")
 game.get_node("HUD").show_history(Expedition.radio_log);await frames();game.get_node("HUD")._filter_history(Expedition.radio_log,"prologue");await shot("journal_phone")
 await NavigationManager.go(&"home");AudioManager.shutdown();await frames();get_tree().quit()
