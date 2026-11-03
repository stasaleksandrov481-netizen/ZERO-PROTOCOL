extends "res://scripts/gameplay/test_screen.gd"
const Builder = preload("res://scripts/models/at01_2d_builder.gd")
var environment: Node2D
var companion: Node2D
var enemy: RigidBody2D
var integrity := 100.0
var elapsed := 0.0
var stage := "road"
var objective: Label
var interact: Button
var debrief: Control
var mission_ready := false
var chatter: Dictionary = {}
var route: Dictionary
var route_end := 4800.0
var landing_time := 0.0
var landing := false
var landing_poses: Dictionary = {}
var companion_poses: Dictionary = {}
var order_clock := 0.0
var retrying := false
func _ready() -> void:
 route = Expedition.active_route();stage = Expedition.checkpoint;route_id = &"expedition";training = false
 landing = route.get("id","") == "DROP" and stage == "landing"
 var starts := {"landing":0.0,"dock":0.0,"road":0.0,"barrier":1800.0,"fight":2800.0,"arrival":4100.0,"mayak":4100.0,"base":4100.0}
 robot_spawn_x = float(starts.get(stage,0.0))
 if landing: target_zoom = .45
 super._ready()
 if not initialized: return
 var world := $WorldView/World/Range
 world.get_node("Backdrop").hide();world.get_node("Floor/GraySlab").hide();world.get_node("Floor/TopEdge").hide()
 environment = load("res://scripts/gameplay/coastal_environment.gd").new();environment.camera = camera;environment.biome = str(route.get("biome","sea"));environment.route_end = route_end;world.add_child(environment)
 companion = Builder.new().create(robot_spawn_x-390);companion.name = "Kedr";world.add_child(companion);companion.modulate = Color(.74,.86,.96);companion.set_meta("callsign","КЕДР / АТ-02")
 companion.footstep.connect(func(strength: float) -> void:
  if not landing: environment.splash(companion.core.position.x,strength*.65))
 companion.impact.connect(func(_point: Vector2,strength: float,_direction: Vector2,target_body: PhysicsBody2D) -> void:
  if target_body == enemy and is_instance_valid(enemy): enemy.register_hit(strength,true))
 enemy = load("res://scripts/gameplay/klyk_2d.gd").new();enemy.name = "Klyk";enemy.position = Vector2(3470,-255);enemy.target = robot;world.add_child(enemy)
 enemy.set_enabled(stage == "fight");enemy.landed.connect(_enemy_landed);enemy.defeated.connect(_enemy_defeated)
 if stage in ["arrival","mayak","base"]: enemy.state = "dead";enemy.hide();enemy.collision_layer = 0
 _boundaries(world)
 $HUD/Top/Back.pressed.disconnect(NavigationManager.back);$HUD/Top/Back.pressed.connect(_to_map)
 $HUD/Top/Crew.pressed.connect(func() -> void: $HUD.show_orders(Expedition.companion_order));$HUD.order_selected.connect(_set_order)
 $HUD.configure_mission();objective = $HUD.objective;interact = $HUD.interact;interact.pressed.connect(_interact);interact.hide()
 $HUD/Title.text = "МОРСКАЯ ВЫСАДКА / 01" if route.get("id","") == "DROP" else str(route.name).to_upper()+" / "+str(route.id)
 $HUD/Help.text = "";$HUD.dispatcher.message_started.connect(func(message: Dictionary) -> void: Expedition.record_radio(message,elapsed))
 robot.impact.connect(_on_impact)
 AudioManager.set_expedition_active(true)
 if landing:
  robot.set_enabled(false);companion.set_enabled(false);left_stick.active = false;right_stick.active = false
  for key: String in robot.parts: landing_poses[key] = robot.parts[key].transform
  for key: String in companion.parts: companion_poses[key] = companion.parts[key].transform
  environment.landing_phase = 0.0
  _radio("ЭХО / НИКА","Первый, Кедр. Точка сброса подтверждена. Под вами внешняя отмель ДОК-17. Отцепление.",2)
 else:
  _radio("КЕДР / ДАНИИЛ","Кедр на связи. Иду на своей машине рядом. Путь на "+str(Expedition.NODES[str(route.to)].name)+" выбран тобой; держимся этой линии.")
 mission_ready = true;_mission_layout()
func _boundaries(world: Node2D) -> void:
 for x: float in [-600.0,route_end+260]:
  var body := StaticBody2D.new();body.collision_layer = 1;body.position = Vector2(x,-800);world.add_child(body)
  var collision := CollisionShape2D.new();var box := RectangleShape2D.new();box.size = Vector2(48,2200);collision.shape = box;body.add_child(collision)
func _update_camera(delta: float,snap: bool = false) -> void:
 super._update_camera(delta,snap)
 if landing:
  camera.position.y = -610;camera.force_update_scroll()
func _mission_layout() -> void: $HUD.layout_hud()
func _physics_process(delta: float) -> void:
 super._physics_process(delta)
 if not mission_ready or paused or is_instance_valid(debrief) or NavigationManager.transitioning: return
 elapsed += delta
 if landing:
  landing_time += delta;var t := clampf((landing_time-1.8)/2.6,0,1)
  var offset_y := lerpf(-450,0,t*t)
  for key: String in landing_poses:
   var pose: Transform2D = landing_poses[key];pose.origin.y += offset_y;robot.parts[key].transform = pose
  for key: String in companion_poses:
   var pose: Transform2D = companion_poses[key];pose.origin.y += lerpf(-510,0,clampf((landing_time-2.1)/2.6,0,1)**2);companion.parts[key].transform = pose
  environment.landing_phase = clampf(landing_time/7,0,.99);environment.helicopter_x = robot_spawn_x-150+maxf(0,landing_time-4)*220;environment.helicopter_y = -1120-maxf(0,landing_time-4)*100
  objective.text = "ВЫСАДКА НА ВНЕШНЮЮ ОТМЕЛЬ";$HUD.objective_meta.text = "ВОЗДУШНЫЙ КОНВОЙ / ОТЦЕПЛЕНИЕ"
  if landing_time > 4.5 and not chatter.has("splash"):
   chatter.splash = true;environment.splash(robot.core.position.x,1.0);environment.splash(companion.core.position.x,1.0);hit_feedback.hit(Vector2(0,-140),.7,Vector2.DOWN)
  if landing_time >= 5.2:
   landing = false;environment.landing_phase = 1;set_camera_zoom(CAMERA_ZOOM);robot.set_enabled(true);companion.set_enabled(true);left_stick.active = true;right_stick.active = true
   Expedition.mark_checkpoint("road");stage = "road"
   _radio("КЕДР / ДАНИИЛ","Посадка есть. Я слева от тебя, на АТ-02. Проверь обе руки. Впереди огни ДОК-17 — идём к ним.")
  return
 var x: float = robot.core.position.x
 $HUD.health = integrity;$HUD.convoy = 100
 $HUD.progress.value = x;$HUD.progress.max_value = route_end
 $HUD.objective_meta.text = "%s / ДО ДОКА %d М"%[str(route.to),ceili(maxf(0,route_end-120-x)/64.0)]
 if x > 600 and not chatter.has("first_walk"):
  chatter.first_walk = true;_radio("ЭХО / НИКА","Держите береговые огни справа. Ночь — время активности Искажённых. В доке получите доступ к сети баз.")
 if x > 2600 and stage not in ["arrival","mayak","base"]:
  if not chatter.has("contact"):
   chatter.contact = true;stage = "fight";enemy.set_enabled(true);Expedition.mark_checkpoint("fight");_radio("КЕДР / ДАНИИЛ","Контакт у подхода! Не бей одними короткими толчками: отведи руку, разгони кулак и вложи массу. Я прикрою.",3)
 if stage in ["arrival","mayak","base"]:
  objective.text = "ЗАЙМИТЕ ДОК «%s»"%str(Expedition.NODES[str(route.to)].name)
  interact.visible = x > route_end-410 and x < route_end+170;interact.text = "СТЫКОВКА / "+str(route.to)
 elif stage == "fight": objective.text = "ОЧИСТИТЕ ПОДХОД К БЕРЕГУ"
 else: objective.text = "ДОЙДИТЕ ДО БЕРЕГОВОГО ДОКА" if environment.biome == "sea" else "ДОЙДИТЕ ДО ДОКА «%s»"%str(Expedition.NODES[str(route.to)].name)
 _companion_tick(delta)
 if robot.core.position.y > 80 or integrity <= 0: _failure("МАШИНА ПОВРЕЖДЕНА")
func _companion_tick(delta: float) -> void:
 if not is_instance_valid(companion): return
 order_clock += delta
 var goal: float = robot.core.position.x-340
 if Expedition.companion_order == "Атакуй" and is_instance_valid(enemy) and enemy.enabled: goal = enemy.position.x-180
 var dx: float = goal-companion.core.position.x
 companion.walk_axis = clampf(dx/110,-1,1) if absf(dx) > 60 else 0
 if is_instance_valid(enemy) and enemy.enabled and absf(enemy.position.x-companion.core.position.x) < 430 and Expedition.companion_order != "Ко мне":
  var phase := order_clock*2.1
  companion.hand_input[1] = Vector2(cos(phase),sin(phase))*.94;companion.hand_engaged[1] = true
 else: companion.hand_input[1] = Vector2.ZERO;companion.hand_engaged[1] = false
func _on_impact(_point: Vector2,strength: float,_direction: Vector2,target_body: PhysicsBody2D) -> void:
 if target_body == enemy and is_instance_valid(enemy): enemy.register_hit(strength)
func _enemy_landed(strength: float) -> void:
 if paused or landing: return
 integrity = maxf(0,integrity-strength*55);robot.core.set_meta("integrity",integrity)
 hit_feedback.hit(robot.core.position,strength*1.7,Vector2.LEFT)
 if environment.biome == "sea": environment.splash(robot.core.position.x,.65)
func _enemy_defeated() -> void:
 stage = "arrival";Expedition.mark_checkpoint("arrival");_radio("КЕДР / ДАНИИЛ","Чисто. Хорошая работа, Первый. Подходим к доку — там решим, куда дальше.",2)
func _radio(speaker: String,text: String,priority: int = 0) -> void: $HUD.dispatcher.enqueue(speaker,text,priority)
func _footstep(strength: float) -> void:
 super._footstep(strength)
 if is_instance_valid(environment) and not landing: environment.splash(robot.core.position.x,strength)
func _interact() -> void:
 if is_instance_valid(debrief) or not interact.visible: return
 _release_input()
 if not Expedition.arrive(): NavigationManager.toast(Expedition.last_error);return
 _set_paused(true,false)
 var base_name: String = Expedition.NODES[Expedition.current_base].name
 var text := "Вы в «%s». Машина зафиксирована. Откройте карту и выберите любую связанную соседнюю базу. Можно возвращаться по пройденным путям."%base_name
 debrief = $HUD.show_report("СТЫКОВКА ПОДТВЕРЖДЕНА",text,false)
func _failure(message: String) -> void:
 if is_instance_valid(debrief): return
 _set_paused(true,false);debrief = $HUD.show_report(message,"Возврат к последней безопасной контрольной точке восстановит машину.",true)
func _participants() -> Array: return [robot,dummy,companion,enemy]
func _restart_ui() -> void:
 if retrying: return
 retrying = true
 await NavigationManager.go(&"campaign");await NavigationManager.go(&"expedition")
func _leave_ui() -> void: _to_map()
func _to_map() -> void:
 if is_instance_valid(hit_feedback): hit_feedback.cancel()
 if Expedition.save_progress(): NavigationManager.go(&"campaign")
func _set_order(value: String) -> void:
 Expedition.companion_order = value;Expedition.save_progress();$HUD/Top/Crew.text = "КЕДР / "+value.to_upper()
 _radio("КЕДР / ДАНИИЛ",{"Прикрывай":"Прикрою подход.","Атакуй":"Отвлеку его. Последний удар за тобой.","Ко мне":"Иду к тебе."}.get(value,"Принял."))
func open_radio_history() -> void:
 history_was_paused = paused;_set_paused(true,false);$HUD.show_history(Expedition.radio_log)
func is_range_ready() -> bool:
 return super.is_range_ready() and mission_ready and is_instance_valid(companion) and is_instance_valid(environment)
func _exit_tree() -> void:
 super._exit_tree()
 if Expedition.started: Expedition.save_progress()
