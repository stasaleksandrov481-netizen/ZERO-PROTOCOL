extends Node
var failures: Array[String] = []
var observed: Dictionary = {}
func _ready() -> void: call_deferred("run")
func run() -> void:
 SettingsManager.set_value("video/reduced_motion",true)
 var app = load("res://scenes/menu/main_menu.tscn").instantiate()
 add_child(app)
 for i in range(5): await get_tree().process_frame
 await NavigationManager.go(&"test")
 var s = NavigationManager.current_screen
 var r = s.robot
 for i in range(150): await get_tree().physics_frame
 r.stabilized = false
 r.enabled = false # Disable every servo; the hardware stops must still work.
 r.core.apply_central_impulse(Vector3(210,270,0))
 r.core.apply_torque_impulse(Vector3(0,0,80))
 var rng = RandomNumberGenerator.new();rng.seed = 734
 var pairs = [["Shoulder","Core","UpperArm"],["Elbow","UpperArm","Forearm"],["Hip","Core","Thigh"],["Knee","Thigh","Shin"],["Ankle","Shin","Foot"]]
 for tick in range(720):
  if tick%80 == 0:
   for body in r.parts.values(): body.apply_torque_impulse(Vector3(0,0,rng.randf_range(-16,16)))
  await get_tree().physics_frame
  for prefix in ["Left","Right"]:
   for pair in pairs:
    var a = r.parts["Core" if pair[1] == "Core" else prefix+pair[1]]
    var b = r.parts[prefix+pair[2]]
    var angle = wrapf(b.rotation.z-a.rotation.z,-PI,PI)
    var joint = r.get_node("Joints/"+prefix+pair[0])
    var low = float(joint.get_meta("anatomical_lower"));var high = float(joint.get_meta("anatomical_upper"))
    var excess = maxf(low-angle,angle-high)
    var key = prefix+pair[0]
    observed[key] = maxf(observed.get(key,0),excess)
    if not b.position.is_finite(): failures.append("nonfinite "+key)
 for key in observed:
  if observed[key] > .20: failures.append(key+" overshoot "+str(observed[key]))
 print("JOINT_FALL_RESULT ",JSON.stringify({"failures":failures,"max_violation_radians":observed}))
 var f=FileAccess.open("user://joint_fall_result.json",FileAccess.WRITE);f.store_string(JSON.stringify({"failures":failures,"max_violation_radians":observed},"  "));f.close()
 AudioManager.shutdown()
 await get_tree().create_timer(.1).timeout
 get_tree().quit(0 if failures.is_empty() else 1)
