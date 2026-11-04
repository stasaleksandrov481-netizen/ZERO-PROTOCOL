extends RefCounted
const Controller = preload("res://scripts/gameplay/atlant_2d_controller.gd")
const Part = preload("res://scripts/gameplay/atlant_2d_part.gd")
const SpriteArt = preload("res://scripts/models/atlant_2d_skin.gd")
const P := 64.0
var startup_error := ""
var robot: Node2D
var bodies: Node2D
var joints: Node2D
var body_map: Dictionary = {}
var contact_material: PhysicsMaterial
func create(spawn_x: float = 0.0) -> Node2D:
 if not SpriteArt.prepare(): startup_error = SpriteArt.last_error;return null
 robot = Node2D.new()
 robot.name = "AT01"
 robot.set_meta("skin",SpriteArt.SKIN_ID)
 robot.set_meta("view_profile","strict_right_side_2d")
 robot.set_script(Controller)
 bodies = Node2D.new();bodies.name = "Bodies";_child(robot,bodies)
 joints = Node2D.new();joints.name = "Joints";_child(robot,joints)
 contact_material = PhysicsMaterial.new();contact_material.friction = .68;contact_material.bounce = 0
 _body("Core",Vector2(0,-6.35)*P,Vector2(1.9,3.0)*P,31,"core",0,false,2)
 _body("Head",Vector2(38.5,-527.5),Vector2(104,70),4,"head",0,false,4)
 _joint("Neck","Core","Head",Vector2(28,-505),-.28,.28)
 for index in range(2):
  var prefix := "Left" if index == 0 else "Right"
  var far := index == 0
  var shoulder := Vector2(.58 if far else -.62,-7.18)*P
  var resting := Vector2(-.25 if far else .50,3.10)*P
  var angles: Vector2 = Controller.solve_chain(resting,1.65*P,1.72*P,1.0)
  _chain(prefix+"UpperArm",prefix+"Forearm",shoulder,angles,1.65*P,1.72*P,7,7.5,"upper_arm","forearm",far,0 if far else 4)
  _joint(prefix+"Shoulder","Core",prefix+"UpperArm",shoulder,Controller.SHOULDER_MIN,Controller.SHOULDER_MAX)
  var elbow := shoulder+Vector2.DOWN.rotated(angles.x)*1.65*P
  _joint(prefix+"Elbow",prefix+"UpperArm",prefix+"Forearm",elbow,-2.7,-.025)
  var hip := Vector2(.33 if far else -.33,-4.65)*P
  var foot_x := .60 if far else -.60
  var target := Vector2(foot_x,-.60)*P-hip
  var legs: Vector2 = Controller.solve_chain(target,2.1*P,2.1*P,-1.0)
  _chain(prefix+"Thigh",prefix+"Shin",hip,legs,2.1*P,2.1*P,7,4.6,"thigh","shin",far,0 if far else 3)
  var knee := hip+Vector2.DOWN.rotated(legs.x)*2.1*P
  var ankle := knee+Vector2.DOWN.rotated(legs.y)*2.1*P
  _body(prefix+"Foot",ankle+Vector2(.24,.28)*P,Vector2(1.9,.64)*P,2.4,"foot",0,far,0 if far else 3)
  _joint(prefix+"Hip","Core",prefix+"Thigh",hip,-1.35,1.25)
  _joint(prefix+"Knee",prefix+"Thigh",prefix+"Shin",knee,.015,2.2)
  _joint(prefix+"Ankle",prefix+"Shin",prefix+"Foot",ankle,-.62,.62)
 for body in body_map.values(): body.position.x += spawn_x
 for joint in joints.get_children(): joint.position.x += spawn_x
 return robot
func _child(parent: Node, child: Node) -> void:
 parent.add_child(child);child.owner = robot
func _body(key: String, point: Vector2, size_value: Vector2, mass_value: float, kind: String, length: float, far: bool, layer: int) -> RigidBody2D:
 var body := RigidBody2D.new()
 body.name = key;body.set_script(Part);body.position = point;body.mass = mass_value
 body.set_meta("damage_part",key)
 body.inertia = mass_value*(size_value.x*size_value.x+size_value.y*size_value.y)/12.0
 if kind == "forearm": body.inertia += mass_value*.42*P*P
 body.linear_damp = .25;body.angular_damp = 1.05;body.can_sleep = false
 body.continuous_cd = RigidBody2D.CCD_MODE_CAST_SHAPE
 body.contact_monitor = true;body.max_contacts_reported = 8
 body.collision_layer = 2;body.collision_mask = 5;body.physics_material_override = contact_material
 body.set("max_spin",4.2 if kind in ["upper_arm","forearm"] else 11.0)
 _child(bodies,body)
 var proxy := CollisionShape2D.new();proxy.name = "Collision"
 if kind in ["upper_arm","forearm"]:
  var capsule := CapsuleShape2D.new();capsule.radius = (.34 if kind == "upper_arm" else .37)*P;capsule.height = length
  proxy.shape = capsule
 else:
  var box := RectangleShape2D.new();box.size = size_value;proxy.shape = box
 _child(body,proxy)
 # The armor silhouette includes the fist; a second oversized circle struck empty air.
 SpriteArt.attach(body,kind,length,far,layer)
 body_map[key] = body
 return body
func _chain(a: String,b: String,anchor: Vector2,angles: Vector2,la: float,lb: float,ma: float,mb: float,ka: String,kb: String,far: bool,layer: int) -> void:
 var elbow := anchor+Vector2.DOWN.rotated(angles.x)*la
 var first := _body(a,anchor+Vector2.DOWN.rotated(angles.x)*la*.5,Vector2(.80*P,la),ma,ka,la,far,layer)
 var second := _body(b,elbow+Vector2.DOWN.rotated(angles.y)*lb*.5,Vector2(.84*P,lb),mb,kb,lb,far,layer+1)
 first.rotation = angles.x;second.rotation = angles.y
func _joint(key: String,a: String,b: String,point: Vector2,lower: float,upper: float) -> void:
 var joint := PinJoint2D.new();joint.name = key;joint.position = point
 joint.node_a = NodePath("../../Bodies/"+a);joint.node_b = NodePath("../../Bodies/"+b)
 joint.disable_collision = true;joint.softness = 0.0;joint.bias = .3
 var rest: float = body_map[b].rotation-body_map[a].rotation
 joint.angular_limit_enabled = false
 joint.angular_limit_lower = lower-rest;joint.angular_limit_upper = upper-rest
 joint.set_meta("rest_angle",rest);joint.set_meta("anatomical_lower",lower);joint.set_meta("anatomical_upper",upper)
 joint.set_meta("parent_key",a);joint.set_meta("child_key",b)
 _child(joints,joint)
