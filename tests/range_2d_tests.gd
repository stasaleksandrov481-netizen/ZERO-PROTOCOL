extends Node
var passed := 0
var failures: Array[String] = []
var metrics: Dictionary = {}
var strikes := 0
var points: Array[Vector2] = []
func _ready() -> void: call_deferred("run")
func ticks(count: int) -> void:
 for i in range(count): await get_tree().physics_frame
func frames(count: int) -> void:
 for i in range(count): await get_tree().process_frame
func check(ok: bool,label: String) -> void:
 if ok: passed += 1
 else: failures.append(label)
 print("PASS " if ok else "FAIL ",label)
func nodes_of(node: Node,kind: String) -> int:
 var count := 1 if node.is_class(kind) else 0
 for child in node.get_children(): count += nodes_of(child,kind)
 return count
func run() -> void:
 get_window().size = Vector2i(1280,720)
 var errors = NavigationManager.RangeErrors.new();OS.add_logger(errors)
 SettingsManager.reset_defaults();SettingsManager.set_value("video/reduced_motion",true)
 var app = load("res://scenes/menu/main_menu.tscn").instantiate();add_child(app)
 await frames(5);await NavigationManager.go(&"test")
 var s = NavigationManager.current_screen
 check(s.has_method("is_range_ready") and s.is_range_ready(),"Test button starts the genuine 2D range")
 if not s.has_method("is_range_ready") or not s.is_range_ready():get_tree().quit(1);return
 var r = s.robot;var d = s.dummy;var world = s.get_node("WorldView/World/Range")
 check(r is Node2D and r.core is RigidBody2D and d.torso is RigidBody2D,"both actors use native 2D rigid bodies")
 check(nodes_of(world,"Node3D") == 0,"no 3D nodes exist anywhere in the active arena")
 check(nodes_of(world,"Light2D") == 0,"there are no lights or cast shadows")
 check(nodes_of(r,"Sprite2D") == 11,"eleven independent painted parts can receive future local damage")
 check(s.camera is Camera2D and s.arena_view.disable_3d,"camera and viewport stay entirely 2D")
 check(s.left_stick.size.x >= 270 and s.left_stick.size == s.right_stick.size,"both joysticks are larger and identical in size")
 check(is_equal_approx(s.left_stick.global_position.y,s.right_stick.global_position.y),"joysticks share one horizontal baseline")
 check(is_equal_approx(s.left_stick.radius,s.right_stick.radius) and s.left_stick.radius > 100,"joysticks are equal true circles with a large touch radius")
 await ticks(240)
 check(r.core.position.y < -5.8*64 and absf(r.core.rotation) < .18,"2D body remains standing")
 check(r.core.linear_velocity.length() < 16,"standing does not slide or collapse")
 check(d.max_deflection < .04,"passive 2D mannequin stands still")
 var untouched: float = r.parts.LeftForearm.rotation-r.parts.LeftUpperArm.rotation
 s.right_stick.value = Vector2(1,0);await ticks(200)
 var straight: float = wrapf(r.parts.RightForearm.rotation-r.parts.RightUpperArm.rotation,-PI,PI)
 s.right_stick.value = Vector2(.25,-.3);await ticks(200)
 var folded: float = wrapf(r.parts.RightForearm.rotation-r.parts.RightUpperArm.rotation,-PI,PI)
 metrics["straight_elbow_rad"] = straight;metrics["folded_elbow_rad"] = folded
 check(absf(folded) > 1.8 and absf(folded-straight) > 1.1,"wrist position control visibly bends and straightens the elbow")
 var left_after: float = wrapf(r.parts.LeftForearm.rotation-r.parts.LeftUpperArm.rotation,-PI,PI)
 check(absf(left_after-untouched) < .35,"moving right hand does not command the left elbow")
 s._reset();await ticks(180)
 var left_point: Vector2 = s.left_stick.get_global_transform_with_canvas()*s.left_stick.origin
 var right_point: Vector2 = s.right_stick.get_global_transform_with_canvas()*s.right_stick.origin
 await touch(3,left_point,true);await touch(7,right_point,true);await ticks(180)
 print("TOUCH_2D ",s.left_stick.touch_index," ",s.right_stick.touch_index," viewport=",get_viewport().get_visible_rect()," points=",left_point," ",right_point)
 check(s.left_stick.touch_index == 3 and s.right_stick.touch_index == 7,"two fingers own the two sticks independently")
 var center_bend: float = wrapf(r.parts.RightForearm.rotation-r.parts.RightUpperArm.rotation,-PI,PI)
 check(absf(center_bend) > 2.1,"holding a stick at its center folds the arm instead of ignoring input")
 await touch(3,left_point,false)
 check(s.left_stick.touch_index == -1 and s.right_stick.touch_index == 7,"releasing left finger preserves right control")
 await touch(7,right_point,false)
 s._reset();await ticks(180)
 var start: float = r.core.position.x
 Input.action_press("future_move_right");await ticks(260);Input.action_release("future_move_right");await ticks(50)
 metrics["walk_right_pixels"] = r.core.position.x-start
 check(r.core.position.x-start > 3*64,"2D machine walks forward under physical forces")
 check(r.facing == 1 and r.get_meta("view_profile") == "strict_right_side_2d","walking never initiates a volumetric turn")
 r.strike.connect(func(p: Vector2,_strength: float) -> void: strikes += 1;points.append(p))
 s.left_stick.value = Vector2(-.6,.5);s.right_stick.value = Vector2(-.6,.5);await ticks(110)
 for i in range(3):
  s.left_stick.value = Vector2(.95,.15);s.right_stick.value = Vector2(.92,.38);await ticks(180)
  s.left_stick.value = Vector2(-.6,.5);s.right_stick.value = Vector2(-.6,.5);await ticks(130)
 metrics["strikes"] = strikes;metrics["dummy_deflection_rad"] = d.max_deflection
 metrics["strike_points"] = points.map(func(p: Vector2) -> String: return str(p))
 check(strikes > 0 and d.hit_count > 0,"2D fist contacts physically hit the mannequin")
 check(d.max_deflection > .005,"2D mannequin physically recoils")
 check(r.parts.LeftForearm.opponent_impulse < 4*64 and r.parts.RightForearm.opponent_impulse < 4*64,"hands withdraw freely after impacts")
 s._reset();await ticks(180)
 start = r.core.position.x
 Input.action_press("future_move_left");await ticks(200);Input.action_release("future_move_left")
 check(r.core.position.x-start < -2.5*64,"walking backward still works")
 check(r.facing == 1,"backward walking preserves the same strict side profile")
 for body in r.parts.values():
  check(not body.get_node("Visual/PaintedArmor").flip_h,"sprite "+String(body.name)+" never flips or turns")
 s._toggle_pause();var old: Transform2D = d.torso.global_transform;await ticks(30)
 check(d.torso.global_transform.is_equal_approx(old),"pause freezes the passive mannequin")
 s._reset();await ticks(180)
 check(not s.paused and d.hit_count == 0 and absf(r.core.position.x) < 30,"reset restores both 2D actors")
 r.stabilized = false;r.enabled = false
 r.core.apply_central_impulse(Vector2(180,-210)*64)
 r.core.apply_torque_impulse(60*64*64)
 var violation := 0.0
 var violations: Dictionary = {}
 for step in range(480):
  if step%100 == 0:
   for body in r.parts.values(): body.apply_torque_impulse((13.0 if step%200 == 0 else -13.0)*64*64)
  await get_tree().physics_frame
  for joint in r.get_node("Joints").get_children():
   var a = r.parts[joint.get_meta("parent_key")];var b = r.parts[joint.get_meta("child_key")]
   var angle = wrapf(b.rotation-a.rotation,-PI,PI)
   var excess = maxf(float(joint.get_meta("anatomical_lower"))-angle,angle-float(joint.get_meta("anatomical_upper")))
   violation = maxf(violation,excess)
   violations[String(joint.name)] = maxf(violations.get(String(joint.name),0.0),excess)
 metrics["fall_joint_violation_rad"] = violation
 metrics["fall_joint_details"] = violations
 check(violation < .22,"all 2D anatomical limits survive an unpowered fall")
 var finite := true
 for body in r.parts.values(): finite = finite and body.position.is_finite()
 check(finite,"falling keeps every 2D part finite")
 r.enabled = true;r.stabilized = true;s._reset();await ticks(240)
 check(r.core.position.y < -5.8*64 and absf(r.core.rotation) < .2,"reset recovers from a fall")
 NavigationManager.back();await frames(5)
 var baseline := int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT))
 for i in range(5):
  await NavigationManager.go(&"test");await frames(4);await NavigationManager.go(&"home");await frames(4)
 check(int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT)) <= baseline+2,"repeated range visits free their 2D worlds")
 OS.remove_logger(errors);check(errors.snapshot().is_empty(),"no engine or script errors")
 var result={"passed":passed,"failures":failures,"metrics":metrics,"errors":errors.snapshot(),"physical_android_tested":false}
 print("RANGE_2D_RESULT ",JSON.stringify(result))
 var f=FileAccess.open("user://range_2d_results.json",FileAccess.WRITE);f.store_string(JSON.stringify(result,"  "));f.close()
 AudioManager.shutdown();await get_tree().create_timer(.15).timeout
 get_tree().quit(0 if failures.is_empty() else 1)
func touch(id: int,point: Vector2,pressed: bool) -> void:
 var event := InputEventScreenTouch.new();event.index = id;event.position = point;event.pressed = pressed;Input.parse_input_event(event);await frames(2)
