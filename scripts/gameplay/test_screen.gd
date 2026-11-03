extends Control
## Side-view empty test range with pointer ownership, mobile walking and pause-safe state.

const InputConfig = preload("res://scripts/input/input_scheme_settings.gd")
@export var route_id: StringName = &"test"
@export var training := true
var robot_spawn_x := 0.0

@onready var arena_view: SubViewport = $WorldView/World
@onready var camera: Camera2D = $WorldView/World/Range/Camera
var robot
var dummy
@onready var left_stick = $HUD/LeftStick
@onready var right_stick = $HUD/RightStick
@onready var speed_text: Label = $HUD/Top/Status
var paused := false
var mobile_walk := 0.0
var walking_touch := -1
var last_taps: Dictionary = {}
var mouse_hands: Array[bool] = [false,false]
var aim_point := Vector2.ZERO
var config: InputConfig
var suppress_touch_mouse := false
var initialized := false
var startup_stage := "Загрузка сцены полигона"
var startup_error := ""
const CAMERA_ZOOM := .62
const CAMERA_MIN := .45
const CAMERA_MAX := 1.12
const PLAYER_SCREEN_X := .41
var target_zoom := CAMERA_ZOOM
var free_touches: Dictionary = {}
var pinch_distance := 0.0
var pinch_zoom := CAMERA_ZOOM
var hit_feedback: Node2D
var pause_states: Array[Dictionary] = []
var history_was_paused := false
var paused_bodies: Array[Dictionary] = []
var paused_processes: Array[Dictionary] = []


func _ready() -> void:
 startup_stage = "Размещение управления"
 if not left_stick.has_method("release") or not right_stick.has_method("release"):
  startup_error = "Не загрузился скрипт управления руками: scripts/gameplay/virtual_hand_stick.gd"
  return
 resized.connect(_layout)
 get_viewport().size_changed.connect(_layout)
 _layout()
 call_deferred("_layout")
 startup_stage = "Сборка АТ-01"
 var builder_script: Script = load("res://scripts/models/at01_2d_builder.gd")
 if builder_script == null or not builder_script.can_instantiate():
  startup_error = "Не удалось загрузить сборку АТ-01: scripts/models/at01_2d_builder.gd"
  return
 var builder = builder_script.new()
 robot = builder.create(robot_spawn_x)
 if robot == null:
  if is_instance_valid(builder.get("robot")): builder.get("robot").free()
  startup_error = "Сборка АТ-01 не создала модель."
  return
 $WorldView/World/Range.add_child(robot)
 if not bool(robot.get("initialized")):
  startup_error = str(robot.get("startup_error"))
  if startup_error == "" or startup_error == "<null>": startup_error = "Контроллер АТ-01 не завершил запуск."
  return
 startup_stage = "Сборка манекена"
 var dummy_script: Script = load("res://scripts/gameplay/training_dummy_2d.gd")
 if dummy_script == null or not dummy_script.can_instantiate():
  startup_error = "Не загрузился scripts/gameplay/training_dummy_2d.gd"
  return
 if training:
  dummy = dummy_script.new()
  dummy.name = "TrainingDummy"
  dummy.position = Vector2(9.0*64.0,0)
  $WorldView/World/Range.add_child(dummy)
  if not bool(dummy.get("initialized")):
   startup_error = "Манекен не завершил сборку.";return
 startup_stage = "Подключение управления"
 config = SettingsManager.input_config()
 $HUD/Top/Back.pressed.connect(NavigationManager.back)
 $HUD/Top/Reset.pressed.connect(_reset)
 $HUD/Top/Pause.pressed.connect(_toggle_pause)
 $HUD/Top/Impulse.pressed.connect(_push)
 $HUD/Top/Balance.toggled.connect(func(value: bool) -> void:
  robot.stabilized = value
  AudioManager.play_ui())
 $HUD/Zoom/Out.pressed.connect(func() -> void: set_camera_zoom(target_zoom/1.14))
 $HUD/Zoom/Reset.pressed.connect(func() -> void: set_camera_zoom(CAMERA_ZOOM))
 $HUD/Zoom/In.pressed.connect(func() -> void: set_camera_zoom(target_zoom*1.14))
 SettingsManager.changed.connect(_setting_changed)
 robot.overload.connect($WorldView/World/Range/Sparks.burst)
 robot.overload.connect(func(_point: Vector2, strength: float) -> void: AudioManager.play_mechanical(strength,true))
 robot.footstep.connect(_footstep)
 robot.strike.connect(_strike)
 hit_feedback = load("res://scripts/gameplay/impact_feedback_2d.gd").new()
 hit_feedback.name = "ImpactFeedback"
 hit_feedback.camera = camera
 $WorldView/World/Range.add_child(hit_feedback)
 robot.impact.connect(func(point: Vector2,strength: float,direction: Vector2,_target: PhysicsBody2D) -> void:
  hit_feedback.hit(point,strength,direction))
 _apply_quality()
 AudioManager.set_test_active(true)
 if OS.has_feature("android"):
  $HUD/Help.text = "Двойной тап с удержанием — ходьба\nДжойстики — кулаки 360° · отпустить — опустить"
  if config.scheme == InputConfig.Scheme.TILT:
   $HUD/Help.text = "Наклон телефона — ходьба\nДжойстики — кулаки 360° · отпустить — опустить"
   if not config.sensor_available():
    $HUD/Help.text = "Датчик недоступен · Двойной тап с удержанием — ходьба\nДжойстики — кулаки 360° · отпустить — опустить"
 else:
  $HUD/Help.text = "A / D — ходьба · ЛКМ / ПКМ — кулаки\nДжойстик — кулак 360° · Колесо / + − — камера"
 $HUD.actor = robot
 $HUD.move_changed.connect(func(axis: float) -> void: mobile_walk = axis)
 $HUD.resume_requested.connect(_resume_ui)
 $HUD.restart_requested.connect(_restart_ui)
 $HUD.leave_requested.connect(_leave_ui)
 initialized = true
 startup_stage = "Готово"
 _update_camera(1.0,true)

func is_range_ready() -> bool:
 return initialized and is_instance_valid(robot) and bool(robot.get("initialized")) and robot.parts.size() >= 11 and (not training or (is_instance_valid(dummy) and bool(dummy.get("initialized"))))

func range_startup_details() -> Dictionary:
 return {"stage":startup_stage,"reason":startup_error,"initialized":initialized,
  "model_present":is_instance_valid(robot)}

func _layout() -> void:
 $WorldView.set_as_top_level(true)
 $WorldView.z_index = -5
 $WorldView.set_anchors_preset(Control.PRESET_TOP_LEFT)
 $WorldView.position = Vector2.ZERO
 $WorldView.size = get_viewport_rect().size
 $HUD.layout_hud()

func _physics_process(delta: float) -> void:
 if not initialized: return
 _update_camera(delta)
 if paused or NavigationManager.transitioning:
  robot.walk_axis = 0
  return
 var axis := Input.get_axis("future_move_left","future_move_right")
 if OS.has_feature("android") and config.scheme == InputConfig.Scheme.TILT and config.sensor_available():
  axis = config.sample_walk_axis()
 elif mobile_walk != 0: axis = mobile_walk
 robot.walk_axis = axis
 robot.hand_input[0] = left_stick.value
 robot.hand_input[1] = right_stick.value
 for index in range(2):
  robot.world_aim[index] = mouse_hands[index]
  var stick = left_stick if index == 0 else right_stick
  robot.hand_engaged[index] = stick.touch_index >= 0 or stick.mouse_active or mouse_hands[index]
  if mouse_hands[index]: robot.hand_world[index] = _mouse_world(aim_point)
 $HUD/Top/Status.text = "АТ-01  /  ГОРИЗОНТ  /  %.1f м/с" % (absf(robot.core.linear_velocity.x)/64.0)

func set_camera_zoom(value: float) -> void:
 target_zoom = clampf(value,CAMERA_MIN,CAMERA_MAX)
 $HUD/Zoom/Reset.text = "%d%%" % roundi(target_zoom/CAMERA_ZOOM*100)

func _update_camera(delta: float,snap: bool = false) -> void:
 var blend := 1.0 if snap else 1.0-exp(-delta*11.0)
 var view_size := Vector2(arena_view.size)
 var screen_factor := clampf(view_size.y/720.0,.5,2.0)
 var zoom_value := lerpf(camera.zoom.x,target_zoom*screen_factor,blend)
 camera.zoom = Vector2.ONE*zoom_value
 var x: float = 0.0 if robot.reset_cooldown > 0 else robot.core.position.x
 var goal := Vector2(x+view_size.x*(.5-PLAYER_SCREEN_X)/zoom_value,-view_size.y*.30/zoom_value)
 # At close inspection zoom, keep the cockpit in frame rather than centering the floor.
 var close := clampf((zoom_value/screen_factor-.88)/.24,0,1)
 goal.y = lerpf(goal.y,robot.core.position.y+1.1*64.0,close)
 camera.position = goal if snap else camera.position.lerp(goal,blend)
 camera.force_update_scroll()

func _pinch_update() -> void:
 if free_touches.size() < 2: return
 var points: Array = free_touches.values()
 var distance: float = points[0].distance_to(points[1])
 if pinch_distance <= 0:
  pinch_distance = maxf(distance,24.0);pinch_zoom = target_zoom
  mobile_walk = 0;walking_touch = -1;last_taps.clear()
 else: set_camera_zoom(pinch_zoom*distance/pinch_distance)

func _input(event: InputEvent) -> void:
 if not initialized or NavigationManager.current_route != route_id: return
 if event is InputEventScreenTouch:
  if not event.pressed:
   free_touches.erase(event.index)
   if free_touches.size() < 2: pinch_distance = 0
   if event.index == walking_touch: mobile_walk = 0;walking_touch = -1
  elif not _over_ui(event.position):
   free_touches[event.index] = event.position
   if free_touches.size() >= 2:
    _pinch_update();get_viewport().set_input_as_handled();return
   if not paused:
    if config.scheme == InputConfig.Scheme.TILT and config.sensor_available(): return
    var local: Vector2 = get_global_transform_with_canvas().affine_inverse()*event.position
    var direction := -1 if local.x < size.x*.5 else 1
    var now := Time.get_ticks_msec()
    if last_taps.has(direction) and now-int(last_taps[direction]) < 330:
     walking_touch = event.index;mobile_walk = float(direction)
    last_taps[direction] = now
    get_viewport().set_input_as_handled()
 elif event is InputEventScreenDrag and free_touches.has(event.index):
  free_touches[event.index] = event.position
  if free_touches.size() >= 2:
   _pinch_update();get_viewport().set_input_as_handled()
 elif event is InputEventMagnifyGesture and free_touches.size() < 2 and not _over_ui(event.position):
  set_camera_zoom(target_zoom*event.factor);get_viewport().set_input_as_handled()
 elif event is InputEventMouseButton:
  if event.pressed and event.button_index in [MOUSE_BUTTON_WHEEL_UP,MOUSE_BUTTON_WHEEL_DOWN] and not _over_ui(event.position):
   set_camera_zoom(target_zoom*(1.12 if event.button_index == MOUSE_BUTTON_WHEEL_UP else 1.0/1.12))
   get_viewport().set_input_as_handled()
  if not event.pressed:
   if event.button_index == MOUSE_BUTTON_LEFT: mouse_hands[0] = false
   if event.button_index == MOUSE_BUTTON_RIGHT: mouse_hands[1] = false

func _unhandled_input(event: InputEvent) -> void:
 if not initialized: return
 if paused or NavigationManager.current_route != route_id: return
 if not (event is InputEventMouseButton or event is InputEventMouseMotion): return
 if event is InputEventMouseButton and event.device != InputEvent.DEVICE_ID_EMULATION:
  if event.button_index not in [MOUSE_BUTTON_LEFT,MOUSE_BUTTON_RIGHT]: return
  var index := 0 if event.button_index == MOUSE_BUTTON_LEFT else 1
  if not event.pressed:
   mouse_hands[index] = false
  elif not _over_ui(event.position):
   mouse_hands[index] = true
   aim_point = event.position
 elif event is InputEventMouseMotion:
  aim_point = event.position
 get_viewport().set_input_as_handled()

func _over_ui(point: Vector2) -> bool:
 return $HUD.contains_pointer(point)

func _mouse_world(point: Vector2) -> Vector2:
 var local: Vector2 = $WorldView.get_global_transform_with_canvas().affine_inverse()*point
 var viewport_point: Vector2 = local/$WorldView.size*Vector2(arena_view.size)
 return arena_view.get_canvas_transform().affine_inverse()*viewport_point

func _reset() -> void:
 hit_feedback.cancel()
 if paused: _toggle_pause()
 _release_input()
 robot.reset_stance()
 if is_instance_valid(dummy): dummy.reset_stance()
 _update_camera(1.0,true)
 AudioManager.play_ui("confirm")

func _push() -> void:
 if paused: _toggle_pause()
 robot.core.apply_central_impulse(Vector2(160,-45)*64.0)
 AudioManager.play_ui()

func _toggle_pause() -> void:
 _set_paused(not paused)
 AudioManager.play_ui()
func _participants() -> Array:
 return [robot,dummy]
func _set_paused(value: bool,show_overlay: bool = true) -> void:
 if paused == value:
  if not value and show_overlay: $HUD.close_overlay()
  return
 if is_instance_valid(hit_feedback): hit_feedback.cancel()
 _release_input()
 if value:
  pause_states.clear();paused_bodies.clear();paused_processes.clear()
  _capture_simulation($WorldView/World/Range)
  for node in _participants():
   if not is_instance_valid(node): continue
   if node is RigidBody2D:
    pause_states.append({"node":node,"enabled":not node.freeze});node.freeze = true
   elif node.has_method("set_enabled"):
    pause_states.append({"node":node,"enabled":node.enabled});node.set_enabled(false)
  for entry: Dictionary in paused_bodies:
   if is_instance_valid(entry.node): entry.node.freeze = true
  for entry: Dictionary in paused_processes:
   if is_instance_valid(entry.node): entry.node.set_process(false);entry.node.set_physics_process(false)
 else:
  for entry: Dictionary in pause_states:
   if not is_instance_valid(entry.node): continue
   if entry.node is RigidBody2D: entry.node.freeze = not bool(entry.enabled)
   else: entry.node.set_enabled(bool(entry.enabled))
  for entry: Dictionary in paused_bodies:
   if is_instance_valid(entry.node): entry.node.freeze = entry.frozen
  for entry: Dictionary in paused_processes:
   if is_instance_valid(entry.node): entry.node.set_process(entry.process);entry.node.set_physics_process(entry.physics)
  pause_states.clear();paused_bodies.clear();paused_processes.clear()
 paused = value;$HUD.paused = value
 left_stick.active = not value;right_stick.active = not value
 $HUD.left_walk.disabled = value;$HUD.right_walk.disabled = value
 if show_overlay:
  if value: $HUD.show_pause()
  else: $HUD.close_overlay()
func _capture_simulation(node: Node) -> void:
 if node is RigidBody2D: paused_bodies.append({"node":node,"frozen":node.freeze})
 if node.get_script() != null: paused_processes.append({"node":node,"process":node.is_processing(),"physics":node.is_physics_processing()})
 for child in node.get_children(): _capture_simulation(child)
func _resume_ui() -> void:
 if $HUD.overlay == "radio" and history_was_paused:
  $HUD.show_pause();return
 _set_paused(false)
func _restart_ui() -> void: _reset()
func _leave_ui() -> void: NavigationManager.back()
func open_radio_history() -> void: pass
func handle_back() -> bool:
 if is_instance_valid($HUD.settings_overlay): $HUD.close_overlay();return true
 if is_instance_valid($HUD.order_panel): $HUD.order_panel.queue_free();$HUD.order_panel = null;return true
 if $HUD.overlay == "report": _leave_ui();return true
 if $HUD.overlay == "radio": _resume_ui();return true
 _toggle_pause();return true

func _release_input() -> void:
 left_stick.release()
 right_stick.release()
 $HUD.release_movement()
 mouse_hands = [false,false]
 mobile_walk = 0
 walking_touch = -1
 free_touches.clear();pinch_distance = 0;last_taps.clear()
 robot.walk_axis = 0
 robot.hand_input.assign([Vector2.ZERO,Vector2.ZERO])
 robot.world_aim.assign([false,false])
 robot.hand_engaged.assign([false,false])

func _setting_changed(key: StringName, _value: Variant) -> void:
 if String(key).begins_with("input/"): config = SettingsManager.input_config()
 if key == &"video/quality": _apply_quality()

func _apply_quality() -> void:
 pass # Sprite rendering stays unlit and shadow-free at every quality setting.

func _footstep(strength: float) -> void:
 AudioManager.play_mechanical(strength)

func _strike(point: Vector2, strength: float) -> void:
 if is_instance_valid(dummy): dummy.register_hit(point,strength)
 $WorldView/World/Range/Sparks.burst(point,strength)

func focus_initial() -> void:
 $HUD/Top/Back.grab_focus()

func _notification(what: int) -> void:
 if what == NOTIFICATION_APPLICATION_FOCUS_OUT or what == NOTIFICATION_APPLICATION_PAUSED:
  if initialized:
   _release_input()
   if not paused: _toggle_pause()

func _exit_tree() -> void:
 if is_instance_valid(hit_feedback): hit_feedback.cancel()
 AudioManager.set_test_active(false)
