extends Node
func _ready() -> void: call_deferred("run")
func run() -> void:
 SettingsManager.set_value("video/reduced_motion",true)
 var app = load("res://scenes/menu/main_menu.tscn").instantiate()
 add_child(app)
 for i in range(5): await get_tree().process_frame
 await NavigationManager.go(&"test")
 var s = NavigationManager.current_screen
 for i in range(180): await get_tree().physics_frame
 for mode in range(3):
  s.left_stick.value = Vector2(1,-.6) if mode != 2 else Vector2(-1,.5)
  for j in range(8):
   for i in range(30): await get_tree().physics_frame
   var r = s.robot
   print("ARM ",mode," ",j," c=",r.core.rotation.z," up=",r.parts.LeftUpperArm.rotation.z," low=",r.parts.LeftForearm.rotation.z," goals=",r.arm_goals[0]," vel=",r.parts.LeftUpperArm.angular_velocity.z," jointRange=",r.get_node("Joints/LeftShoulder").get_param(HingeJoint3D.PARAM_LIMIT_LOWER),"..",r.get_node("Joints/LeftShoulder").get_param(HingeJoint3D.PARAM_LIMIT_UPPER))
 AudioManager.shutdown()
 await get_tree().create_timer(.1).timeout
 get_tree().quit()
