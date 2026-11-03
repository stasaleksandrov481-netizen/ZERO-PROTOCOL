extends Node
const Dispatch = preload("res://scripts/systems/radio_dispatch.gd")
var passed := 0
var failures: Array[String] = []
var errors
var app
func _ready() -> void: call_deferred("run")
func frames(n: int) -> void:
 for i in range(n): await get_tree().process_frame
func ticks(n: int) -> void:
 for i in range(n): await get_tree().physics_frame
func check(value: bool,label: String) -> void:
 if value: passed += 1
 else: failures.append(label)
 print("PASS " if value else "FAIL ",label)
func touch(id: int,p: Vector2,down: bool) -> void:
 # Synthetic OS input uses window pixels; targets above are logical canvas coordinates.
 var e := InputEventScreenTouch.new();e.index = id;e.position = get_viewport().get_final_transform()*p;e.pressed = down;Input.parse_input_event(e);await frames(2)
func inside(control: Control) -> bool:
 var a := control.get_global_transform_with_canvas()*Vector2.ZERO
 var b := control.get_global_transform_with_canvas()*control.size
 return a.x >= -1 and a.y >= -1 and b.x <= get_viewport().get_visible_rect().size.x+1 and b.y <= get_viewport().get_visible_rect().size.y+1
func run() -> void:
 get_window().size = Vector2i(1024,459) if OS.get_environment("RIFT_PHONE") == "1" else Vector2i(1280,720)
 errors = NavigationManager.RangeErrors.new();OS.add_logger(errors)
 SettingsManager.reset_defaults();SettingsManager.set_value("video/reduced_motion",true)
 if OS.get_environment("RIFT_PHONE") == "1": SettingsManager.set_value("ui/scale",1.25)
 app = load("res://scenes/menu/main_menu.tscn").instantiate();add_child(app);await frames(5)
 var dispatcher := Dispatch.new()
 var full := "Первый, не рви привод. Перенеси вес на переднюю ступню и проверь кулак. Машина должна выдерживать замах, контакт и торможение, не теряя положение корпуса над опорой."
 check(dispatcher.enqueue("ТАЯ",full,0,"instruction"),"radio accepts a full instruction")
 check(not dispatcher.enqueue("ТАЯ",full,0,"instruction"),"radio does not enqueue duplicate instructions")
 dispatcher.enqueue("КЕДР","Контакт справа!",3,"urgent")
 check(dispatcher.current.id == "urgent","urgent combat call interrupts a lower-priority transmission")
 dispatcher.advance()
 var collected: Array[String] = []
 while not dispatcher.current.is_empty(): collected.append(str(dispatcher.current.body));dispatcher.advance()
 check(" ".join(collected) == full,"automatic radio pages preserve every word")
 var bounded := Dispatch.new()
 for i in range(35): bounded.enqueue("ЭХО","Сообщение %d"%i,0,"id_%d"%i)
 check(bounded.pending.size() <= bounded.LIMIT,"radio queue remains bounded")
 bounded.enqueue("КЕДР","Контакт!",3,"full_queue_alarm");bounded.advance()
 check(bounded.current.id == "id_0" and bounded.pending.size() <= bounded.LIMIT,"an urgent call preserves the interrupted transmission even when the queue is full")
 check(Expedition.new_campaign("Стас"),"new profile starts transactionally")
 Expedition.mark_checkpoint("road")
 await NavigationManager.go(&"expedition");await ticks(300)
 var s = NavigationManager.current_screen
 check(s.has_method("is_range_ready") and s.is_range_ready(),"redesigned mission opens completely")
 if not s.has_method("is_range_ready") or not s.is_range_ready():get_tree().quit(1);return
 var hud = s.get_node("HUD")
 check(absf(s.target_zoom-.62) < .001 and absf(s.camera.zoom.x-.62) < .003,"entry camera starts farther out at 0.62")
 check(hud.radio.active and hud.radio.portraits != null and hud.radio.person == "vetrova","radio binds the current sender to a real portrait")
 check(Expedition.radio_log.size() > 0 and Expedition.radio_log[0].text == hud.dispatcher.current.full_body,"history stores full messages independently of display pages")
 var lp: Vector2 = s.left_stick.get_global_transform_with_canvas()*s.left_stick.origin
 var rp: Vector2 = s.right_stick.get_global_transform_with_canvas()*s.right_stick.origin
 var wp: Vector2 = hud.right_walk.get_global_transform_with_canvas()*(hud.right_walk.size*.5)
 await touch(3,lp,true);await touch(7,rp,true);await touch(10,wp,true);await ticks(15)
 check(s.left_stick.touch_index == 3 and s.right_stick.touch_index == 7 and s.mobile_walk > 0 and s.robot.walk_axis > 0,"three fingers independently own two arms and walking")
 await touch(10,wp,false);await touch(3,lp,false);await touch(7,rp,false)
 var world = s.get_node("WorldView/World/Range")
 var scrap := RigidBody2D.new();scrap.mass = 1;scrap.position = Vector2(400,-200);scrap.linear_velocity = Vector2(40,0);world.add_child(scrap)
 var shape := CollisionShape2D.new();var box := RectangleShape2D.new();box.size = Vector2(20,10);shape.shape = box;scrap.add_child(shape)
 await ticks(10)
 var environment_time: float = s.environment.clock
 s._toggle_pause();await frames(5)
 var paused_transform := scrap.global_transform;await ticks(30)
 check(scrap.freeze and scrap.global_transform.is_equal_approx(paused_transform),"pause freezes unregistered physical debris as well as actors")
 check(s.environment.clock == environment_time and not s.environment.is_processing(),"pause also stops environment and effect processing")
 check(inside(hud.modal_panel) and hud.modal_panel.size.y < s.size.y-30,"pause content fits and centers inside the viewport")
 hud.show_settings();await frames(5)
 check(NavigationManager.current_route == &"expedition" and is_instance_valid(hud.settings_overlay) and s.paused,"in-game settings preserve the live mission")
 s.handle_back();await frames(4)
 check(not is_instance_valid(hud.settings_overlay) and s.paused and hud.overlay == "pause","closing in-game settings returns to the paused scene")
 s.handle_back();await ticks(20)
 check(not s.paused and not scrap.freeze and s.environment.is_processing(),"resume restores body and process states")
 check(not s.enemy.enabled,"pause does not activate a future enemy encounter")
 s.open_radio_history();await frames(4)
 var old_elapsed: float = hud.dispatcher.elapsed;await frames(30)
 check(s.paused and hud.overlay == "radio" and is_equal_approx(old_elapsed,hud.dispatcher.elapsed),"reading history pauses both gameplay and transmission timing")
 s._resume_ui();await ticks(30)
 check(not s.paused and hud.overlay.is_empty(),"closing history restores game input")
 hud.crew.pressed.emit();await frames(3)
 check(is_instance_valid(hud.order_panel),"crew control opens explicit command choices")
 hud.order_selected.emit("Ко мне");check(Expedition.companion_order == "Ко мне","crew choice reaches the real companion controller")
 if is_instance_valid(hud.order_panel):hud.order_panel.queue_free();hud.order_panel = null
 check(Expedition.save_progress(),"radio journal and profile save together")
 var writes: int = Expedition.write_count;Expedition.save_progress();Expedition.save_progress()
 check(Expedition.write_count == writes,"unchanged navigation does not rewrite or rotate saves")
 var radio_count: int = Expedition.radio_log.size();Expedition.radio_log.clear();Expedition.load_progress()
 check(Expedition.radio_log.size() == radio_count,"radio history survives profile reload")
 var intact := ConfigFile.new();intact.load(Expedition.PATH);intact.save(Expedition.BACKUP)
 var invalid := ConfigFile.new();invalid.set_value("campaign","schema",99);invalid.save(Expedition.PATH)
 Expedition.load_progress();writes = Expedition.write_count
 check(not Expedition.notice.is_empty() and Expedition.radio_log.size() == radio_count and Expedition.save_progress() and Expedition.write_count == writes+1,"backup recovery repairs the primary save even when the recovered state has not changed")
 var repaired := ConfigFile.new();repaired.load(Expedition.PATH)
 check(Expedition._valid(repaired),"repaired campaign is a valid primary save")
 s._show_debrief("ПОТЕРЯ ОПОРЫ","Повторите подход с контрольной точки.",true);await frames(5)
 check(inside(hud.modal_panel) and hud.modal_panel.size.y < s.size.y-30,"failure report remains readable inside the viewport")
 await NavigationManager.go(&"home");await frames(5)
 for route: StringName in [&"operations",&"hangar",&"archive"]:
  await NavigationManager.go(route);await ticks(90)
  var screen = NavigationManager.current_screen
  check(screen.has_method("focus_initial") and inside(screen.get_node("Margin/Column/Header/Back")),"data screen has a usable header: "+str(route))
  if route == &"hangar":check(is_instance_valid(screen.preview_actor) and screen.preview_actor.parts.size() == 12 and screen.viewport.disable_3d,"hangar uses the actual 2D rig")
  await NavigationManager.go(&"home");await frames(5)
 check(is_equal_approx(Engine.time_scale,1) and errors.snapshot().is_empty(),"UI lifecycle leaves normal time with no script/runtime errors")
 print("UI09_RESULT ",JSON.stringify({"passed":passed,"failures":failures,"errors":errors.snapshot()}))
 AudioManager.shutdown();NavigationManager.current_screen = null;app.queue_free();await frames(4);get_tree().quit(0 if failures.is_empty() else 1)
