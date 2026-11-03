extends Node
var failures: Array[String] = []
var passed := 0
var metrics: Dictionary = {}
var strikes := 0
var strike_points: Array[Vector3] = []
func _ready() -> void: call_deferred("run")
func ticks(count: int) -> void:
 for i in range(count): await get_tree().physics_frame
func check(ok: bool, label: String) -> void:
 if ok: passed += 1
 else: failures.append(label)
 print("PASS " if ok else "FAIL ",label)
func run() -> void:
 var errors = NavigationManager.RangeErrors.new()
 OS.add_logger(errors)
 SettingsManager.reset_defaults()
 SettingsManager.set_value("video/reduced_motion",true)
 var app = load("res://scenes/menu/main_menu.tscn").instantiate()
 add_child(app)
 for i in range(5): await get_tree().process_frame
 await NavigationManager.go(&"test")
 var s = NavigationManager.current_screen
 var r = s.robot
 var d = s.dummy
 r.strike.connect(func(p: Vector3,_strength: float) -> void: strikes += 1;strike_points.append(p))
 await ticks(180)
 check(d.initialized and d.parts.size() == 6,"passive mannequin has six real movable body sections")
 check(d.max_deflection < .05,"mannequin stands still without attacks or locomotion")
 check(r.total_mass > 90 and r.parts.RightForearm.mass > 7,"arms have real additional mass and compound inertia")
 var before: float = r.parts.LeftUpperArm.rotation.z
 s.left_stick.value = Vector2(1,-.5)
 await ticks(3)
 var early: float = absf(r.parts.LeftUpperArm.rotation.z-before)
 await ticks(21)
 var after_200: float = absf(r.parts.LeftUpperArm.rotation.z-before)
 await ticks(156)
 var after_1500: float = absf(r.parts.LeftUpperArm.rotation.z-before)
 metrics["arm_motion_25ms_rad"] = early
 metrics["arm_motion_200ms_rad"] = after_200
 metrics["arm_motion_1500ms_rad"] = after_1500
 check(early < .035 and after_200 < .30,"arm accelerates instead of snapping to the joystick")
 check(after_1500 > .9,"heavy arm remains responsive and completes the requested swing")
 var no_self := true
 for part in r.parts.values(): no_self = no_self and (part.collision_mask & 2) == 0
 check(no_self,"player parts cannot snag on the player's own limbs")
 s._reset()
 await ticks(180)
 Input.action_press("future_move_right")
 await ticks(230)
 Input.action_release("future_move_right")
 await ticks(80)
 metrics["attack_start_x"] = r.core.position.x
 s.left_stick.value = Vector2(-.6,.6)
 s.right_stick.value = Vector2(-.7,.5)
 await ticks(110)
 for hit in range(3):
  s.left_stick.value = Vector2(1,.38)
  s.right_stick.value = Vector2(1,.10)
  await ticks(190)
  s.left_stick.value = Vector2(-.8,.3)
  s.right_stick.value = Vector2(-.7,.5)
  await ticks(140)
 metrics["strikes"] = strikes
 metrics["dummy_deflection_rad"] = d.max_deflection
 metrics["dummy_hits"] = d.hit_count
 metrics["strike_points"] = strike_points.map(func(p: Vector3) -> String: return str(p))
 check(strikes > 0 and d.hit_count > 0,"joystick swings cause real solver contacts with the mannequin")
 check(d.max_deflection > .006,"mannequin physically deflects under actual punches")
 check(r.parts.LeftForearm.opponent_impulse < 4 and r.parts.RightForearm.opponent_impulse < 4,"both hands pull free after contact")
 s.left_stick.value = Vector2(1,.38)
 s.right_stick.value = Vector2(1,.10)
 await ticks(360)
 var before_hold: int = strikes
 await ticks(240)
 metrics["settled_hold_new_hits"] = strikes-before_hold
 check(strikes-before_hold <= 2,"resting pressure does not loop impact feedback")
 var finite := true
 for part in r.parts.values(): finite = finite and part.position.is_finite() and part.linear_velocity.is_finite()
 for part in d.parts.values(): finite = finite and part.position.is_finite() and part.linear_velocity.is_finite()
 check(finite,"repeated strikes keep both rigs finite")
 s._toggle_pause()
 var dummy_before: Transform3D = d.torso.global_transform
 await ticks(30)
 check(d.torso.global_transform.is_equal_approx(dummy_before),"pause freezes the mannequin too")
 s._reset()
 await ticks(240)
 check(d.hit_count == 0 and absf(d.torso.rotation.z) < .02,"reset restores the mannequin and clears strike feedback")
 check(absf(r.core.position.x) < .4 and r.core.position.y > 5.8,"reset restores the player after repeated punches")
 OS.remove_logger(errors)
 check(errors.snapshot().is_empty(),"no engine or script errors in the new physics")
 var result={"engine":Engine.get_version_info()["string"],"passed":passed,"failures":failures,"metrics":metrics,"engine_errors":errors.snapshot(),"physical_android_tested":false}
 print("POLISH_RESULT ",JSON.stringify(result))
 var f=FileAccess.open("user://polish_result.json",FileAccess.WRITE);f.store_string(JSON.stringify(result,"  "));f.close()
 SettingsManager.reset_defaults();AudioManager.shutdown()
 await get_tree().create_timer(.1).timeout
 get_tree().quit(0 if failures.is_empty() else 1)
