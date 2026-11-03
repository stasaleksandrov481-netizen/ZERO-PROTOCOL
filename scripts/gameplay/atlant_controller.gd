class_name AtlantController
extends Node3D
## Force-driven planar active ragdoll: 11 rigid bodies and 10 real hinge joints.
## The torso has an explicit balance assist; limbs never receive animated physics transforms.

# Explicit dependency: updating the project must not depend on the editor's class-name cache.
const PartBody = preload("res://scripts/gameplay/atlant_part.gd")

signal overload(point: Vector3, strength: float)
signal footstep(strength: float)
signal strike(point: Vector3, strength: float)

const LEG_UPPER := 2.1
const LEG_LOWER := 2.1
const ARM_UPPER := 1.65
const ARM_LOWER := 1.72
const REST_HEIGHT := 6.35
const WALK_SPEED := 2.8
const ARM_DEPTH := 1.46

@onready var core: PartBody = $Bodies/Core
var parts: Dictionary = {}
var initial_poses: Dictionary = {}
var walk_axis := 0.0
var hand_input: Array[Vector2] = [Vector2.ZERO,Vector2.ZERO]
var hand_world: Array[Vector2] = [Vector2.ZERO,Vector2.ZERO]
var world_aim: Array[bool] = [false,false]
var stabilized := true
var facing := 1.0
var model_yaw := PI*.5
var gait := 0.0
var walk_blend := 0.0
var total_mass := 0.0
var load_ratio := 0.0
var last_torque := 0.0
var reset_cooldown := 0
var overloaded_time := 0.0
var spark_cooldown := 0.0
var left_contact := false
var right_contact := false
var distance_walked := 0.0
var previous_x := 0.0
var enabled := true
var startup_error := ""
var initialized := false
var arm_goals: Array[Vector2] = [Vector2.ZERO,Vector2.ZERO]
var arm_speeds: Array[Vector2] = [Vector2.ZERO,Vector2.ZERO]
var strike_cooldowns: Array[float] = [0.0,0.0]
var hand_contacts: Array[bool] = [false,false]
var last_contact_impulses: Array[float] = [0.0,0.0]

func _ready() -> void:
	if core == null or get_node_or_null("Bodies") == null:
		startup_error = "АТ-01: отсутствует корпус или группа физических частей."
		set_physics_process(false)
		return
	for body: PartBody in $Bodies.get_children():
		parts[String(body.name)] = body
		initial_poses[String(body.name)] = body.global_transform
		total_mass += body.mass
	if parts.size() != 11 or $Joints.get_child_count() != 10:
		startup_error = "АТ-01: собрано %d из 11 частей, %d из 10 шарниров." % [parts.size(),$Joints.get_child_count()]
		set_physics_process(false)
		return
	previous_x = core.position.x
	_reset_arm_goals()
	_update_joint_limits()
	_update_visuals()
	initialized = true

static func solve_chain(target: Vector2, upper: float, lower: float, branch: float) -> Vector2:
	var radius := clampf(target.length(),absf(upper-lower)+.08,upper+lower-.055)
	var line := atan2(target.x,-target.y)
	var a := acos(clampf((upper*upper+radius*radius-lower*lower)/(2*upper*radius),-1,1))
	var b := acos(clampf((lower*lower+radius*radius-upper*upper)/(2*lower*radius),-1,1))
	return Vector2(line+branch*a,line-branch*b)

func _physics_process(delta: float) -> void:
	if not initialized or not enabled: return
	if reset_cooldown > 0:
		reset_cooldown -= 1
		return
	if not core.position.is_finite() or core.position.y < -6 or absf(core.position.x) > 90:
		reset_stance()
		return
	var moving := absf(walk_axis) > .08
	if moving: facing = signf(walk_axis)
	model_yaw = move_toward(model_yaw,facing*PI*.5,delta*5.2)
	_update_joint_limits()
	walk_blend = move_toward(walk_blend,absf(walk_axis) if moving else 0.0,delta*3.5)
	gait += delta*(3.4*walk_blend)
	last_torque = 0.0
	if stabilized:
		var lean := -walk_axis*.055
		_drive(core,null,lean,130,24,core.mass*145)
		var bob := absf(sin(gait))*.07*walk_blend
		var error := REST_HEIGHT + bob - core.position.y
		var support := _feet_near_ground()
		var lift := total_mass*(error*36.0-core.linear_velocity.y*8.0) + total_mass*9.8*.48
		core.apply_central_force(Vector3(0,clampf(lift,-total_mass*9.8,total_mass*9.8*2.1)*support,0))
		var desired_vx := walk_axis*WALK_SPEED
		var traction := clampf((desired_vx-core.linear_velocity.x)*4.6,-9.0,9.0)*total_mass
		core.apply_central_force(Vector3(traction*support,0,0))
	for index in range(2):
		_drive_leg(index)
		_drive_arm(index,delta)
	load_ratio = lerpf(load_ratio,clampf(last_torque/1850.0,0,1),.08)
	spark_cooldown = maxf(0,spark_cooldown-delta)
	if load_ratio > .82: overloaded_time += delta
	else: overloaded_time = maxf(0,overloaded_time-delta*2)
	if overloaded_time > .22 and spark_cooldown == 0:
		var forearm: PartBody = parts["LeftForearm"] if hand_input[0].length() > hand_input[1].length() else parts["RightForearm"]
		overload.emit(forearm.global_position+Vector3(.2,.65,.35),load_ratio)
		spark_cooldown = .85
		overloaded_time = 0
	_contact_events()
	distance_walked += absf(core.position.x-previous_x)
	previous_x = core.position.x
	_update_visuals()

func _feet_near_ground() -> float:
	var left: PartBody = parts["LeftFoot"]
	var right: PartBody = parts["RightFoot"]
	return 1.0 if minf(left.position.y,right.position.y) < 1.15 else .1

func _drive_leg(index: int) -> void:
	var prefix := "Left" if index == 0 else "Right"
	var upper: PartBody = parts[prefix+"Thigh"]
	var lower: PartBody = parts[prefix+"Shin"]
	var foot: PartBody = parts[prefix+"Foot"]
	if not stabilized or absf(wrapf(core.rotation.z,-PI,PI)) > .9:
		# Once down, do not pull the knees toward imaginary world-space footsteps.
		# Keep a loose anatomical pose and let gravity/contact forces carry the fall.
		_drive(upper,core,core.rotation.z+facing*.15,18,8,upper.mass*25)
		_drive(lower,upper,upper.rotation.z-facing*.45,18,8,lower.mass*22)
		_drive(foot,lower,lower.rotation.z+facing*.15,16,8,foot.mass*20)
		return
	var phase := gait + (PI if index == 0 else 0.0)
	var idle_x := -.43 if index == 0 else .43
	var foot_x := lerpf(idle_x,sin(phase)*1.02*facing,walk_blend)
	var lift := maxf(0,cos(phase))*.82*walk_blend
	var hip := Vector2(core.position.x,core.position.y-1.7)
	var target := Vector2(core.position.x+foot_x,.7+lift)-hip
	var angles := solve_chain(target,LEG_UPPER,LEG_LOWER,facing)
	_drive(upper,core,angles.x,100,19,upper.mass*135)
	_drive(lower,upper,angles.y,105,20,lower.mass*145)
	_drive(foot,lower,-sin(phase)*.05*walk_blend,100,19,foot.mass*120)

func _drive_arm(index: int, delta: float) -> void:
	var prefix := "Left" if index == 0 else "Right"
	var upper: PartBody = parts[prefix+"UpperArm"]
	var lower: PartBody = parts[prefix+"Forearm"]
	var shoulder := Vector2(core.position.x,core.position.y+.83)
	var target := Vector2(-.45 if index == 0 else .45,-3.15)
	var control: Vector2 = hand_input[index]
	var commanded := world_aim[index] or control.length() > .1
	if world_aim[index]:
		target = hand_world[index]-shoulder
	elif control.length() > .1:
		target = Vector2(control.x,-control.y).normalized()*(1.65+1.62*clampf(control.length(),0,1))
	var angles := solve_chain(target,ARM_UPPER,ARM_LOWER,-facing)
	# Anatomical joint coordinates: the elbow bends toward the facing direction.
	# Acceleration-limited servo targets preserve momentum when a stick reverses.
	var requested := Vector2(clampf(wrapf(angles.x-(core.rotation.z if commanded else 0.0),-PI,PI),-2.35,2.35),
		facing*clampf(absf(wrapf(angles.y-angles.x,-PI,PI)),.1,2.30))
	for axis in range(2):
		var error := requested[axis]-arm_goals[index][axis]
		var speed_limit := 2.45 if axis == 0 else 3.0
		var acceleration := 8.0 if axis == 0 else 10.0
		var wanted_speed := clampf(error*5.5,-speed_limit,speed_limit)
		arm_speeds[index][axis] = move_toward(arm_speeds[index][axis],wanted_speed,acceleration*delta)
		var step := arm_speeds[index][axis]*delta
		if signf(step) == signf(error) and absf(step) > absf(error):
			step = error
			arm_speeds[index][axis] = 0.0
		arm_goals[index][axis] += step
	var shoulder_point := core.position+Vector3(0,.83,0)
	var elbow_point := upper.position+Vector3(sin(upper.rotation.z),-cos(upper.rotation.z),0)*ARM_UPPER*.5
	var shoulder_gravity := 9.8*(upper.mass*(upper.position.x-shoulder_point.x)+lower.mass*(lower.position.x-shoulder_point.x))
	var elbow_gravity := 9.8*lower.mass*(lower.position.x-elbow_point.x)
	var up_radius := Vector2(upper.position.x-shoulder_point.x,upper.position.y-shoulder_point.y)
	var low_radius := Vector2(lower.position.x-shoulder_point.x,lower.position.y-shoulder_point.y)
	var shoulder_inertia := upper.inertia.z+upper.mass*up_radius.length_squared()+lower.inertia.z+lower.mass*low_radius.length_squared()
	var elbow_inertia := lower.inertia.z+lower.mass*ARM_LOWER*ARM_LOWER*.25
	_arm_motor(upper,core,arm_goals[index].x,32,11,upper.mass*90,shoulder_gravity,shoulder_inertia)
	_arm_motor(lower,upper,arm_goals[index].y,38,12,lower.mass*55,elbow_gravity,elbow_inertia)
	strike_cooldowns[index] = maxf(0,strike_cooldowns[index]-delta)
	var impact := lower.opponent_impulse
	var new_impact := not hand_contacts[index] or impact > last_contact_impulses[index]*1.8
	if impact > 4.0 and new_impact and strike_cooldowns[index] == 0:
		strike.emit(lower.opponent_contact,clampf(lower.opponent_impulse/50.0,.15,1.0))
		strike_cooldowns[index] = .24
	hand_contacts[index] = impact > .3
	last_contact_impulses[index] = impact

func _arm_motor(body: PartBody, parent_body: PartBody, target: float, stiffness: float,
		damping: float, limit: float, gravity_compensation: float, joint_inertia: float) -> void:
	var angle := wrapf(body.rotation.z-parent_body.rotation.z,-PI,PI)
	var speed := body.angular_velocity.z-parent_body.angular_velocity.z
	var error := target-angle
	var torque := joint_inertia*(stiffness*error-damping*speed)+gravity_compensation*.9
	# A compressed contact does not build up an integral force that launches the arm.
	if body.opponent_impulse > 2: torque -= body.inertia.z*speed*2.0
	torque = clampf(torque,-limit,limit)
	body.apply_torque(Vector3(0,0,torque))
	parent_body.apply_torque(Vector3(0,0,-torque))
	last_torque += absf(torque)

func _update_joint_limits() -> void:
	# Handed anatomical stops follow the existing face-through-camera turn.
	# They remain active with stabilization off and during every collision/fall.
	var side := sin(model_yaw)
	for prefix: String in ["Left","Right"]:
		_set_anatomical_limit($Joints.get_node(prefix+"Shoulder"),-2.4,2.4)
		_set_anatomical_limit($Joints.get_node(prefix+"Elbow"),-2.4*maxf(-side,0)-.07,2.4*maxf(side,0)+.07)
		_set_anatomical_limit($Joints.get_node(prefix+"Hip"),-1.25,1.25)
		_set_anatomical_limit($Joints.get_node(prefix+"Knee"),-1.98*maxf(side,0)-.06,1.98*maxf(-side,0)+.06)
		_set_anatomical_limit($Joints.get_node(prefix+"Ankle"),-.55,.55)

func _set_anatomical_limit(joint: HingeJoint3D, lower: float, upper: float) -> void:
	var rest := float(joint.get_meta("rest_angle",0.0))
	# Godot's hinge coordinate increases opposite to the child-body Z angle.
	joint.set_param(HingeJoint3D.PARAM_LIMIT_LOWER,rest-upper)
	joint.set_param(HingeJoint3D.PARAM_LIMIT_UPPER,rest-lower)
	joint.set_meta("anatomical_lower",lower)
	joint.set_meta("anatomical_upper",upper)

func _reset_arm_goals() -> void:
	for index in range(2):
		var prefix := "Left" if index == 0 else "Right"
		var up: PartBody = parts[prefix+"UpperArm"]
		var low: PartBody = parts[prefix+"Forearm"]
		arm_goals[index] = Vector2(up.rotation.z-core.rotation.z,low.rotation.z-up.rotation.z)
		arm_speeds[index] = Vector2.ZERO
		strike_cooldowns[index] = .35
		hand_contacts[index] = false
		last_contact_impulses[index] = 0.0

func _drive(body: PartBody, parent_body: PartBody, absolute_angle: float, stiffness: float, damping: float, limit: float) -> void:
	var relative_speed := body.angular_velocity.z
	if parent_body != null: relative_speed -= parent_body.angular_velocity.z
	var error := wrapf(absolute_angle-body.rotation.z,-PI,PI)
	var inertia_z := body.inertia.z
	if inertia_z <= 0: inertia_z = body.mass*.8
	var torque := clampf(inertia_z*(stiffness*error-damping*relative_speed),-limit,limit)
	body.apply_torque(Vector3(0,0,torque))
	if parent_body != null: parent_body.apply_torque(Vector3(0,0,-torque))
	last_torque += absf(torque)

func _contact_events() -> void:
	for prefix: String in ["Left","Right"]:
		var foot: PartBody = parts[prefix+"Foot"]
		var touching := foot.support_contacts > 0
		var was_touching := left_contact if prefix == "Left" else right_contact
		if touching and not was_touching:
			footstep.emit(clampf(foot.contact_impulse/30.0,.15,1))
		if touching and foot.contact_impulse > 9.0 and spark_cooldown == 0:
			overload.emit(foot.global_position+Vector3(0,.4,.35),.7)
			spark_cooldown = .9
		if prefix == "Left": left_contact = touching
		else: right_contact = touching

func _update_visuals() -> void:
	for key: String in parts:
		var body: PartBody = parts[key]
		var visual := body.get_node("Visual") as Node3D
		visual.rotation.y = model_yaw
		if key == "Core": continue
		var side := 1.0 if key.begins_with("Left") else -1.0
		var span := ARM_DEPTH if "Arm" in key else .65
		var physical_z := -side*span
		var offset := Vector3(side*span*cos(model_yaw),0,-side*span*sin(model_yaw)-physical_z)
		visual.position = body.global_basis.inverse()*offset

func reset_stance() -> void:
	for key: String in parts:
		var body: PartBody = parts[key]
		body.reset_pose = initial_poses[key]
		body.reset_requested = true
		body.sleeping = false
	walk_axis = 0
	hand_input = [Vector2.ZERO,Vector2.ZERO]
	world_aim = [false,false]
	model_yaw = PI*.5
	facing = 1
	gait = 0
	walk_blend = 0
	load_ratio = 0
	overloaded_time = 0
	spark_cooldown = 1
	previous_x = 0
	reset_cooldown = 3
	for index in range(2):
		var prefix := "Left" if index == 0 else "Right"
		var up_pose: Transform3D = initial_poses[prefix+"UpperArm"]
		var low_pose: Transform3D = initial_poses[prefix+"Forearm"]
		arm_goals[index] = Vector2(up_pose.basis.get_euler().z,low_pose.basis.get_euler().z-up_pose.basis.get_euler().z)
		arm_speeds[index] = Vector2.ZERO
		strike_cooldowns[index] = .35
		hand_contacts[index] = false
		last_contact_impulses[index] = 0.0

func set_enabled(value: bool) -> void:
	enabled = value
	for body: PartBody in parts.values():
		body.freeze = not value
	if not value:
		walk_axis = 0
		hand_input = [Vector2.ZERO,Vector2.ZERO]
		world_aim = [false,false]
