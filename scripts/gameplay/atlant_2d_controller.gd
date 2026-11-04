extends Node2D
## Genuine 2D articulated character. Painted parts remain in one fixed right-facing view.
const Part = preload("res://scripts/gameplay/atlant_2d_part.gd")
const P := 64.0
const G := 627.2
const ARM_UPPER := 1.65*P
const ARM_LOWER := 1.72*P
const LEG_UPPER := 2.1*P
const LEG_LOWER := 2.1*P
const REST_Y := -6.35*P
const WALK_SPEED := 2.45*P
const RUN_SPEED := 3.8*P
const SHOULDER_MIN := -3.02
const SHOULDER_MAX := 1.65
signal overload(point: Vector2,strength: float)
signal impact(point: Vector2,strength: float,direction: Vector2,target: PhysicsBody2D)
signal strike(point: Vector2,strength: float)
signal footstep(strength: float)
signal planted(point: Vector2,strength: float)
signal balance_changed(state: String)
@onready var core: Part = $Bodies/Core
var parts: Dictionary = {}
var initial_poses: Dictionary = {}
var arm_load: Array[float] = [0.0,0.0]
var fallen := false
const Balance = preload("res://scripts/systems/balance_response.gd")
var balance: Balance = Balance.new()
var balance_state := "steady"
var run_requested := false
var run_blend := 0.0
var walk_axis := 0.0
var hand_input: Array[Vector2] = [Vector2.ZERO,Vector2.ZERO]
var hand_world: Array[Vector2] = [Vector2.ZERO,Vector2.ZERO]
var world_aim: Array[bool] = [false,false]
var hand_engaged: Array[bool] = [false,false]
var arm_goals: Array[Vector2] = [Vector2.ZERO,Vector2.ZERO]
var arm_speeds: Array[Vector2] = [Vector2.ZERO,Vector2.ZERO]
var arm_commanded: Array[bool] = [false,false]
var wrist_targets: Array[Vector2] = [Vector2(-16,198),Vector2(32,198)]
var wrist_velocities: Array[Vector2] = [Vector2.ZERO,Vector2.ZERO]
var elbow_compression: Array[float] = [0.0,0.0]
var strike_cooldowns: Array[float] = [0.0,0.0]
var hand_contacts: Array[bool] = [false,false]
var last_impulses: Array[float] = [0.0,0.0]
var stabilized := true
var enabled := true
var initialized := false
var startup_error := ""
var facing := 1.0 # Deliberately fixed. Turning awaits the user's new design.
var gait := 0.0
var walk_blend := 0.0
var drive_axis := 0.0
var step_times: Array[float] = [-10.0,-10.0]
var physics_clock := 0.0
var total_mass := 0.0
var load_ratio := 0.0
var last_torque := 0.0
var distance_walked := 0.0
var previous_x := 0.0
var reset_cooldown := 0
var left_contact := false
var right_contact := false
var spark_cooldown := 0.0
var overload_time := 0.0
func _ready() -> void:
 for body: Part in $Bodies.get_children():
  parts[String(body.name)] = body
  initial_poses[String(body.name)] = body.global_transform
  total_mass += body.mass
 if core == null or parts.size() != 12 or $Joints.get_child_count() != 11:
  startup_error = "Не собран 2D-риг АТ-01."
  set_physics_process(false)
  return
 previous_x = core.position.x
 for joint: PinJoint2D in $Joints.get_children():
  var parent: Part = parts[joint.get_meta("parent_key")]
  var child: Part = parts[joint.get_meta("child_key")]
  child.configure_stop(parent,joint.global_position,float(joint.get_meta("anatomical_lower")),float(joint.get_meta("anatomical_upper")))
 _reset_commands()
 initialized = true

static func solve_chain(target: Vector2, upper: float, lower: float, branch: float) -> Vector2:
 var radius := clampf(target.length(),maxf(absf(upper-lower)+5.0,.78*P),upper+lower-4.0)
 var line := atan2(-target.x,target.y)
 if line > PI*.5: line -= TAU
 var a := acos(clampf((upper*upper+radius*radius-lower*lower)/(2.0*upper*radius),-1,1))
 var b := acos(clampf((lower*lower+radius*radius-upper*upper)/(2.0*lower*radius),-1,1))
 return Vector2(line+branch*a,line-branch*b)

func _physics_process(delta: float) -> void:
 if not initialized or not enabled: return
 if reset_cooldown > 0:
  reset_cooldown -= 1
  return
 if not core.position.is_finite() or core.position.y > 8*P:
  reset_stance()
  return
 physics_clock += delta
 var root_angle := wrapf(core.rotation,-PI,PI)
 if stabilized and absf(root_angle) > .98 and not balance.is_prone(): balance.fall(signf(root_angle))
 var upright := absf(root_angle) < .30 and core.position.y < REST_Y+70
 balance.tick(delta,upright,_grounded())
 fallen = balance.is_prone()
 if balance.state != balance_state: balance_state = balance.state;balance_changed.emit(balance_state)
 run_blend = move_toward(run_blend,1.0 if run_requested and absf(walk_axis) > .08 and balance.state == "steady" else 0.0,delta*.72)
 drive_axis = move_toward(drive_axis,walk_axis,delta*(1.15 if absf(walk_axis) > .08 else 1.8))
 if fallen: drive_axis = move_toward(drive_axis,0,delta*3)
 walk_blend = move_toward(walk_blend,absf(drive_axis),delta*2.2)
 gait += delta*lerpf(3.0,2.85,run_blend)*walk_blend
 last_torque = 0
 _drive(parts["Head"],core,core.rotation,60,16,parts["Head"].mass*90*P*P)
 if stabilized:
  var down := balance.state in ["falling","down"]
  var rise := balance.state == "rising"
  var stability := .07 if down else (.35+.65*clampf(balance.age/2.0,0,1) if rise else 1.0)
  _drive(core,null,drive_axis*(.065+run_blend*.07)+balance.lean,130*stability,24*sqrt(stability),core.mass*145*P*P*stability)
  var bob := absf(sin(gait))*.07*P*walk_blend
  var rest_height := REST_Y+run_blend*.27*P
  var error := rest_height-bob-core.position.y
  if rise: error *= smoothstep(0,1,clampf(balance.age/1.5,0,1))
  var support := _support()
  if rise: support = maxf(support,.85)
  if down: support = 0
  var force := total_mass*(error*36-core.linear_velocity.y*8)-total_mass*G*.48
  core.apply_central_force(Vector2(0,clampf(force,-total_mass*G*2.1,total_mass*G)*support))
  var traction := clampf((drive_axis*lerpf(WALK_SPEED,RUN_SPEED,run_blend)-core.linear_velocity.x)*3.7,-4.5*P,4.5*P)*total_mass
  core.apply_central_force(Vector2(traction*support*(.16 if balance.state == "stagger" else (.25 if rise else 1.0)),0))
 for index in range(2):
  _leg(index)
  _arm(index,delta)
 load_ratio = lerpf(load_ratio,clampf(last_torque/(1850*P*P),0,1),.08)
 spark_cooldown = maxf(0,spark_cooldown-delta)
 if load_ratio > .88: overload_time += delta
 else: overload_time = maxf(0,overload_time-delta*2)
 if overload_time > .3 and spark_cooldown == 0:
  var hand: Part = parts["LeftForearm"] if hand_input[0].length() > hand_input[1].length() else parts["RightForearm"]
  overload.emit(hand.global_position,load_ratio)
  spark_cooldown = .9;overload_time = 0
 _contacts()
 distance_walked += absf(core.position.x-previous_x)
 previous_x = core.position.x

func _support() -> float:
 var a: Part = parts["LeftFoot"];var b: Part = parts["RightFoot"]
 return 1.0 if maxf(a.position.y,b.position.y) > -1.2*P else .1
func _grounded() -> bool:
 for body: Part in parts.values():
  if body.support_contacts > 0: return true
 return false
func receive_impact(strength: float,direction: Vector2,point: Vector2 = Vector2.ZERO) -> void:
 if not enabled: return
 var push := signf(direction.x)
 if push == 0: push = 1
 var bracing := run_blend > .6 or ((hand_engaged[0] or hand_engaged[1]) and maxf(parts.LeftForearm.linear_velocity.length(),parts.RightForearm.linear_velocity.length()) > 150)
 balance.hit(strength,push,run_blend,_grounded(),bracing)
 if strength >= .20:
  for body: Part in parts.values(): body.apply_central_impulse(Vector2(push*(22+strength*78),-strength*4)*body.mass)
  core.apply_torque_impulse(core.inertia*push*strength*.65)
func request_recovery() -> void: balance.request_recovery()

func _leg(index: int) -> void:
 var prefix := "Left" if index == 0 else "Right"
 var up: Part = parts[prefix+"Thigh"]
 var low: Part = parts[prefix+"Shin"]
 var foot: Part = parts[prefix+"Foot"]
 if not stabilized or balance.state in ["falling","down"]:
  _drive(up,core,core.rotation-.15,18,8,up.mass*25*P*P)
  _drive(low,up,up.rotation+.45,18,8,low.mass*22*P*P)
  _drive(foot,low,low.rotation-.15,16,8,foot.mass*20*P*P)
  return
 var phase := gait+(PI if index == 0 else 0.0)
 var idle := .60 if index == 0 else -.60
 var x := lerpf(idle,sin(phase)*lerpf(1.18,1.84,run_blend)*signf(drive_axis),walk_blend)
 var lift := maxf(0,cos(phase))*lerpf(.82,1.03,run_blend)*walk_blend
 if balance.catch_step > .01:
  var catch_phase: float = balance.age*6.0+(PI if index == 0 else 0.0)
  x += balance.direction*balance.catch_step*(.75 if index == 0 else 1.1)
  lift = maxf(lift,maxf(0,sin(catch_phase))*.62*balance.catch_step)
 var hip := core.position+Vector2(.33 if index == 0 else -.33,1.7).rotated(core.rotation)*P
 var target := Vector2(core.position.x+x*P,(-.60-lift)*P)-hip
 var angles := solve_chain(target,LEG_UPPER,LEG_LOWER,-1)
 _drive(up,core,angles.x,100,19,up.mass*135*P*P)
 _drive(low,up,angles.y,105,20,low.mass*145*P*P)
 _drive(foot,low,sin(phase)*.05*walk_blend,100,19,foot.mass*120*P*P)

func _arm(index: int,delta: float) -> void:
 var prefix := "Left" if index == 0 else "Right"
 var up: Part = parts[prefix+"UpperArm"]
 var low: Part = parts[prefix+"Forearm"]
 var shoulder := core.position+Vector2(.58 if index == 0 else -.62,-.83).rotated(core.rotation)*P
 var control: Vector2 = hand_input[index]
 var commanded := (world_aim[index] or hand_engaged[index] or control.length() > .08) and not fallen
 if arm_commanded[index] and not commanded:
  # Cancel the command's stored motion, then brake the physical arm into its rest pose.
  arm_goals[index] = Vector2(clampf(wrapf(up.rotation-core.rotation,-PI,PI),SHOULDER_MIN,SHOULDER_MAX),clampf(wrapf(low.rotation-up.rotation,-PI,PI),-2.65,-.04))
  arm_speeds[index] = Vector2.ZERO
 arm_commanded[index] = commanded
 var swing := sin(gait+(PI if index == 0 else 0.0))*1.45*walk_blend
 var target := Vector2((-.25 if index == 0 else .50)+swing,3.10-absf(swing)*.25)*P
 if fallen: target = Vector2(.65,2.8)*P
 elif world_aim[index]: target = hand_world[index]-shoulder
 elif hand_engaged[index] or control.length() > .08:
  # A forward working envelope: retract, jab, sweep up or drive down with the elbow.
  # Pulling back folds the arm in front of the body instead of winding the shoulder.
  target = Vector2(lerpf(.25,3.12,(control.x+1)*.5),.42+control.y*2.72)*P
 var desired_velocity := ((target-wrist_targets[index])*7.0).limit_length(340 if commanded else 210)
 wrist_velocities[index] = wrist_velocities[index].move_toward(desired_velocity,(1000 if commanded else 620)*delta)
 wrist_targets[index] += wrist_velocities[index]*delta
 var angles := solve_chain(wrist_targets[index],ARM_UPPER,ARM_LOWER,1)
 elbow_compression[index] = move_toward(elbow_compression[index],clampf(low.opponent_impulse/(35*P),0,.26),delta*3.0)
 # The target and the measured joint angle must share one bounded coordinate domain.
 # Unwrapping only the target used to wind it up by 2π and keep the motor spinning.
 var desired_shoulder := clampf(wrapf(angles.x-core.rotation,-PI,PI),SHOULDER_MIN+.04,SHOULDER_MAX-.04)
 var requested := Vector2(desired_shoulder,
  clampf(wrapf(angles.y-angles.x,-PI,PI)-elbow_compression[index],-2.65,-.04))
 for axis in range(2):
  var error := requested[axis]-arm_goals[index][axis]
  var max_speed := (3.0 if axis == 0 else 4.0) if commanded else (1.8 if axis == 0 else 2.5)
  var desired := clampf(error*6.0,-max_speed,max_speed)
  arm_speeds[index][axis] = move_toward(arm_speeds[index][axis],desired,(6.0 if axis == 0 else 9.0)*delta)
  var step := arm_speeds[index][axis]*delta
  if signf(step) == signf(error) and absf(step) > absf(error): step = error;arm_speeds[index][axis] = 0
  arm_goals[index][axis] += step
 arm_goals[index].x = clampf(arm_goals[index].x,SHOULDER_MIN,SHOULDER_MAX)
 arm_goals[index].y = clampf(arm_goals[index].y,-2.65,-.04)
 var elbow := up.position+Vector2.DOWN.rotated(up.rotation)*ARM_UPPER*.5
 var gravity_shoulder := -G*(up.mass*(up.position.x-shoulder.x)+low.mass*(low.position.x-shoulder.x))
 var gravity_elbow := -G*low.mass*(low.position.x-elbow.x)
 var inertia_shoulder := up.inertia+up.mass*up.position.distance_squared_to(shoulder)+low.inertia+low.mass*low.position.distance_squared_to(shoulder)
 var inertia_elbow := low.inertia+low.mass*ARM_LOWER*ARM_LOWER*.25
 _motor(up,core,arm_goals[index].x,32,15,up.mass*110*P*P,gravity_shoulder,inertia_shoulder)
 _motor(low,up,arm_goals[index].y,44,17,low.mass*80*P*P,gravity_elbow,inertia_elbow)
 arm_load[index] = clampf(absf(requested.x-arm_goals[index].x)*.6+absf(arm_speeds[index].x)*.12,0,1)
 strike_cooldowns[index] = maxf(0,strike_cooldowns[index]-delta)
 var contact_hit := low.opponent_impulse
 var new_impact := not hand_contacts[index] or contact_hit > last_impulses[index]*1.8
 if contact_hit > 4*P and new_impact and strike_cooldowns[index] == 0:
  var strength := clampf(contact_hit/(50*P),.15,1)
  strike.emit(low.opponent_contact,strength)
  if is_instance_valid(low.opponent_body): impact.emit(low.opponent_contact,strength,low.linear_velocity.normalized(),low.opponent_body)
  strike_cooldowns[index] = .24
 hand_contacts[index] = contact_hit > .3*P
 last_impulses[index] = contact_hit

func _motor(body: Part,parent: Part,target: float,k: float,damping: float,limit: float,gravity: float,inertia_value: float) -> void:
 var angle := wrapf(body.rotation-parent.rotation,-PI,PI)
 var speed := body.angular_velocity-parent.angular_velocity
 var torque := inertia_value*(k*(target-angle)-damping*speed)+gravity*.9
 torque = clampf(torque,-limit,limit)
 body.apply_torque(torque);parent.apply_torque(-torque)
 last_torque += absf(torque)
func _drive(body: Part,parent: Part,target: float,k: float,damping: float,limit: float) -> void:
 var speed := body.angular_velocity-(parent.angular_velocity if parent != null else 0.0)
 var error := wrapf(target-body.rotation,-PI,PI)
 var torque := clampf(body.inertia*(k*error-damping*speed),-limit,limit)
 body.apply_torque(torque)
 if parent != null: parent.apply_torque(-torque)
 last_torque += absf(torque)
func _contacts() -> void:
 for prefix: String in ["Left","Right"]:
  var foot: Part = parts[prefix+"Foot"]
  var touching := foot.support_contacts > 0
  var was := left_contact if prefix == "Left" else right_contact
  var index := 0 if prefix == "Left" else 1
  if touching and not was and physics_clock-step_times[index] > .40:
   var strength := clampf(foot.contact_impulse/(30*P)+walk_blend*.32+run_blend*.20,.15,1)
   step_times[index] = physics_clock;footstep.emit(strength);planted.emit(foot.global_position,strength)
  if prefix == "Left": left_contact = touching
  else: right_contact = touching
func _reset_commands() -> void:
 for index in range(2):
  var prefix := "Left" if index == 0 else "Right"
  var up: Part = parts[prefix+"UpperArm"];var low: Part = parts[prefix+"Forearm"]
  var up_pose: Transform2D = initial_poses[prefix+"UpperArm"]
  var low_pose: Transform2D = initial_poses[prefix+"Forearm"]
  arm_goals[index] = Vector2(up_pose.get_rotation(),low_pose.get_rotation()-up_pose.get_rotation())
  arm_speeds[index] = Vector2.ZERO;strike_cooldowns[index] = .35;hand_contacts[index] = false;last_impulses[index] = 0
  arm_commanded[index] = false
  wrist_targets[index] = Vector2(-.25 if index == 0 else .50,3.10)*P;wrist_velocities[index] = Vector2.ZERO;elbow_compression[index] = 0
func reset_stance() -> void:
 for key: String in parts:
  parts[key].reset_pose = initial_poses[key]
  parts[key].reset_requested = true;parts[key].sleeping = false
 walk_axis = 0;hand_input.assign([Vector2.ZERO,Vector2.ZERO]);world_aim.assign([false,false]);hand_engaged.assign([false,false])
 gait = 0;walk_blend = 0;drive_axis = 0;run_requested = false;run_blend = 0;balance.clear();fallen = false;balance_state = "steady";load_ratio = 0;overload_time = 0;spark_cooldown = 1;step_times.assign([-10.0,-10.0])
 previous_x = 0;reset_cooldown = 3
 _reset_commands()
func set_enabled(value: bool) -> void:
 enabled = value
 for body: Part in parts.values(): body.freeze = not value
 if not value:
  run_requested = false
  walk_axis = 0;hand_input.assign([Vector2.ZERO,Vector2.ZERO]);world_aim.assign([false,false]);hand_engaged.assign([false,false])
