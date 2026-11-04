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
var leg_rigs: Array[Dictionary] = []
var lifted: Array[bool] = [false,false]
var last_plants: Array[float] = [-10.0,-10.0]
var attack_clock := 0.0
var clock := 0.0
var atlas: Texture2D
var limbs: Array[Node2D] = []
var collider_bindings: Array[Dictionary] = []
var attack_time := -1.0
var attack_landed := false
var hit_tween: Tween
var cutout: ShaderMaterial
func _ready() -> void:
 mass = 75;inertia = mass*(210.0*210.0+610.0*610.0)/12.0;angular_damp = 2.0;collision_layer = 4;collision_mask = 3;lock_rotation = false;contact_monitor = true;max_contacts_reported = 8;continuous_cd = RigidBody2D.CCD_MODE_CAST_SHAPE
 rng.randomize()
 atlas = Textures.png(atlas_path)
 if atlas == null:
  startup_error = Textures.last_error;enabled = false;freeze = true;set_physics_process(false);return
 var material := PhysicsMaterial.new();material.friction = .85;material.bounce = 0;physics_material_override = material
 cutout = ShaderMaterial.new();cutout.shader = preload("res://resources/theme/at01_cutout_2d.gdshader")
 _part(0,Vector2(0,-45),Vector2(.69,.74),0)
 _part(1,Vector2(-115,-170),Vector2(.69,.69),2)
 for side in range(2):
  var tint := Color(.62,.70,.77) if side == 0 else Color(.84,.88,.92)
  var offset := -30.0 if side == 0 else 30.0
  var leg := Node2D.new();leg.position = Vector2(offset,63);leg.z_index = -1 if side == 0 else 1;add_child(leg);limbs.append(leg)
  var thigh := _part(2,Vector2(0,30),Vector2(.42,.50),0,leg);thigh.modulate = tint
  var shin := _part(4,Vector2(-5,135),Vector2(.40,.46),0,leg);shin.modulate = tint
  var foot := _part(6,Vector2(-41,204),Vector2(.47,.40),0,leg);foot.modulate = tint
  leg_rigs.append({"hip":leg,"shin":shin,"foot":foot,"x":offset})
  var arm := Node2D.new();arm.position = Vector2(-15+offset,-95);arm.z_index = -2 if side == 0 else 3;add_child(arm);limbs.append(arm)
  _part(3,Vector2(-40,95),Vector2(.44,.55),0,arm).modulate = tint
 _sync_colliders()
 initialized = true
func _part(index: int,p: Vector2,scale_value: Vector2,layer: int,parent: Node = self) -> Sprite2D:
 if atlas == null: return null
 var sprite := Sprite2D.new();var region := AtlasTexture.new();region.atlas = atlas
 var cell := Vector2(atlas.get_width()/4.0,atlas.get_height()/2.0);region.region = Rect2(Vector2(index%4,index/4)*cell,cell);region.filter_clip = true
 sprite.texture = region;sprite.position = p;sprite.scale = scale_value;sprite.z_index = layer;sprite.material = cutout;parent.add_child(sprite)
 var polygon := PackedVector2Array()
 for point: Vector2 in preload("res://scripts/models/collision_profiles.gd").KLYK[index]: polygon.append((point-cell*.5)*scale_value)
 var shape := ConvexPolygonShape2D.new();shape.points = polygon
 var collision := CollisionShape2D.new();collision.name = "HeadCollision" if index == 1 else "PartCollision%d_%d"%[index,collider_bindings.size()];collision.shape = shape;collision.set_meta("part",index);add_child(collision)
 collider_bindings.append({"sprite":sprite,"collision":collision});return sprite
func _sync_colliders() -> void:
 for binding: Dictionary in collider_bindings:
  var sprite: Node2D = binding.sprite
  # Scale is already baked into the polygon; the animated branch supplies its pose.
  binding.collision.transform = global_transform.affine_inverse()*sprite.get_parent().global_transform*Transform2D(sprite.rotation,sprite.position)
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
 else:
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
 var stiffness := 3.0 if prone else (25.0 if rising else 45.0)
 var torque := inertia*(stiffness*wrapf(lean-angle,-PI,PI)-(4.0 if prone else 12.0)*angular_velocity)
 apply_torque(clampf(torque,-inertia*9,inertia*9))
 if rising and absf(angle) > .5: apply_central_force(Vector2(0,-mass*627.2*.85))
 if not prone and not rising:
  # Stance traction must overcome the heavy compound feet's static friction.
  var traction := signf(desired_speed)*627.2*.83 if absf(desired_speed) > 1 and _grounded() else 0.0
  var acceleration := clampf((desired_speed-linear_velocity.x)*4.0+traction,-1000,1000)
  if balance.state == "stagger": acceleration *= .12
  apply_central_force(Vector2(acceleration*mass,0))
 _animate(delta)
 state = "attack" if behavior == "attack" else behavior
 telegraph = {"charge_windup":"КЛЫК / ГОТОВИТ РЫВОК","rush":"КЛЫК / РЫВОК","windup":"КЛЫК / ЗАМАХ","evade":"КЛЫК / УКЛОНЕНИЕ","recover":"КЛЫК / ЛОВИТ РАВНОВЕСИЕ"}.get(behavior,"")
 if balance.is_prone(): telegraph = "КЛЫК / ПОДНИМАЕТСЯ" if rising else "КЛЫК / НА ЗЕМЛЕ"
 _sync_colliders()
func _grounded() -> bool:
 for body: Node2D in get_colliding_bodies():
  if body is StaticBody2D and (body.collision_layer & 1) != 0: return true
 return false
func _animate(delta: float) -> void:
 move_blend = move_toward(move_blend,clampf(absf(linear_velocity.x)/140,0,1),delta*2)
 gait += delta*(2.6 if behavior == "rush" else 2.3)*move_blend
 for i in range(2):
  var rig: Dictionary = leg_rigs[i];var phase := gait+i*PI
  var catch_phase: float = balance.age*6+i*PI
  rig.hip.position = Vector2(float(rig.x)+sin(phase)*16*move_blend+balance.direction*balance.catch_step*30,63-maxf(0,cos(phase))*12*move_blend)
  rig.hip.rotation = sin(phase)*.21*move_blend+sin(catch_phase)*balance.catch_step*.23
  rig.shin.rotation = -maxf(0,cos(phase))*.18*move_blend
  rig.foot.rotation = -rig.hip.rotation
  rig.foot.position = Vector2(-41+sin(phase)*27*move_blend+balance.direction*balance.catch_step*35,204-maxf(0,cos(phase))*24*move_blend-maxf(0,sin(catch_phase))*balance.catch_step*26)
  var in_air := cos(phase) > 0
  if not in_air and lifted[i] and move_blend > .2 and not balance.is_prone() and clock-last_plants[i] > .4:
   last_plants[i] = clock;planted.emit(rig.foot.global_position,clampf(.45+move_blend*.35+(.2 if behavior == "rush" else 0),0,1))
  lifted[i] = in_air
  var arm: Node2D = limbs[i*2+1]
  arm.rotation = sin(phase+PI)*.22*move_blend
  if attack_time >= 0:
   var duration := 1.05 if attack_kind == "claw" else 1.32
   arm.rotation += sin(clampf(attack_time/duration,0,1)*PI)*(.72 if attack_kind != "claw" else .56)
  if balance.state == "stagger": arm.rotation -= balance.direction*balance.catch_step*.30
func _integrate_forces(physics: PhysicsDirectBodyState2D) -> void:
 if not enabled or state == "dead": return
 physics.angular_velocity = clampf(physics.angular_velocity,-2.2,2.2)
 var windup := .42 if attack_kind == "claw" else .67
 if balance.state != "steady" or attack_landed or attack_time < windup or attack_time > windup+.38: return
 for i in range(physics.get_contact_count()):
  var other := physics.get_contact_collider_object(i)
  if not other is RigidBody2D or not other.has_meta("damage_part"): continue
  if str(other.get_meta("damage_part")) not in ["Head","Core"]: continue
  var owner_id := shape_find_owner(physics.get_contact_local_shape(i))
  var shape_node := shape_owner_get_owner(owner_id)
  if int(shape_node.get_meta("part",-1)) not in [1,3]: continue
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
  state = "dead";enabled = false;collision_layer = 0;collision_mask = 1;lock_rotation = false;apply_torque_impulse(-65000);defeated.emit()
func set_enabled(value: bool) -> void:
 enabled = value;freeze = not value
