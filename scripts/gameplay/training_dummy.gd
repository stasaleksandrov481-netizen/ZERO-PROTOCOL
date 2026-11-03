extends Node3D
## Passive practice stand. Every movable section is a real rigid body.
## The only restoring force is the torsion spring in the floor-mounted pivot.
const BodyScript = preload("res://scripts/gameplay/atlant_part.gd")
var parts: Dictionary = {}
var poses: Dictionary = {}
var torso: RigidBody3D
var enabled := true
var initialized := false
var hit_count := 0
var last_strength := 0.0
var max_deflection := 0.0
var flash := 0.0
var target_material: StandardMaterial3D
var body_root: Node3D
var metal: StandardMaterial3D
var armor: StandardMaterial3D
var accent: StandardMaterial3D

func _ready() -> void:
	metal = _material(Color("343b3e"),.5)
	armor = _material(Color("777e7c"),.25)
	accent = _material(Color("b58443"),.22)
	target_material = _material(Color("b14a3f"),.1)
	target_material.emission_enabled = true
	target_material.emission = Color("ff813f")
	target_material.emission_energy_multiplier = 0.0
	body_root = Node3D.new()
	body_root.name = "Bodies"
	add_child(body_root)
	var base := StaticBody3D.new()
	base.name = "Base"
	base.collision_layer = 4
	base.collision_mask = 2
	body_root.add_child(base)
	_box(base,Vector3(3.6,.5,4.2),Vector3(0,.25,0),metal,true)
	_box(base,Vector3(3.63,.08,4.23),Vector3(0,.46,0),accent,false)
	torso = _body("Torso",Vector3(0,4.65,0),42,Vector3(2.3,2.9,3.8))
	_box(torso,Vector3(2.35,2.95,3.83),Vector3.ZERO,armor,false)
	_box(torso,Vector3(1.65,1.95,.09),Vector3(0,.15,1.97),metal,false)
	_ring(torso,.68,.69,Vector3(0,.18,2.035),target_material)
	_ring(torso,.43,.44,Vector3(0,.18,2.10),accent)
	_ring(torso,.21,.22,Vector3(0,.18,2.15),target_material)
	# Paired legs and feet are part of the floor-pivoted frame, not a walking AI.
	for side: float in [-1,1]:
		_box(torso,Vector3(.30,2.55,.56),Vector3(side*.64,-2.6,0),metal,false)
		_box(torso,Vector3(.74,.3,2.5),Vector3(side*.64,-4.04,.28),metal,false)
		_box(torso,Vector3(.74,.08,1.6),Vector3(side*.64,-3.84,.43),accent,false)
		_box(torso,Vector3(.43,.82,.23),Vector3(side*.64,-2.45,.36),armor,false)
	var head := _body("Head",Vector3(0,6.95,0),6,Vector3(1.35,1.23,3.1))
	_box(head,Vector3(1.38,1.26,3.13),Vector3.ZERO,armor,false)
	_box(head,Vector3(.88,.14,.08),Vector3(0,.16,1.62),accent,false)
	_joint("FloorPivot","Base","Torso",Vector3(0,.5,0),-.36,.36)
	_joint("Neck","Torso","Head",Vector3(0,6.12,0),-.28,.28)
	for side: float in [-1,1]:
		var prefix := "Left" if side < 0 else "Right"
		var up := _body(prefix+"UpperArm",Vector3(side*1.8,5.24,0),4,Vector3(.7,1.4,3.35))
		var low := _body(prefix+"Forearm",Vector3(side*1.8,3.77,0),5,Vector3(.83,1.4,3.35))
		_box(up,Vector3(.74,1.4,3.38),Vector3.ZERO,metal,false)
		_box(low,Vector3(.86,1.4,3.38),Vector3.ZERO,armor,false)
		_box(low,Vector3(.89,.12,3.41),Vector3(0,.37,0),accent,false)
		_joint(prefix+"Shoulder","Torso",prefix+"UpperArm",Vector3(side*1.8,5.98,0),-1.1,1.1)
		_joint(prefix+"Elbow",prefix+"UpperArm",prefix+"Forearm",Vector3(side*1.8,4.51,0),-1.65,.05)
	for key: String in parts: poses[key] = parts[key].global_transform
	var label := Label3D.new()
	label.name = "Nameplate"
	label.text = "МАНЕКЕН"
	label.position = Vector3(0,8.35,0)
	label.font_size = 28
	label.pixel_size = .008
	label.modulate = Color("9da9ae")
	label.no_depth_test = true
	add_child(label)
	initialized = true

func _material(color: Color, metallic: float) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = .78
	mat.metallic = metallic
	return mat

func _box(parent: Node3D, size_value: Vector3, point: Vector3, mat: Material, collision: bool) -> void:
	var visual := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size_value
	visual.mesh = mesh
	visual.material_override = mat
	visual.position = point
	parent.add_child(visual)
	if collision:
		var proxy := CollisionShape3D.new()
		var shape := BoxShape3D.new()
		shape.size = size_value
		proxy.shape = shape
		proxy.position = point
		parent.add_child(proxy)

func _ring(parent: Node3D, radius: float, _outer: float, point: Vector3, mat: Material) -> void:
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = .08
	mesh.radial_segments = 24
	mesh.rings = 1
	var visual := MeshInstance3D.new()
	visual.mesh = mesh
	visual.material_override = mat
	visual.rotation.x = PI*.5
	visual.position = point
	parent.add_child(visual)

func _body(key: String, point: Vector3, mass_value: float, size_value: Vector3) -> RigidBody3D:
	var body := RigidBody3D.new()
	body.name = key
	body.set_script(BodyScript)
	body.position = point
	body.mass = mass_value
	body.collision_layer = 4
	body.collision_mask = 3
	body.axis_lock_linear_z = true
	body.axis_lock_angular_x = true
	body.axis_lock_angular_y = true
	body.linear_damp = .4
	body.angular_damp = 1.8
	body.continuous_cd = true
	body.contact_monitor = true
	body.max_contacts_reported = 8
	body.can_sleep = false
	body.set("max_spin",7.0)
	body_root.add_child(body)
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size_value
	collision.shape = shape
	body.add_child(collision)
	parts[key] = body
	return body

func _joint(key: String, a: String, b: String, point: Vector3, lower: float, upper: float) -> void:
	var joint := HingeJoint3D.new()
	joint.name = key
	joint.position = point
	joint.node_a = NodePath("../Bodies/"+a)
	joint.node_b = NodePath("../Bodies/"+b)
	joint.exclude_nodes_from_collision = true
	joint.solver_priority = 4
	joint.set_flag(HingeJoint3D.FLAG_USE_LIMIT,true)
	joint.set_param(HingeJoint3D.PARAM_LIMIT_LOWER,-upper)
	joint.set_param(HingeJoint3D.PARAM_LIMIT_UPPER,-lower)
	joint.set_param(HingeJoint3D.PARAM_LIMIT_BIAS,.2)
	add_child(joint)

func _physics_process(_delta: float) -> void:
	if not initialized or not enabled: return
	# Physical torsion spring; no movement, aiming, attacks, balance AI or damage logic.
	var angle := wrapf(torso.rotation.z,-PI,PI)
	torso.apply_torque(Vector3(0,0,-angle*6200.0-torso.angular_velocity.z*1100.0))
	max_deflection = maxf(max_deflection,absf(angle))

func register_hit(_point: Vector3, strength: float) -> void:
	hit_count += 1
	last_strength = strength
	flash = maxf(flash,strength)

func _process(delta: float) -> void:
	flash = move_toward(flash,0,delta*3.0)
	if target_material != null: target_material.emission_energy_multiplier = flash*.5

func set_enabled(value: bool) -> void:
	enabled = value
	for part: RigidBody3D in parts.values(): part.freeze = not value

func reset_stance() -> void:
	for key: String in parts:
		parts[key].reset_pose = poses[key]
		parts[key].reset_requested = true
		parts[key].sleeping = false
	hit_count = 0
	last_strength = 0
	max_deflection = 0
	flash = 0
