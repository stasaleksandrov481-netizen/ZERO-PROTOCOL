extends Node
var passed := 0
var failed := 0
var app: Control
var jaw_contact := false
func _ready() -> void: call_deferred("_run")
func check(ok: bool,label: String) -> void:
 if ok: passed += 1;print("PASS ",label)
 else: failed += 1;print("FAIL ",label)
func ticks(n: int) -> void:
 for i in range(n): await get_tree().physics_frame
func frames(n: int = 5) -> void:
 for i in range(n): await get_tree().process_frame
func anchor_gap(enemy: RigidBody2D) -> float:
 var worst := 0.0
 for key: String in enemy.parts:
  if key == "Core": continue
  var limb = enemy.parts[key]
  worst = maxf(worst,(limb.limit_parent.global_transform*limb.anchor_parent).distance_to(limb.global_transform*limb.anchor_self))
 return worst
func finite_rig(enemy: RigidBody2D) -> bool:
 for part: RigidBody2D in enemy.parts.values():
  if not part.position.is_finite() or not part.linear_velocity.is_finite() or not is_finite(part.rotation): return false
 return true
func _run() -> void:
 var errors = NavigationManager.RangeErrors.new();OS.add_logger(errors)
 app = load("res://scenes/menu/main_menu.tscn").instantiate();add_child(app);app.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);await frames(25)
 await NavigationManager.go(&"test");await frames()
 var game = NavigationManager.current_screen;var world = game.get_node("WorldView/World/Range")
 var enemy = load("res://scripts/gameplay/klyk_2d.gd").new();enemy.position = Vector2(2500,-330);enemy.target = game.robot;enemy.ai_enabled = false;world.add_child(enemy)
 check(enemy.initialized and enemy.parts.size() == 10 and enemy.joints.size() == 9,"enemy is ten rigid bodies connected by nine real joints")
 var ids := {};var mass := 0.0
 for part: RigidBody2D in enemy.parts.values(): ids[part.get_rid()] = true;mass += part.mass
 check(ids.size() == 10 and is_equal_approx(mass,75),"independent solver bodies retain the full seventy-five ton mass")
 check(enemy.head_body != enemy and enemy.head_body.limit_parent == enemy,"head has its own mass and a constrained physical neck")
 var native_shapes := true
 for binding: Dictionary in enemy.collider_bindings:
  native_shapes = native_shapes and binding.collision.get_parent() == binding.body and binding.collision.shape is ConvexPolygonShape2D
 check(native_shapes,"each silhouette collides on its own moving physical body")
 check(not enemy.parts.NearArm.get_collision_exceptions().has(enemy.head_body),"arm and head retain collision instead of passing through each other")
 await ticks(360)
 print("RIG_STANCE angle=",enemy.rotation," gap=",anchor_gap(enemy))
 check(absf(enemy.rotation) < .18 and enemy.balance.state == "steady","powered ragdoll stands without collapsing or drifting")
 check(anchor_gap(enemy) < 8,"native joint anchors remain connected in stance")
 var base_angle: float = enemy.head_body.rotation-enemy.rotation;var peak_lag := 0.0;var peak_speed_difference := 0.0
 # A heavy 7.5-ton fist at 1000 px/s; no scripted head force or angle.
 enemy.apply_impulse(Vector2(7500,0),Vector2(0,45))
 for i in range(150):
  await ticks(1);peak_lag = maxf(peak_lag,absf(enemy.head_body.rotation-enemy.rotation-base_angle))
  peak_speed_difference = maxf(peak_speed_difference,enemy.head_body.linear_velocity.distance_to(enemy.linear_velocity))
 print("BELLY_INERTIA angle=",peak_lag," relative_speed=",peak_speed_difference)
 check(peak_lag > .025 and peak_speed_difference > 5,"a real belly impulse makes the head lag through the neck joint")
 await ticks(240)
 var head = enemy.head_body;var jaw := Vector2(-102,72)
 var jaw_start: float = enemy.to_local(head.global_transform*jaw).y
 var probe := RigidBody2D.new();probe.mass = 7.5;probe.gravity_scale = 0;probe.collision_layer = 2;probe.collision_mask = 4
 probe.contact_monitor = true;probe.max_contacts_reported = 12;probe.continuous_cd = RigidBody2D.CCD_MODE_CAST_SHAPE
 var collider := CollisionShape2D.new();var circle := CircleShape2D.new();circle.radius = 16;collider.shape = circle;probe.add_child(collider)
 probe.position = head.global_transform*jaw+Vector2(0,220);world.add_child(probe)
 probe.body_entered.connect(func(body: Node) -> void: if body == head: jaw_contact = true)
 probe.linear_velocity = Vector2(0,-750)
 var jaw_lift := 0.0;var peak_head_angle := 0.0
 for i in range(150):
  await ticks(1);jaw_lift = maxf(jaw_lift,jaw_start-enemy.to_local(head.global_transform*jaw).y)
  peak_head_angle = maxf(peak_head_angle,head.rotation-enemy.rotation)
 print("UPPERCUT contact=",jaw_contact," lift=",jaw_lift," head_angle=",peak_head_angle," gap=",anchor_gap(enemy))
 check(jaw_contact,"an upward physical fist really contacts the jaw collider")
 check(jaw_lift > 12 and peak_head_angle > .06,"native uppercut impulse lifts the jaw and head without a reaction animation")
 check(peak_head_angle <= .78 and anchor_gap(enemy) < 15,"neck stops keep the head attached during the uppercut")
 probe.queue_free();await ticks(300)
 check(absf(head.rotation-enemy.rotation) < .15,"neck muscles damp the physical oscillation back to stance")
 enemy.desired_speed = -135;enemy.behavior = "pursue";var start: float = enemy.position.x;var foot_min := INF;var foot_max := -INF;var plants := [0]
 enemy.planted.connect(func(_point: Vector2,_strength: float) -> void: plants[0] += 1)
 for i in range(480):
  await ticks(1);var x: float = enemy.parts.NearFoot.position.x-enemy.position.x;foot_min = minf(foot_min,x);foot_max = maxf(foot_max,x)
 print("RIG_WALK distance=",start-enemy.position.x," foot_range=",foot_max-foot_min," plants=",plants[0])
 check(enemy.position.x < start-300 and foot_max-foot_min > 90,"walking uses wide physical leg strides rather than a stationary sliding pose")
 check(plants[0] >= 2,"enemy water steps come from real foot-floor contacts")
 enemy.set_enabled(false);var frozen: Vector2 = head.position;await ticks(60)
 check(head.position.is_equal_approx(frozen) and enemy.parts.NearFoot.freeze,"freezing the creature stops every ragdoll body")
 enemy.desired_speed = 0;enemy.set_enabled(true);await ticks(240)
 check(finite_rig(enemy) and anchor_gap(enemy) < 12 and absf(enemy.linear_velocity.x) < 80,"unfreezing a moved ragdoll preserves anchors and stable momentum")
 enemy.set_enabled(false);enemy.reset_stance(Vector2(2500,-330));await ticks(3);enemy.set_enabled(true);await ticks(240)
 check(absf(enemy.position.x-2500) < 20 and anchor_gap(enemy) < 10,"repositioning resets every body and joint anchor together")
 enemy.set_physics_process(false);var original_y: float = enemy.position.y;var original_knee: float = enemy.parts.NearShin.rotation-enemy.parts.NearThigh.rotation;var knee_change := 0.0
 for i in range(600):
  await ticks(1);knee_change = maxf(knee_change,absf(enemy.parts.NearShin.rotation-enemy.parts.NearThigh.rotation-original_knee))
 print("UNPOWERED_RAGDOLL core=",enemy.position," angle=",enemy.rotation," knee_change=",knee_change," gap=",anchor_gap(enemy))
 check(enemy.position.y > original_y+35 and knee_change > .18,"without muscles gravity folds the real ragdoll and its limbs")
 check(finite_rig(enemy) and anchor_gap(enemy) < 20,"unpowered collapse keeps connected finite bodies")
 enemy.set_physics_process(true);enemy.balance.fall(signf(enemy.rotation));await ticks(1050)
 check(enemy.balance.state == "steady" and absf(enemy.rotation) < .30,"the same physical rig stands up after a genuine ragdoll collapse")
 enemy.queue_free();await NavigationManager.go(&"campaign");Expedition.new_campaign("Тест","Слоя",[[Vector2(.1,.3),Vector2(.6,.6)]],{});await NavigationManager.go(&"expedition");await ticks(700)
 game = NavigationManager.current_screen
 var min_player := 999;var max_kedr := -999
 for part: Node2D in game.robot.parts.values(): min_player = mini(min_player,game.robot.z_index+part.get_node("Visual").z_index)
 for part: Node2D in game.companion.parts.values(): max_kedr = maxi(max_kedr,game.companion.z_index+part.get_node("Visual").z_index)
 check(min_player > max_kedr,"the entire player is rendered in front of every companion part")
 var overlap: Vector2 = game.robot.core.global_position+Vector2(30,0)-game.companion.core.global_position
 game.companion.set_enabled(false)
 for part: RigidBody2D in game.companion.parts.values(): part.global_position += overlap
 game._companion_tick(.5)
 check(game.companion.modulate.a < .65 and is_equal_approx(game.robot.modulate.a,1),"overlapping Kedr recedes smoothly while the foreground player stays opaque")
 Expedition.mark_checkpoint("arrival");await NavigationManager.go(&"home");await NavigationManager.go(&"expedition");await frames()
 game = NavigationManager.current_screen;var cleared: bool = game.stage == "arrival" and not game.enemy.visible
 for part: RigidBody2D in game.enemy.parts.values(): cleared = cleared and part.collision_layer == 0 and part.collision_mask == 0
 check(cleared,"resuming a cleared route leaves no invisible ragdoll colliders on the path")
 await NavigationManager.go(&"home");AudioManager.shutdown();await frames()
 check(errors.snapshot().is_empty(),"zero unexpected script or engine errors")
 for item: Dictionary in errors.snapshot(): print("UNEXPECTED ",item)
 OS.remove_logger(errors);print("INERTIAL RIG RESULT ",passed," passed / ",failed," failed");get_tree().quit(1 if failed else 0)
