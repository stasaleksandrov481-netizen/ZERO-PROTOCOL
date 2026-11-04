extends Node
## Reproduces the 0.11 endless-spin bug and checks physical collision silhouettes.
var passed := 0
var failed := 0
var app: Control
var probe_contact := false
class Errors extends Logger:
 var items: Array[String] = []
 func _log_error(_fn: String,file: String,line: int,code: String,reason: String,_notify: bool,kind: int,_traces: Array[ScriptBacktrace]) -> void:
  if kind != Logger.ERROR_TYPE_WARNING: items.append(file+":"+str(line)+" "+code+" "+reason)
func _ready() -> void: call_deferred("_run")
func check(ok: bool,label: String) -> void:
 if ok: passed += 1;print("PASS ",label)
 else: failed += 1;print("FAIL ",label)
func ticks(n: int) -> void:
 for i in range(n): await get_tree().physics_frame
func frames(n: int = 6) -> void:
 for i in range(n): await get_tree().process_frame
func occupied(body: PhysicsBody2D,point: Vector2) -> bool:
 var query := PhysicsPointQueryParameters2D.new();query.position = point;query.collision_mask = 4
 for hit: Dictionary in body.get_world_2d().direct_space_state.intersect_point(query):
  if hit.collider == body: return true
 return false
func _run() -> void:
 var errors := Errors.new();OS.add_logger(errors)
 app = load("res://scenes/menu/main_menu.tscn").instantiate();add_child(app);app.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);await frames(25)
 await NavigationManager.go(&"test");await frames()
 var game = NavigationManager.current_screen;var robot = game.robot
 await ticks(180)
 check(robot.total_mass > 90 and robot.total_mass < 95,"92-ton rig retains its physical mass")
 var silhouettes := true
 for part: Node in robot.parts.values(): silhouettes = silhouettes and part.get_node("Collision").shape is ConvexPolygonShape2D and part.get_node_or_null("FistCollision") == null
 check(silhouettes,"all 12 robot colliders follow armor silhouettes without oversized fist circles")
 var bounded := true
 for i in range(144):
  var angle := -float(i)*TAU/36.0
  game.right_stick.touch_index = 19;game.left_stick.touch_index = 20
  game.right_stick._update_value(game.right_stick.origin+Vector2(cos(angle),sin(angle))*game.right_stick.radius)
  game.left_stick._update_value(game.left_stick.origin+Vector2(cos(-angle),sin(-angle))*game.left_stick.radius)
  await ticks(4)
  for index in range(2): bounded = bounded and absf(robot.arm_goals[index].x) <= PI
 game.right_stick.release();game.left_stick.release();await ticks(600)
 var up = robot.parts.RightUpperArm;var low = robot.parts.RightForearm
 print("ARM_RELEASE_METRICS ",robot.arm_goals[1]," omega=",up.angular_velocity," / ",low.angular_velocity)
 check(bounded,"clockwise and counterclockwise gestures never accumulate full turns")
 check(absf(up.angular_velocity) < .35 and absf(low.angular_velocity) < .35,"released right arm settles without perpetual spin")
 check(absf(robot.parts.LeftUpperArm.angular_velocity) < .35 and absf(robot.parts.LeftForearm.angular_velocity) < .35,"released left arm also settles")
 check(robot.arm_speeds[0].length() < .1 and robot.arm_speeds[1].length() < .1,"no stored command velocity survives release")
 game.right_stick.touch_index = 21;game.right_stick._update_value(game.right_stick.origin+Vector2(60,-40));game.right_stick._notification(NOTIFICATION_APPLICATION_FOCUS_OUT)
 check(game.right_stick.value == Vector2.ZERO and game.right_stick.touch_index == -1,"focus loss releases owned stick input")
 var maximum_violation := 0.0
 for joint: PinJoint2D in robot.get_node("Joints").get_children():
  var a = robot.parts[joint.get_meta("parent_key")];var b = robot.parts[joint.get_meta("child_key")]
  var angle := wrapf(b.rotation-a.rotation,-PI,PI)
  maximum_violation = maxf(maximum_violation,maxf(float(joint.get_meta("anatomical_lower"))-angle,angle-float(joint.get_meta("anatomical_upper"))))
 check(maximum_violation < .08,"all joint angles remain inside mechanical limits after gestures")
 var start: float = robot.core.position.x
 Input.action_press("future_move_right");await ticks(12);var early_speed: float = absf(robot.core.linear_velocity.x)
 await ticks(170);var cruise_speed: float = absf(robot.core.linear_velocity.x)
 Input.action_release("future_move_right");await ticks(160)
 check(early_speed < cruise_speed*.6 and robot.core.position.x > start+60,"heavy locomotion builds momentum instead of snapping to full speed")
 check(absf(robot.core.linear_velocity.x) < 25,"heavy gait brakes to a stable stop")
 robot.enabled = false;robot.core.apply_central_impulse(Vector2(130,-160)*64);robot.parts.RightForearm.apply_torque_impulse(30*64*64)
 var fall_excess := 0.0
 for i in range(150):
  await ticks(1)
  for joint: PinJoint2D in robot.get_node("Joints").get_children():
   var a = robot.parts[joint.get_meta("parent_key")];var b = robot.parts[joint.get_meta("child_key")]
   var angle := wrapf(b.rotation-a.rotation,-PI,PI)
   fall_excess = maxf(fall_excess,maxf(float(joint.get_meta("anatomical_lower"))-angle,angle-float(joint.get_meta("anatomical_upper"))))
 check(fall_excess < .20,"mechanical stops survive an unpowered impact")
 var finite := true
 for part: Node2D in robot.parts.values(): finite = finite and part.position.is_finite() and part.linear_velocity.is_finite()
 check(finite,"unpowered fall keeps all body states finite")
 robot.enabled = true;robot.reset_stance();await ticks(240)
 check(absf(robot.core.rotation) < .2,"rig recovers to a stable stance after reset")
 var enemy = load("res://scripts/gameplay/klyk_2d.gd").new();enemy.position = Vector2(1800,-340);game.get_node("WorldView/World/Range").add_child(enemy);enemy.set_enabled(false);await ticks(3)
 check(enemy.collider_bindings.size() == 10,"enemy has separate head, torso and eight limb silhouettes")
 check(occupied(enemy,enemy.global_position+Vector2(-210,-105)),"visible front of enemy jaw has real collision")
 var matches := true
 for binding: Dictionary in enemy.collider_bindings:
  var points: PackedVector2Array = binding.collision.shape.points;var centre := Vector2.ZERO
  for point: Vector2 in points: centre += point
  centre /= points.size();matches = matches and occupied(enemy,binding.collision.global_transform*centre)
 check(matches,"all ten visible enemy parts have registered solver geometry")
 check(not occupied(enemy,enemy.global_position+Vector2(-350,-330)),"empty space outside the silhouette is not a giant blocking rectangle")
 var probe := RigidBody2D.new();probe.mass = 7.5;probe.gravity_scale = 0;probe.collision_layer = 2;probe.collision_mask = 4;probe.continuous_cd = RigidBody2D.CCD_MODE_CAST_SHAPE;probe.contact_monitor = true;probe.max_contacts_reported = 8
 var cs := CollisionShape2D.new();var circle := CircleShape2D.new();circle.radius = 20;cs.shape = circle;probe.add_child(cs);probe.position = enemy.position+Vector2(-520,-105)
 probe.body_entered.connect(func(body: Node) -> void: if body == enemy: probe_contact = true)
 game.get_node("WorldView/World/Range").add_child(probe);probe.linear_velocity = Vector2(1200,0);await ticks(150)
 check(probe_contact,"fast physical fist contacts the enemy jaw")
 check(probe.position.x < enemy.position.x-200,"CCD fist cannot tunnel through the jaw")
 probe.queue_free();enemy.target = robot;enemy.set_enabled(true);await ticks(80)
 var poses_match := true
 for binding: Dictionary in enemy.collider_bindings:
  var expected: Transform2D = binding.sprite.get_parent().global_transform*Transform2D(binding.sprite.rotation,binding.sprite.position)
  poses_match = poses_match and binding.collision.global_transform.is_equal_approx(expected)
 check(poses_match,"enemy limb colliders follow animated branches")
 enemy.queue_free()
 await NavigationManager.go(&"campaign");Expedition.new_campaign("Тест","Физики",[[Vector2(.1,.3),Vector2(.6,.6)]],{});await NavigationManager.go(&"expedition");await ticks(700)
 game = NavigationManager.current_screen;var sea = game.environment
 for viewport: Vector2i in [Vector2i(1280,720),Vector2i(1024,459)]:
  get_window().content_scale_size = viewport;get_window().size = viewport;await frames(12)
  var hud = game.get_node("HUD")
  hud.dispatcher.clear()
  var full := "Держите береговые огни справа. Ночь — время активности Искажённых. В доке получите доступ к сети баз. Контакт у подхода! Отведите руку, разгоните кулак и вложите массу."
  hud.dispatcher.enqueue("ЭХО / НИКА",full,0,"measure_"+str(viewport));await frames()
  var pages_fit := true;var collected: Array[String] = []
  while not hud.dispatcher.current.is_empty():
   collected.append(hud.dispatcher.current.body);await frames(2)
   pages_fit = pages_fit and hud.radio.body.position.y+hud.radio.body.get_minimum_size().y <= hud.radio.size.y-30
   hud.dispatcher.advance()
  check(pages_fit and " ".join(collected) == full,"radio pages fit measured text without losing words %s"%viewport)
  var inside: bool = hud.get_global_rect().encloses(hud.radio.get_global_rect()) and hud.radio.position.x > hud.size.x*.6
  check(inside,"active radio stays to the side and inside viewport %s"%viewport)
 var shader_source: String = sea.water.material.shader.code
 check(not shader_source.contains("screen_texture") and not shader_source.contains("SCREEN_UV"),"water is a flat 2D cross-section without screen refraction")
 sea.splashes.clear();sea.wakes.clear();sea.last_splashes.clear();sea.splash(900,.7)
 check(sea.splashes.size() >= 40,"ordinary footfall produces a broad spray")
 var fastest := 0.0
 for drop: Dictionary in sea.splashes: fastest = maxf(fastest,-drop.velocity.y)
 check(fastest > 280,"step spray has a visibly stronger upward impulse")
 sea.splash(1200,.7);check(sea.wakes.size() == 2,"two machines can splash in separate places on the same frame")
 for i in range(220): sea.splash(i*60,1)
 check(sea.splashes.size() <= sea.MAX_SPRAY and sea.wakes.size() <= 16,"water spray and surface disturbances remain bounded")
 sea.splashes.clear();sea.wakes.clear();sea.last_splashes.clear()
 var seen_weight := 0.0
 Input.action_press("future_move_right")
 for i in range(350):
  await ticks(1);seen_weight = maxf(seen_weight,game.hit_feedback.foot_weight)
 Input.action_release("future_move_right")
 check(not sea.wakes.is_empty(),"actual walking creates water disturbances from foot contacts")
 check(seen_weight > 0,"planted mass drives a small camera response")
 SettingsManager.set_value(&"video/reduced_motion",true);game.hit_feedback.step_weight(1);await frames()
 check(game.camera.offset == Vector2.ZERO,"reduced motion removes footfall camera movement")
 game._set_paused(true,false);var water_clock: float = sea.clock;await ticks(20)
 check(sea.clock == water_clock,"pause freezes the new 2D water")
 game._set_paused(false);SettingsManager.set_value(&"video/reduced_motion",false)
 SettingsManager.set_value(&"video/reduced_motion",true)
 await NavigationManager.go(&"settings");await NavigationManager.go(&"campaign");await frames()
 check(NavigationManager.current_route == &"campaign","rapid reduced-motion navigation tolerates stale deferred focus")
 SettingsManager.set_value(&"video/reduced_motion",false)
 await NavigationManager.go(&"home");AudioManager.shutdown();await frames()
 check(errors.items.is_empty(),"zero engine and script errors in physics regression run")
 for item: String in errors.items: print("UNEXPECTED ",item)
 OS.remove_logger(errors);print("PHYSICS REGRESSION RESULT ",passed," passed / ",failed," failed");get_tree().quit(1 if failed else 0)
