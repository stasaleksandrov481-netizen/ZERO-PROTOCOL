extends Node
var passed := 0
var failed := 0
var app: Control
func _ready() -> void: call_deferred("_run")
func check(ok: bool,label: String) -> void:
 if ok: passed += 1;print("PASS ",label)
 else: failed += 1;print("FAIL ",label)
func ticks(n: int) -> void:
 for i in range(n): await get_tree().physics_frame
func frames(n: int = 5) -> void:
 for i in range(n): await get_tree().process_frame
func place(actor: Node2D,x: float) -> void:
 actor.reset_stance();var origin: Transform2D = actor.initial_poses.Core
 for key: String in actor.parts:
  var pose: Transform2D = actor.initial_poses[key];pose.origin.x += x-origin.origin.x
  actor.parts[key].reset_pose = pose;actor.parts[key].reset_requested = true
func _run() -> void:
 var errors = NavigationManager.RangeErrors.new();OS.add_logger(errors)
 get_window().content_scale_size = Vector2i(1280,720);get_window().size = Vector2i(1280,720)
 app = load("res://scenes/menu/main_menu.tscn").instantiate();add_child(app);app.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);await frames(25)
 Expedition.new_campaign("Тест","Контакта",[[Vector2(.1,.3),Vector2(.6,.6)]],{});await NavigationManager.go(&"expedition");await ticks(700)
 var game = NavigationManager.current_screen;var hud = game.get_node("HUD");var feedback = game.hit_feedback
 hud.dispatcher.clear();if is_instance_valid(game.field_guide): game.field_guide.dismiss()
 place(game.robot,game.enemy.position.x-580);place(game.companion,game.enemy.position.x-940)
 game.chatter.contact = true;game.stage = "fight";game.enemy.enabled = true;game.enemy.freeze = true;game.enemy.set_physics_process(false)
 game.set_camera_zoom(1.12);await ticks(420)
 var factor := clampf(float(game.arena_view.size.y)/720,.5,2)
 print("FRAMING zoom=",game.camera.zoom.x/factor," manual=",game.target_zoom," subjects=",game._camera_subjects()," viewport=",game.arena_view.size," factor=",factor)
 check(game.camera.zoom.x/factor < game.target_zoom*.92,"close combat camera smoothly widens for all three participants")
 var contained := true
 for x: float in game._camera_subjects():
  var screen: float = (x-game.camera.get_screen_center_position().x)*game.camera.zoom.x+game.arena_view.size.x*.5
  contained = contained and screen > game.arena_view.size.x*.16 and screen < game.arena_view.size.x*.84
 check(contained,"player companion and enemy remain in the central readable part of the frame")
 var top_pixel: float = (game._camera_top_y()-game.camera.get_screen_center_position().y)*game.camera.zoom.x+game.arena_view.size.y*.5
 var hud_bottom: float = hud._enemy_card().end.y*game.arena_view.size.x/game.size.x
 check(top_pixel > hud_bottom+6,"fighter heads stay below the upper combat HUD")
 check(hud.get_node("Zoom/Reset").text == "%d%%"%roundi(game.camera.zoom.x/factor/game.CAMERA_ZOOM*100),"zoom percentage reports the actual camera scale")
 game.enemy.enabled = false;await ticks(480)
 check(absf(game.camera.zoom.x/factor-game.target_zoom) < .025,"leaving combat restores the selected manual zoom")
 feedback.cancel();feedback.hit(game.robot.core.position,.95,Vector2.RIGHT);feedback._process(.04)
 check(game.camera.offset.x > 4,"strong contact produces a directional camera recoil")
 var right: float = game.camera.offset.x
 feedback.cancel();feedback.hit(game.robot.core.position,.95,Vector2.LEFT);feedback._process(.04)
 check(game.camera.offset.x < -4 and absf(right+game.camera.offset.x) < 6,"opposite impact direction reverses the main recoil")
 check(feedback.framing_pullback() > 0 and Engine.time_scale == 1,"heavy contact widens the view without slowing controls or simulation")
 for i in range(1000): feedback.hit(Vector2(i*200,-300),1,Vector2.RIGHT)
 feedback._process(.02)
 check(feedback.shockwaves.size() <= 8 and game.camera.offset.length() < 35,"contact spam keeps visual effects and camera displacement bounded")
 game._set_paused(true,false);var paused_position: Vector2 = game.camera.position;var paused_zoom: Vector2 = game.camera.zoom;await ticks(60)
 check(game.camera.position.is_equal_approx(paused_position) and game.camera.zoom.is_equal_approx(paused_zoom) and game.camera.offset == Vector2.ZERO,"pause cancels recoil and freezes camera framing")
 game._set_paused(false);SettingsManager.set_value(&"video/reduced_motion",true);game.enemy.enabled = true
 feedback.hit(game.robot.core.position,1,Vector2.RIGHT);await frames(12)
 check(game.camera.offset == Vector2.ZERO and feedback.framing_pullback() == 0 and game.framing_ratio == 1,"reduced motion disables recoil and automatic camera zoom")
 hud.observed_enemy = null;game.enemy.health = game.enemy.MAX_HEALTH;await frames()
 game.enemy.health -= 100;await frames(1)
 check(hud.enemy_health.value == game.enemy.health,"health meter immediately reports the true remaining health")
 check(hud.enemy_health_trail.value == hud.enemy_health.value,"reduced motion makes health feedback immediate")
 SettingsManager.set_value(&"video/reduced_motion",false)
 game.enemy.health -= 80;await frames(1)
 check(hud.enemy_health_trail.value > hud.enemy_health.value,"ordinary mode visibly retains the recent damage segment")
 await ticks(90)
 check(is_equal_approx(hud.enemy_health_trail.value,hud.enemy_health.value),"the recent damage segment settles to real health")
 game.left_stick.touch_index = 71;game.right_stick.touch_index = 72;hud.hand_contact(0,.9);await frames(1)
 check(game.left_stick.contact_flash > .5 and game.right_stick.contact_flash == 0,"only the hand that landed lights up")
 check(game.left_stick.touch_index == 71 and game.right_stick.touch_index == 72,"contact indication never changes hand ownership")
 game._release_input();game.enemy.enabled = false;await frames()
 check(not hud.enemy_health.visible and not hud.enemy_health_trail.visible and not hud.enemy_intent.visible,"inactive enemy leaves no stale combat meters")
 for viewport: Vector2i in [Vector2i(1280,720),Vector2i(1024,459)]:
  get_window().content_scale_size = viewport;get_window().size = viewport;await frames(12);hud.layout_hud()
  check(hud.enemy_health.get_rect().is_equal_approx(hud.enemy_health_trail.get_rect()) and hud.get_rect().encloses(hud.run_button.get_rect()),"health layers align and run remains inside viewport %s"%viewport)
 game.set_camera_zoom(.45);game.enemy.enabled = true;feedback.hit(game.robot.core.position,1,Vector2.RIGHT);await ticks(240)
 factor = clampf(float(game.arena_view.size.y)/720,.5,2)
 check(game.camera.zoom.x/factor >= game.CAMERA_MIN-.001,"impact framing never exceeds the allowed far zoom")
 await NavigationManager.go(&"home");AudioManager.shutdown();await frames()
 check(errors.snapshot().is_empty(),"zero unexpected script or engine errors")
 for item: Dictionary in errors.snapshot(): print("UNEXPECTED ",item)
 OS.remove_logger(errors);print("COMBAT READABILITY RESULT ",passed," passed / ",failed," failed");get_tree().quit(1 if failed else 0)
