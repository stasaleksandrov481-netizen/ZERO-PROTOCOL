extends RigidBody2D
## Support damage cannot deliver the player's final blow.
const Textures = preload("res://scripts/systems/texture_source.gd")
const ATLAS_PATH := "res://assets/creatures/klyk_atlas.png"
@export_file("*.png") var atlas_path := ATLAS_PATH
var initialized := false
var startup_error := ""
signal defeated
signal landed(strength: float)
var target: Node2D
var enabled := true
var state := "idle"
var health := 100.0
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
 mass = 75;collision_layer = 4;collision_mask = 3;lock_rotation = true;contact_monitor = true;max_contacts_reported = 8;continuous_cd = RigidBody2D.CCD_MODE_CAST_SHAPE
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
  _part(2,Vector2(0,30),Vector2(.42,.50),0,leg).modulate = tint
  _part(4,Vector2(-5,135),Vector2(.40,.46),0,leg).modulate = tint
  _part(6,Vector2(-41,204),Vector2(.47,.40),0,leg).modulate = tint
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
func _physics_process(delta: float) -> void:
 if not enabled or state == "dead" or not is_instance_valid(target): return
 clock += delta;attack_clock = maxf(0,attack_clock-delta)
 var dx: float = target.core.position.x-position.x
 linear_velocity.x = move_toward(linear_velocity.x,signf(dx)*48 if absf(dx) > 200 else 0,delta*150)
 if absf(dx) < 460 and attack_clock == 0: attack_clock = 2.7;attack_time = 0;attack_landed = false
 if attack_time >= 0:
  attack_time += delta;state = "windup" if attack_time < .32 else "attack"
  if attack_time > 1.05: attack_time = -1;state = "idle"
 for i in range(limbs.size()):
  var swing := sin(clock*2.8+i*PI)*(.10 if i%2 == 0 else .14)
  if i%2 == 1 and attack_time >= 0: swing += sin(clampf(attack_time/1.05,0,1)*PI)*.48
  limbs[i].rotation = swing
 _sync_colliders()
func _integrate_forces(physics: PhysicsDirectBodyState2D) -> void:
 if not enabled or attack_landed or attack_time < .32 or attack_time > .82: return
 for i in range(physics.get_contact_count()):
  var other := physics.get_contact_collider_object(i)
  if not other is RigidBody2D or not other.has_meta("damage_part"): continue
  if str(other.get_meta("damage_part")) not in ["Head","Core"]: continue
  var owner_id := shape_find_owner(physics.get_contact_local_shape(i))
  var shape_node := shape_owner_get_owner(owner_id)
  if int(shape_node.get_meta("part",-1)) not in [1,3]: continue
  attack_landed = true;landed.emit(.12);break
func register_hit(strength: float,support: bool = false) -> void:
 if state == "dead" or not enabled: return
 health = maxf(8 if support else 0,health-clampf(strength,0,1)*40-8)
 linear_velocity.x += 30;modulate = Color(1.25,.9,.8)
 if is_instance_valid(hit_tween): hit_tween.kill()
 hit_tween = create_tween();hit_tween.tween_property(self,"modulate",Color.WHITE,.24)
 if health <= 0:
  state = "dead";enabled = false;collision_layer = 0;collision_mask = 1;lock_rotation = false;apply_torque_impulse(-65000);defeated.emit()
func set_enabled(value: bool) -> void:
 enabled = value;freeze = not value
