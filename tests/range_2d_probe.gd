extends Node
var app: Control
func ticks(count: int) -> void:
 for i in range(count): await get_tree().physics_frame
func _ready() -> void: call_deferred("run")
func run() -> void:
 SettingsManager.reset_defaults();SettingsManager.set_value("video/reduced_motion",true)
 app = load("res://scenes/menu/main_menu.tscn").instantiate();add_child(app)
 for i in range(5): await get_tree().process_frame
 await NavigationManager.go(&"test")
 var s = NavigationManager.current_screen
 if not s.has_method("is_range_ready") or not s.is_range_ready():
  print("2D FAILED ROUTE ",NavigationManager.current_route)
  if is_instance_valid(NavigationManager.active_modal): print(NavigationManager.active_modal.body_text)
  get_tree().quit(1);return
 var r = s.robot
 for step in range(8):
  await ticks(60)
  print("IDLE ",step," core=",r.core.position," v=",r.core.linear_velocity," theta=",r.core.rotation," knee=",r.parts.RightShin.rotation-r.parts.RightThigh.rotation)
 for control in [Vector2(1,0),Vector2(.25,-.3),Vector2(.35,.15),Vector2(-.6,.5)]:
  s.right_stick.value = control
  await ticks(210)
  print("ARM2D ",control," up=",r.parts.RightUpperArm.rotation-r.core.rotation," bend=",r.parts.RightForearm.rotation-r.parts.RightUpperArm.rotation," goal=",r.arm_goals[1])
 AudioManager.shutdown();await get_tree().create_timer(.1).timeout
 get_tree().quit()
