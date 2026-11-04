extends Node
## Run with an isolated XDG_DATA_HOME. Covers behavior, persistence and native physics.
var passed := 0
var failed := 0
var app: Control
var runtime_errors: Logger
class ErrorCollector extends Logger:
 var errors: Array[String] = []
 func _log_error(_function: String,file: String,line: int,code: String,rationale: String,_editor_notify: bool,error_type: int,_backtraces: Array[ScriptBacktrace]) -> void:
  if error_type != Logger.ERROR_TYPE_WARNING: errors.append(file+":"+str(line)+" "+code+" "+rationale)

func _ready() -> void: call_deferred("_run")
func check(condition: bool,label_value: String) -> void:
 if condition: passed += 1;print("PASS ",label_value)
 else: failed += 1;push_error("FAIL "+label_value)
func frames(count: int = 5) -> void:
 for i in range(count): await get_tree().process_frame
func physics_frames(count: int) -> void:
 for i in range(count): await get_tree().physics_frame
func go(route: StringName) -> void: await NavigationManager.go(route);await frames()
func _run() -> void:
 runtime_errors = ErrorCollector.new();OS.add_logger(runtime_errors)
 app = load("res://scenes/menu/main_menu.tscn").instantiate();add_child(app);app.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);await frames(25)
 check(NavigationManager.current_route == &"home","main menu loads")
 # Real 0.9 files, including both in-progress and paid-completion migration.
 var legacy := ConfigFile.new()
 for key: String in ["schema","started","completed","pilot","base","checkpoint","credits","alloy","coolants","visited","flags","radio"]:
  legacy.set_value("campaign",key,{"schema":1,"started":true,"completed":false,"pilot":"Архивный пилот","base":"A01","checkpoint":"fight","credits":777,"alloy":0,"coolants":0,"visited":["A01"],"flags":{},"radio":[]}[key])
 legacy.save(Expedition.PATH);Expedition.load_progress()
 check(Expedition.flags.get("ROUTE_ACTIVE",false) and Expedition.checkpoint == "fight" and Expedition.active_route().to == "A02","in-progress 0.9 file migrates without losing trip")
 legacy.set_value("campaign","completed",true);legacy.set_value("campaign","base","A02");legacy.set_value("campaign","checkpoint","mayak");legacy.save(Expedition.PATH);Expedition.load_progress()
 check(Expedition.checkpoint == "base" and Expedition.flags.get("REWARD_R01",false) and Expedition.credits == 777,"paid 0.9 completion becomes free-travel base without duplicate reward")
 var invalid := ConfigFile.new();invalid.parse(legacy.encode_to_text());invalid.set_value("map","pan",Vector2(INF,0));check(not Expedition._valid(invalid),"corrupt nonfinite map coordinates rejected")
 var old := Expedition.snapshot()
 await go(&"campaign")
 check(NavigationManager.current_screen.graph_buttons.size() == 11,"only region-I outposts instantiated")
 check(Expedition.NODES.size() == 11 and Expedition.MAP_LINKS.size() == 17,"11 outposts and 17 routes")
 for edge: Array in Expedition.MAP_LINKS:
  var forward: Dictionary = Expedition.route_between(edge[0],edge[1]);var back: Dictionary = Expedition.route_between(edge[1],edge[0])
  check(forward.id == back.id and forward.from == back.to and forward.biome in ["sea","city","bridge"],"bidirectional "+str(edge[2]))
 await go(&"enlistment")
 var flow = NavigationManager.current_screen
 flow.form_first.text = "";flow.form_family.text = "";flow._identity_next();check(flow.step == 0,"empty identity blocked")
 flow.form_first.text = "123";flow.form_family.text = "456";flow._identity_next();check(flow.step == 0,"non-name identity blocked")
 flow.form_first.text = "Стас";flow.form_family.text = "Александров";flow._identity_next();await frames()
 check(flow.step == 1 and flow.next_button.disabled,"unsigned contract blocked")
 flow._sign_next();check(flow.step == 1,"direct continue cannot bypass signature")
 check(Expedition.snapshot() == old,"onboarding does not replace existing campaign early")
 var pad = flow.signature_pad
 var touch := InputEventScreenTouch.new();touch.index = 8;touch.pressed = true;touch.position = Vector2(40,40);pad._gui_input(touch)
 var drag := InputEventScreenDrag.new();drag.index = 9;drag.position = Vector2(95,90);pad._gui_input(drag)
 check(pad.length_drawn == 0,"other finger cannot draw into owned signature")
 drag.index = 8
 for i in range(15): drag.position = Vector2(40+i*8,40+sin(i*.8)*20);pad._gui_input(drag)
 touch.pressed = false;pad._gui_input(touch)
 check(not flow.next_button.disabled and pad.length_drawn > 8,"freehand signature enables continue")
 pad.clear_signature();check(flow.next_button.disabled,"clear removes consent")
 pad._start(Vector2(40,50));pad._append(Vector2(110,70));pad._append(Vector2(170,45));pad.drawing = false
 flow._sign_next();await frames()
 check(flow.step == 2 and flow.dialogue_index == 0,"contract opens protected briefing")
 for i in range(5): flow._answer(i%2);await frames()
 await frames(15)
 check(NavigationManager.current_route == &"expedition","briefing enters sea mission")
 var game = NavigationManager.current_screen
 check(game.is_range_ready(),"full expedition initialized")
 check(game.landing and game.environment.biome == "sea","first mission is aerial sea landing")
 check(game.robot.parts.size() == 12 and game.companion.parts.size() == 12,"two independent articulated Atlants")
 check(Expedition.pilot_name == "Стас Александров" and Expedition.flags.CONTRACT_SIGNED,"identity and consent saved")
 check(Expedition.flags.INTRO_CHOICES.size() == 5,"all dialogue choices retained")
 Expedition.load_progress();check(Expedition.flags.SIGNATURE.size() > 0,"signature survives reload")
 await get_tree().create_timer(5.5).timeout
 check(not game.landing and game.robot.enabled,"landing returns controls")
 check(game.environment.water != null and game.environment.water.material != null,"live refracting water layer")
 check(game.target_zoom <= game.CAMERA_ZOOM and game.camera.zoom.x/(float(game.arena_view.size.y)/720.0) < .64,"default camera remains pulled back")
 var start_x: float = game.robot.core.position.x
 Input.action_press("future_move_right");await physics_frames(250);Input.action_release("future_move_right");await physics_frames(12)
 check(game.robot.core.position.x > start_x+80,"native walking advances along sea bed")
 check(absf(game.robot.core.rotation) < .8,"walking keeps the machine upright")
 var left = game.left_stick;var right = game.right_stick
 var a := InputEventScreenTouch.new();a.pressed = true;a.index = 11;a.position = left.get_global_transform_with_canvas()*(left.origin+Vector2(30,-30));left._input(a)
 var b := InputEventScreenTouch.new();b.pressed = true;b.index = 12;b.position = right.get_global_transform_with_canvas()*(right.origin+Vector2(-30,-30));right._input(b)
 check(left.touch_index == 11 and right.touch_index == 12 and left.value != right.value,"two simultaneous hands own different fingers")
 left.release();right.release()
 game._set_paused(true);var frozen: Vector2 = game.robot.core.position;var water_clock: float = game.environment.clock;await physics_frames(20)
 check(game.robot.core.position.distance_to(frozen) < .01 and game.environment.clock == water_clock,"pause freezes physics and water")
 game.get_node("HUD").show_settings();await frames();check(game.get_node("HUD").settings_overlay.is_visible_in_tree(),"settings visible over paused game")
 game.get_node("HUD").close_overlay();game._set_paused(false);await physics_frames(4);check(game.robot.enabled,"resume restores actor")
 for i in range(220): game.environment.splash(float(i),1)
 check(game.environment.splashes.size() <= 160 and game.environment.wakes.size() <= 16,"water effects have fixed particle limits")
 # Exercise the real collision -> impact signal -> hostile damage path.
 var shift: float = 3250-game.robot.core.position.x
 for body in game.robot.parts.values(): body.position.x += shift
 game.enemy.set_enabled(true);game.stage = "fight"
 right.touch_index = 12
 for i in range(1600):
  if game.enemy.state == "dead": break
  var angle := float(i)*.025
  right._update_value(right.origin+Vector2(cos(angle),sin(angle))*right.radius)
  await get_tree().physics_frame
 right.release()
 check(game.enemy.health <= 0,"physical fist combat defeats the hostile")
 check(game.stage == "arrival","real victory opens docking objective")
 print("COMBAT HEALTH ",game.enemy.health," PLAYER ",game.integrity)
 await go(&"campaign")
 check(Expedition.arrive(),"initial sea docking commits")
 var first_balance := Expedition.credits
 check(Expedition.current_base == "A01" and Expedition.can_depart("A02") and Expedition.can_depart("A03"),"two initial routes freely available")
 check(not Expedition.can_depart("A11") and not Expedition.can_depart("REGION_II"),"nonadjacent and fogged routes blocked")
 check(Expedition.depart("A02"),"choose maritime branch")
 check(not Expedition.can_depart("A03"),"cannot begin second trip while travelling")
 Expedition.mark_checkpoint("fight");Expedition.load_progress()
 check(Expedition.active_route().to == "A02" and Expedition.checkpoint == "fight","chosen route and checkpoint survive reload")
 Expedition.arrive();var paid := Expedition.credits
 check(Expedition.current_base == "A02" and paid > first_balance,"arrival uses selected base and pays once")
 Expedition.arrive();check(Expedition.credits == paid,"repeat completion cannot pay twice")
 check(Expedition.depart("A01"),"return along the same connection")
 Expedition.arrive();check(Expedition.credits == paid,"reverse trip cannot duplicate first-clear reward")
 check(Expedition.depart("A03") and Expedition.active_route().biome == "city","alternative city branch launches")
 Expedition.arrive();Expedition.depart("A04");Expedition.arrive();Expedition.depart("A02");Expedition.arrive()
 check(Expedition.depart("A04") and Expedition.active_route().biome == "bridge","bridge branch launches")
 Expedition.arrive();await go(&"campaign")
 check(NavigationManager.current_screen.graph_buttons.size() == 11,"future regions remain fogged after travel")
 await go(&"operations");await frames(5);await go(&"archive");await frames(5)
 await go(&"hangar");await frames(5);check(NavigationManager.current_screen.preview_actor.parts.has("Head"),"hangar has separate cockpit inspection")
 await go(&"home")
 AudioManager.shutdown();await frames(8)
 check(runtime_errors.errors.is_empty(),"zero engine or script errors during the run")
 for error in runtime_errors.errors: print("RUNTIME ERROR ",error)
 OS.remove_logger(runtime_errors)
 print("NIGHTFALL RESULT ",passed," passed / ",failed," failed")
 get_tree().quit(1 if failed else 0)
