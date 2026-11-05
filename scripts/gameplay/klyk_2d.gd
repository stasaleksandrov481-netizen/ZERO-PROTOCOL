extends RigidBody2D
## Support damage cannot deliver the player's final blow.
const Textures = preload("res://scripts/systems/texture_source.gd")
const ATLAS_PATH := "res://assets/creatures/klyk_atlas.png"
@export_file("*.png") var atlas_path := ATLAS_PATH
var initialized := false
var startup_error := ""
signal defeated
signal landed(strength: float)
signal planted(point: Vector2,strength: float)
var target: Node2D
var enabled := true
var ai_enabled := true
var state := "idle"
const Armor = preload("res://scripts/systems/impact_armor.gd")
const MAX_HEALTH := Armor.MAX_HEALTH
var armor: Armor = Armor.new()
var health: float:
 get: return armor.health
 set(value): armor.health = value
var combat_time := 0.0
const Balance = preload("res://scripts/systems/balance_response.gd")
var balance: Balance = Balance.new()
var rng := RandomNumberGenerator.new()
var behavior := "idle"
var behavior_age := 0.0
var decision_clock := 0.0
var evade_cooldown := 0.0
var charge_cooldown := 1.5
var threat_age := 0.0
var attack_direction := -1.0
var attack_kind := "claw"
var desired_speed := 0.0
var gait := 0.0
var move_blend := 0.0
var telegraph := ""
var last_defender: Node2D
var last_hit_direction := Vector2.LEFT
var last_hit_point := Vector2.ZERO
var state_visits: Dictionary = {}
const Limb = preload("res://scripts/gameplay/creature_part_2d.gd")
const Chain = preload("res://scripts/gameplay/atlant_2d_controller.gd")
const G := 627.2
const REST_Y := -330.0
const UPPER := 145.143
const LOWER := 134.863
const ARM := 198.893
var parts: Dictionary = {}
var rest_poses: Dictionary = {}
var joints: Array[PinJoint2D] = []
var total_mass := 0.0
var head_body: RigidBody2D
var arm_bodies: Array[RigidBody2D] = []
var leg_rigs: Array[Dictionary] = []
var reset_pending := false
var reset_transform: Transform2D
var previous_foot_contacts: Array[bool] = [false,false]
var last_plants: Array[float] = [-10.0,-10.0]
var attack_clock := 0.0
var clock := 0.0
var atlas: Texture2D
var collider_bindings: Array[Dictionary] = []
var attack_time := -1.0
var attack_landed := false
var hit_tween: Tween
var cutout: ShaderMaterial
func _ready() -> void:
 mass = 31;total_mass = mass;inertia = mass*(250.0*250.0+300.0*300.0)/12.0
 angular_damp = 1.2;collision_layer = 4;collision_mask = 7;lock_rotation = false
 contact_monitor = true;max_contacts_reported = 12;continuous_cd = RigidBody2D.CCD_MODE_CAST_SHAPE;can_sleep = false
 rng.randomize()
 atlas = Textures.png(atlas_path)
 if atlas == null:
  startup_error = Textures.last_error;enabled = false;freeze = true;set_physics_process(false);return
 var material := PhysicsMaterial.new();material.friction = .76;material.bounce = 0;physics_material_override = material
 cutout = ShaderMaterial.new();cutout.shader = preload("res://resources/theme/at01_cutout_2d.gdshader")
 parts.Core = self;set_meta("creature_owner",self)
 _sprite(self,0,Vector2(0,-45),Vector2(.69,.74),0)
 head_body = _body("Head",8,Vector2(-115,-170),0,3,1)
 _sprite(head_body,1,Vector2.ZERO,Vector2(.69,.69),0)
 _joint("Neck",self,head_body,Vector2(-42,-115),-.40,.70)
 for side in range(2):
  var prefix := "Far" if side == 0 else "Near"
  var layer := -2 if side == 0 else 1
  var tint := Color(.62,.70,.77) if side == 0 else Color(.84,.88,.92)
  var hip := Vector2(28 if side == 0 else -28,30)
  var aim := Vector2(42 if side == 0 else -42,249)-hip
  var angles := Chain.solve_chain(aim,UPPER,LOWER,1)
  var knee := hip+Vector2.DOWN.rotated(angles.x)*UPPER
  var ankle := knee+Vector2.DOWN.rotated(angles.y)*LOWER
  var up := _body(prefix+"Thigh",7,hip+Vector2.DOWN.rotated(angles.x)*UPPER*.5,angles.x,layer,2)
  _limb_art(up,2,Vector2(250,65),Vector2(230,380),Vector2(.42,.46));up.modulate = tint
  var low := _body(prefix+"Shin",3,knee+Vector2.DOWN.rotated(angles.y)*LOWER*.5,angles.y,layer,4)
  _limb_art(low,4,Vector2(295,70),Vector2(183,388),Vector2(.40,.40));low.modulate = tint
  var foot := _body(prefix+"Foot",2,ankle,0,layer,6)
  _sprite(foot,6,Vector2.ZERO,Vector2(.43,.43),0,Vector2(340,180));foot.modulate = tint
  _joint(prefix+"Hip",self,up,hip,-1.35,1.35)
  _joint(prefix+"Knee",up,low,knee,-2.2,-.015)
  _joint(prefix+"Ankle",low,foot,ankle,-.95,.95)
  leg_rigs.append({"up":up,"low":low,"foot":foot,"hip":hip})
  var shoulder := Vector2(55 if side == 0 else 15,-100)
  var arm := _body(prefix+"Arm",6,shoulder+Vector2.DOWN.rotated(.85)*ARM*.5,.85,-2 if side == 0 else 2,3)
  _limb_art(arm,3,Vector2(315,50),Vector2(190,390),Vector2(.46,.56));arm.modulate = tint
  _joint(prefix+"Shoulder",self,arm,shoulder,.35,1.45);arm_bodies.append(arm)
 # The two depth lanes can overlap in this side view; head and non-adjacent limbs still collide.
 for a_key: String in ["FarThigh","FarShin","FarFoot","FarArm"]:
  for b_key: String in ["NearThigh","NearShin","NearFoot","NearArm"]: parts[a_key].add_collision_exception_with(parts[b_key])
 for key: String in parts: rest_poses[key] = global_transform.affine_inverse()*parts[key].global_transform
 initialized = parts.size() == 10 and joints.size() == 9
 if not initialized: startup_error = "Не собран физический риг Клыка."
func _body(key: String,mass_value: float,offset: Vector2,angle: float,layer: int,index: int) -> RigidBody2D:
 var body := Limb.new();body.name = key;body.creature = self;body.part_index = index
 body.set_as_top_level(true);body.position = global_transform*offset;body.rotation = global_rotation+angle
 body.mass = mass_value;body.inertia = mass_value*1600;body.linear_damp = .35;body.angular_damp = 1.0
 body.collision_layer = 4;body.collision_mask = 7;body.physics_material_override = physics_material_override
 body.can_sleep = false;body.continuous_cd = RigidBody2D.CCD_MODE_CAST_SHAPE
 body.contact_monitor = true;body.max_contacts_reported = 12;body.max_spin = 6
 body.z_as_relative = false;body.z_index = z_index+layer;body.set_meta("creature_owner",self)
 add_child(body);parts[key] = body;total_mass += mass_value;return body
func _sprite(body: RigidBody2D,index: int,offset: Vector2,scale_value: Vector2,angle: float,pivot: Vector2 = Vector2.INF) -> Sprite2D:
 var cell := Vector2(atlas.get_width()/4.0,atlas.get_height()/2.0)
 if not pivot.is_finite(): pivot = cell*.5
 var sprite := Sprite2D.new();var region := AtlasTexture.new();region.atlas = atlas
 region.region = Rect2(Vector2(index%4,index/4)*cell,cell);region.filter_clip = true
 sprite.texture = region;sprite.centered = false;sprite.offset = -pivot;sprite.position = offset
 sprite.scale = scale_value;sprite.rotation = angle;sprite.material = cutout;body.add_child(sprite)
 var points := PackedVector2Array()
 for point: Vector2 in preload("res://scripts/models/collision_profiles.gd").KLYK[index]: points.append((point-pivot)*scale_value)
 var shape := ConvexPolygonShape2D.new();shape.points = points
 var collision := CollisionShape2D.new();collision.name = "Collision";collision.shape = shape
 collision.transform = Transform2D(angle,offset);collision.set_meta("part",index);body.add_child(collision)
 collider_bindings.append({"sprite":sprite,"collision":collision,"body":body})
 if body != self:
  var bounds := Rect2(points[0],Vector2.ZERO)
  for point: Vector2 in points: bounds = bounds.expand(point)
  body.inertia = body.mass*(bounds.size.x*bounds.size.x+bounds.size.y*bounds.size.y)/12.0
 return sprite
func _limb_art(body: RigidBody2D,index: int,a: Vector2,b: Vector2,scale_value: Vector2) -> void:
 var line := (b-a)*scale_value
 _sprite(body,index,Vector2(0,-line.length()*.5),scale_value,-atan2(-line.x,line.y),a)
func _joint(key: String,a: RigidBody2D,b: RigidBody2D,offset: Vector2,lower: float,upper: float) -> void:
 var pin := PinJoint2D.new();pin.name = key;pin.set_as_top_level(true);pin.position = global_transform*offset
 pin.node_a = a.get_path();pin.node_b = b.get_path();pin.disable_collision = true;pin.softness = 0;pin.bias = .3
 pin.set_meta("rest_offset",offset)
 pin.set_meta("child_body",b)
 pin.angular_limit_enabled = false;add_child(pin);joints.append(pin)
 b.configure_stop(a,global_transform*offset,lower,upper)
func _sync_colliders() -> void:
 # Each silhouette now belongs to its own rigid body, never to an animated proxy.
 for binding: Dictionary in collider_bindings:
  var sprite: Node2D = binding.sprite
  var pose := Transform2D(sprite.rotation,sprite.position)
  if not binding.collision.transform.is_equal_approx(pose): binding.collision.transform = pose
func owns_collider(body: PhysicsBody2D) -> bool:
 return body == self or (is_instance_valid(body) and body.get_meta("creature_owner",null) == self)
func reset_stance(spawn: Vector2) -> void:
 var base := Transform2D(0,spawn);reset_transform = base;reset_pending = true
 if freeze: global_transform = base;linear_velocity = Vector2.ZERO;angular_velocity = 0
 for key: String in parts:
  if key == "Core": continue
  var body = parts[key];body.reset_pose = base*rest_poses[key];body.reset_requested = true
  if body.freeze: body.global_transform = body.reset_pose;body.linear_velocity = Vector2.ZERO;body.angular_velocity = 0
 for pin: PinJoint2D in joints: pin.global_position = base*Vector2(pin.get_meta("rest_offset"))
 balance.clear();behavior = "idle";state = "idle";attack_time = -1;attack_clock = 0;gait = 0;move_blend = 0
func _set_behavior(value: String) -> void:
 if behavior == value: return
 behavior = value;behavior_age = 0;state_visits[value] = int(state_visits.get(value,0))+1
func _incoming_threat() -> bool:
 if not is_instance_valid(target): return false
 for key: String in ["LeftForearm","RightForearm"]:
  var hand: RigidBody2D = target.parts[key]
  var separation := position.x-hand.global_position.x
  if absf(separation) < 430 and absf(hand.global_position.y-position.y) < 290 and hand.linear_velocity.x*signf(separation) > 85: return true
 return false
func _begin_attack(kind: String,direction: float) -> void:
 attack_kind = kind;attack_direction = direction;attack_time = 0;attack_landed = false
 attack_clock = 2.7 if kind == "claw" else 3.6
 _set_behavior("windup")
func _choose_action(dx: float) -> void:
 var distance := absf(dx);var toward := signf(dx)
 if _incoming_threat(): threat_age += .1
 else: threat_age = maxf(0,threat_age-.2)
 if threat_age >= .18 and evade_cooldown <= 0 and distance < 600:
  evade_cooldown = 4.2;threat_age = 0;attack_direction = toward
  _set_behavior("evade");return
 if target.fallen:
  desired_speed = -toward*60 if distance < 470 else toward*55
  _set_behavior("stalk");return
 if distance > 670 and charge_cooldown <= 0:
  charge_cooldown = 7;attack_direction = toward;_set_behavior("charge_windup");return
 if distance > 355:
  desired_speed = toward*135;_set_behavior("pursue")
 elif attack_clock <= 0:
  _begin_attack("heavy" if rng.randf() < .36 else "claw",toward)
 else:
  desired_speed = -toward*85 if distance < 260 else (toward*42 if distance > 325 else 0.0)
  _set_behavior("guard" if distance <= 325 else "reposition")
func _physics_process(delta: float) -> void:
 if not enabled or state == "dead" or not is_instance_valid(target): return
 clock += delta;combat_time += delta;behavior_age += delta
 armor.tick(delta)
 attack_clock = maxf(0,attack_clock-delta);evade_cooldown = maxf(0,evade_cooldown-delta);charge_cooldown = maxf(0,charge_cooldown-delta)
 var angle := wrapf(rotation,-PI,PI)
 if absf(angle) > 1.0 and not balance.is_prone(): balance.fall(signf(angle))
 balance.tick(delta,absf(angle) < .25,_grounded())
 var dx: float = target.core.global_position.x-global_position.x
 if balance.state != "steady":
  attack_time = -1;desired_speed = 0;_set_behavior("recover")
 elif ai_enabled:
  match behavior:
   "evade":
    desired_speed = -attack_direction*180
    if behavior_age > .62: _set_behavior("guard")
   "charge_windup":
    desired_speed = 0
    if behavior_age > .60: _set_behavior("rush")
   "rush":
    desired_speed = attack_direction*235
    if absf(dx) < 380 or behavior_age > 1.4: _begin_attack("charge",attack_direction)
   "windup", "attack":
    attack_time += delta
    var windup := .42 if attack_kind == "claw" else .67
    desired_speed = attack_direction*(220 if attack_kind == "charge" else 155) if attack_time > windup else 0.0
    if attack_time > windup: _set_behavior("attack")
    if attack_time > windup+.42: attack_time = -1;_set_behavior("recovery")
   "recovery":
    desired_speed = 0
    if behavior_age > .78: _set_behavior("guard")
   _:
    decision_clock -= delta
    if decision_clock <= 0: decision_clock = .10;_choose_action(dx)
 var prone := balance.state in ["falling","down"]
 var rising := balance.state == "rising"
 var lean := balance.lean+clampf(linear_velocity.x/235.0,-1,1)*.11
 var stiffness := 5.5 if prone else (55.0 if rising else 120.0)
 var torque := inertia*(stiffness*wrapf(lean-angle,-PI,PI)-(4.0 if prone else (14.0 if rising else 22.0))*angular_velocity)
 apply_torque(clampf(torque,-inertia*(25 if prone else 100),inertia*(25 if prone else 100)))
 var supported := _support()
 if rising: supported = maxf(.85,supported)
 if prone: supported = 0
 var run := 1.0 if behavior == "rush" else 0.0
 var error := REST_Y+run*20-absf(sin(gait))*4*move_blend-position.y
 var vertical := total_mass*(error*32-linear_velocity.y*8)-total_mass*G*.42
 apply_central_force(Vector2(0,clampf(vertical,-total_mass*G*2.1,total_mass*G)*supported))
 if not prone and not rising:
  var traction := signf(desired_speed)*G*.55 if absf(desired_speed) > 1 and _grounded() else 0.0
  var acceleration := clampf((desired_speed-linear_velocity.x)*4.0+traction,-780,780)
  if balance.state == "stagger": acceleration *= .16
  apply_central_force(Vector2(acceleration*total_mass*supported,0))
 _animate(delta)
 state = "attack" if behavior == "attack" else behavior
 telegraph = {"charge_windup":"КЛЫК / ГОТОВИТ РЫВОК","rush":"КЛЫК / РЫВОК","windup":"КЛЫК / ЗАМАХ","evade":"КЛЫК / УКЛОНЕНИЕ","recover":"КЛЫК / ЛОВИТ РАВНОВЕСИЕ"}.get(behavior,"")
 if balance.is_prone(): telegraph = "КЛЫК / ПОДНИМАЕТСЯ" if rising else "КЛЫК / НА ЗЕМЛЕ"
 _sync_colliders()
func _grounded() -> bool:
 for key: String in parts:
  if key != "Core" and parts[key].support_contacts > 0: return true
 for body: Node2D in get_colliding_bodies():
  if body is StaticBody2D and (body.collision_layer & 1) != 0: return true
 return false
func _support() -> float:
 for rig: Dictionary in leg_rigs:
  if rig.foot.global_position.y > -130 or rig.foot.support_contacts > 0: return 1.0
 return .15
func _motor_part(body: RigidBody2D,parent: RigidBody2D,target_angle: float,k: float,damping: float,power: float) -> void:
 var relative := wrapf(body.rotation-parent.rotation,-PI,PI)
 var target_limit := clampf(target_angle,body.limit_lower+.025,body.limit_upper-.025)
 var anchor: Vector2 = parent.global_transform*body.anchor_parent
 var effective_inertia: float = body.inertia+body.mass*body.global_position.distance_squared_to(anchor)
 var gravity: float = -body.mass*G*(body.global_position.x-anchor.x)
 var torque: float = effective_inertia*(k*(target_limit-relative)-damping*(body.angular_velocity-parent.angular_velocity))+gravity
 torque = clampf(torque,-body.inertia*power,body.inertia*power)
 body.apply_torque(torque);parent.apply_torque(-torque)
func _animate(delta: float) -> void:
 var prone := balance.state in ["falling","down"]
 move_blend = move_toward(move_blend,0 if balance.is_prone() else clampf(absf(linear_velocity.x)/135,0,1),delta*1.8)
 var running := behavior == "rush"
 gait += delta*minf(absf(linear_velocity.x)*PI/(280.0 if running else 185.0),2.65)*move_blend
 _motor_part(head_body,self,sin(gait+.5)*.025*move_blend+sin(clock*1.4)*.006,8 if prone else 14,3.5 if prone else 2.8,24)
 for i in range(2):
  var rig: Dictionary = leg_rigs[i];var phase := gait+i*PI
  if prone:
   _motor_part(rig.up,self,.55,10,6,70);_motor_part(rig.low,rig.up,-1.3,10,6,70);_motor_part(rig.foot,rig.low,.3,10,6,70)
  else:
   var direction := signf(linear_velocity.x) if absf(linear_velocity.x) > 10 else signf(desired_speed)
   var x := lerpf(42.0 if i == 0 else -42.0,sin(phase)*(125 if running else 85)*direction,move_blend)
   var lift := maxf(0,cos(phase))*(112 if running else 92)*move_blend
   x += balance.direction*balance.catch_step*(40 if i == 0 else 65)
   lift = maxf(lift,maxf(0,sin(balance.age*6+i*PI))*45*balance.catch_step)
   var hip: Vector2 = global_transform*Vector2(rig.hip)
   var target_position := Vector2(position.x+x,-81-lift)-hip
   var angles := Chain.solve_chain(target_position,UPPER,LOWER,1)
   _motor_part(rig.up,self,angles.x-rotation,95,18,350)
   _motor_part(rig.low,rig.up,angles.y-rig.up.rotation,105,19,350)
   _motor_part(rig.foot,rig.low,-rig.low.rotation,125,20,280)
  var touching: bool = rig.foot.support_contacts > 0
  if touching and not previous_foot_contacts[i] and clock-last_plants[i] > .4:
   last_plants[i] = clock;planted.emit(rig.foot.global_position,clampf(rig.foot.contact_impulse/1800+move_blend*.55+(.2 if running else 0),.35,1))
  previous_foot_contacts[i] = touching
  var arm: RigidBody2D = arm_bodies[i]
  var arm_angle := .85+sin(phase+PI)*.12*move_blend
  if attack_time >= 0:
   var windup := .42 if attack_kind == "claw" else .67
   var arm_time := maxf(0,attack_time-i*.07)
   if arm_time <= windup: arm_angle = lerpf(.85,.95,smoothstep(0,1,arm_time/windup))
   else: arm_angle = lerpf(.95,1.25,smoothstep(0,1,(arm_time-windup)/.29))
  if balance.state == "stagger": arm_angle += balance.direction*balance.catch_step*.23
  _motor_part(arm,self,arm_angle,8 if prone else 55,5 if prone else 11,170)
func _integrate_forces(physics: PhysicsDirectBodyState2D) -> void:
 if reset_pending:
  physics.transform = reset_transform;physics.linear_velocity = Vector2.ZERO;physics.angular_velocity = 0;reset_pending = false;return
 physics.angular_velocity = clampf(physics.angular_velocity,-2.4,2.4)
 if physics.linear_velocity.length() > 1000: physics.linear_velocity = physics.linear_velocity.limit_length(1000)
func try_attack_contact(physics: PhysicsDirectBodyState2D,part_index: int) -> void:
 if not enabled or state == "dead" or part_index not in [1,3]: return
 var windup := .42 if attack_kind == "claw" else .67
 if balance.state != "steady" or attack_landed or attack_time < windup or attack_time > windup+.38: return
 for i in range(physics.get_contact_count()):
  var other := physics.get_contact_collider_object(i)
  if not other is RigidBody2D or not other.has_meta("damage_part"): continue
  if str(other.get_meta("damage_part")) not in ["Head","Core"]: continue
  var defender = other.get_parent().get_parent()
  if not defender.has_method("receive_impact"): continue
  last_defender = defender;last_hit_point = physics.get_contact_collider_position(i);last_hit_direction = Vector2(attack_direction,0)
  attack_landed = true;landed.emit(.24 if attack_kind == "claw" else (.60 if attack_kind == "charge" else .48));break
func register_hit(strength: float,support: bool = false,direction: Vector2 = Vector2.RIGHT,point: Vector2 = Vector2.ZERO) -> void:
 if state == "dead" or not enabled: return
 strength = clampf(strength,0,1)
 armor.hit(strength,support,behavior == "guard")
 var push := signf(direction.x)
 if push == 0: push = 1
 apply_central_impulse(Vector2(push*(18+strength*70),-strength*3)*mass)
 if strength >= .20:
  balance.hit(strength,push,move_blend,_grounded(),behavior in ["windup","attack","rush"]);apply_torque_impulse(inertia*push*strength*.62)
 if is_instance_valid(hit_tween): hit_tween.kill()
 modulate = Color(1.20,.91,.83);hit_tween = create_tween();hit_tween.tween_property(self,"modulate",Color.WHITE,.24)
 if health <= 0:
  state = "dead";enabled = false;collision_layer = 8;collision_mask = 9;lock_rotation = false
  for key: String in parts:
   if key != "Core": parts[key].collision_layer = 8;parts[key].collision_mask = 9
  apply_torque_impulse(-65000);defeated.emit()
func set_enabled(value: bool) -> void:
 for pin: PinJoint2D in joints:
  var child = pin.get_meta("child_body")
  pin.global_position = child.limit_parent.global_transform*child.anchor_parent
 enabled = value;freeze = not value
 for key: String in parts:
  if key != "Core": parts[key].freeze = not value
