extends Node2D
const Part = preload("res://scripts/gameplay/atlant_2d_part.gd")
const P := 64.0
var parts: Dictionary = {}
var poses: Dictionary = {}
var torso: RigidBody2D
var head: RigidBody2D
var body_root: Node2D
var target_panel: Node2D
var initialized := false
var enabled := true
var hit_count := 0
var max_deflection := 0.0
var last_strength := 0.0
var flash := 0.0
class DummyPanel extends Node2D:
 var panel_size := Vector2(80,120)
 var role := "armor"
 var flash := 0.0
 func _draw() -> void:
  if role == "torso":
   for side: float in [-1,1]:
    draw_rect(Rect2(Vector2(side*18-9,85),Vector2(18,173)),Color("353e43"))
    draw_rect(Rect2(Vector2(side*18-50,246),Vector2(82,18)),Color("66716f"))
  var style := StyleBoxFlat.new()
  style.bg_color = Color("667574") if role != "arm" else Color("39484d")
  style.border_color = Color("a1aeaa")
  style.set_border_width_all(2)
  style.set_corner_radius_all(7)
  draw_style_box(style,Rect2(-panel_size*.5,panel_size))
  if role == "torso":
   draw_rect(Rect2(Vector2(-49,-68),Vector2(98,135)),Color("27343a"))
   var target := Color("bc7550").lerp(Color("e8b96b"),flash)
   draw_circle(Vector2.ZERO,40,target)
   draw_circle(Vector2.ZERO,29,Color("ddd0a0"))
   draw_circle(Vector2.ZERO,17,target)
   draw_circle(Vector2.ZERO,6,Color("452f2b"))
  elif role == "head":
   draw_rect(Rect2(Vector2(-panel_size.x*.5+7,-9),Vector2(44,15)),Color("212e34"))
   draw_rect(Rect2(Vector2(-panel_size.x*.5+9,-6),Vector2(39,7)),Color("c8a269"))
  elif role == "forearm":
   draw_line(Vector2(-panel_size.x*.4,-panel_size.y*.25),Vector2(panel_size.x*.4,-panel_size.y*.25),Color("bd9b63"),6)
  for side: float in [-1,1]:
   draw_circle(Vector2(side*(panel_size.x*.5-8),-panel_size.y*.5+9),2.3,Color("2b363b"))
func _ready() -> void:
 body_root = Node2D.new();body_root.name = "Bodies";add_child(body_root)
 var base := StaticBody2D.new();base.name = "Base";base.collision_layer = 4;base.collision_mask = 2
 body_root.add_child(base)
 var base_proxy := CollisionShape2D.new();var base_shape := RectangleShape2D.new();base_shape.size = Vector2(3.6,.5)*P
 base_proxy.shape = base_shape;base_proxy.position = Vector2(0,-.25*P);base.add_child(base_proxy)
 var base_art := Polygon2D.new();base_art.polygon = PackedVector2Array([Vector2(-1.8,-.5),Vector2(1.8,-.5),Vector2(1.8,0),Vector2(-1.8,0)])
 base_art.scale = Vector2.ONE*P;base_art.color = Color("454f52");base.add_child(base_art)
 torso = _body("Torso",Vector2(0,-4.65)*P,Vector2(2.3,2.9)*P,42,"torso")
 torso.z_index = 2
 target_panel = torso.get_node("Panel")
 head = _body("Head",Vector2(-.15,-6.95)*P,Vector2(1.20,1.23)*P,6,"head")
 head.z_index = 2
 _joint("FloorPivot","Base","Torso",Vector2(0,-.5)*P,-.36,.36)
 _joint("Neck","Torso","Head",Vector2(0,-6.12)*P,-.28,.28)
 for side: float in [-1,1]:
  var prefix := "Left" if side < 0 else "Right"
  _body(prefix+"UpperArm",Vector2(-.8 if side < 0 else .35,-5.24)*P,Vector2(.7,1.4)*P,4,"arm")
  _body(prefix+"Forearm",Vector2(-.8 if side < 0 else .35,-3.77)*P,Vector2(.83,1.4)*P,5,"forearm")
  _joint(prefix+"Shoulder","Torso",prefix+"UpperArm",Vector2(-.8 if side < 0 else .35,-5.98)*P,-1.1,1.1)
  _joint(prefix+"Elbow",prefix+"UpperArm",prefix+"Forearm",Vector2(-.8 if side < 0 else .35,-4.51)*P,-.05,1.65)
  for suffix in ["UpperArm","Forearm"]:
   parts[prefix+suffix].z_index = 5 if side < 0 else -1
   parts[prefix+suffix].modulate = Color.WHITE if side < 0 else Color(.68,.72,.75,1)
 for key: String in parts: poses[key] = parts[key].global_transform
 var label := Label.new();label.text = "МАНЕКЕН";label.position = Vector2(-70,-8.35*P);label.size = Vector2(140,32)
 label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER;label.add_theme_font_size_override("font_size",19);label.modulate = Color("a0aaa8");add_child(label)
 initialized = true
 set_process(false)
func _body(key: String,point: Vector2,size_value: Vector2,mass_value: float,role: String) -> RigidBody2D:
 var body := RigidBody2D.new();body.name = key;body.set_script(Part);body.position = point;body.mass = mass_value
 body.collision_layer = 4;body.collision_mask = 3;body.angular_damp = 1.8;body.linear_damp = .4
 body.continuous_cd = RigidBody2D.CCD_MODE_CAST_SHAPE;body.contact_monitor = true;body.max_contacts_reported = 8;body.can_sleep = false
 body_root.add_child(body)
 var proxy := CollisionShape2D.new();var shape := RectangleShape2D.new();shape.size = size_value;proxy.shape = shape;body.add_child(proxy)
 var panel := DummyPanel.new();panel.name = "Panel";panel.panel_size = size_value;panel.role = role;body.add_child(panel)
 parts[key] = body
 return body
func _joint(key: String,a: String,b: String,point: Vector2,lower: float,upper: float) -> void:
 var pin := PinJoint2D.new();pin.name = key;pin.position = point;pin.node_a = NodePath("../Bodies/"+a);pin.node_b = NodePath("../Bodies/"+b)
 pin.disable_collision = true;pin.angular_limit_enabled = false;add_child(pin)
 parts[b].configure_stop(body_root.get_node(a),pin.global_position,lower,upper)
func _physics_process(_delta: float) -> void:
 if not initialized or not enabled: return
 torso.apply_torque((-wrapf(torso.rotation,-PI,PI)*6200-torso.angular_velocity*1100)*P*P)
 var neck := wrapf(head.rotation-torso.rotation,-PI,PI)
 var neck_torque := (-neck*450-(head.angular_velocity-torso.angular_velocity)*90)*P*P
 head.apply_torque(neck_torque);torso.apply_torque(-neck_torque)
 max_deflection = maxf(max_deflection,absf(wrapf(torso.rotation,-PI,PI)))
func _process(delta: float) -> void:
 flash = move_toward(flash,0,delta*3)
 if is_instance_valid(target_panel): target_panel.flash = flash;target_panel.queue_redraw()
 if flash == 0: set_process(false)
func register_hit(_point: Vector2,strength: float) -> void:
 hit_count += 1;last_strength = strength;flash = maxf(flash,strength)
 set_process(true)
func set_enabled(value: bool) -> void:
 enabled = value
 for part: RigidBody2D in parts.values(): part.freeze = not value
func reset_stance() -> void:
 for key: String in parts:
  parts[key].reset_pose = poses[key];parts[key].reset_requested = true;parts[key].sleeping = false
 hit_count = 0;last_strength = 0;max_deflection = 0;flash = 0
