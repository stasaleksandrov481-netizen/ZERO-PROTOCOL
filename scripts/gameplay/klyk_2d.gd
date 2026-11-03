extends RigidBody2D
## Support damage cannot deliver the player's final blow.
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
func _ready() -> void:
 mass = 75;collision_layer = 4;collision_mask = 3;lock_rotation = true;contact_monitor = true;max_contacts_reported = 8;continuous_cd = RigidBody2D.CCD_MODE_CAST_SHAPE
 atlas = load("res://assets/creatures/klyk_atlas.png")
 var shape := CollisionShape2D.new();var box := RectangleShape2D.new();box.size = Vector2(155,510);shape.shape = box;add_child(shape)
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
func _part(index: int,p: Vector2,scale_value: Vector2,layer: int,parent: Node = self) -> Sprite2D:
 var sprite := Sprite2D.new();var region := AtlasTexture.new();region.atlas = atlas
 var cell := Vector2(atlas.get_width()/4.0,atlas.get_height()/2.0);region.region = Rect2(Vector2(index%4,index/4)*cell,cell)
 sprite.texture = region;sprite.position = p;sprite.scale = scale_value;sprite.z_index = layer;parent.add_child(sprite);return sprite
func _physics_process(delta: float) -> void:
 if not enabled or state == "dead" or not is_instance_valid(target): return
 clock += delta;attack_clock = maxf(0,attack_clock-delta)
 var dx: float = target.core.position.x-position.x
 linear_velocity.x = move_toward(linear_velocity.x,signf(dx)*48 if absf(dx) > 200 else 0,delta*150)
 for i in range(limbs.size()): limbs[i].rotation = sin(clock*2.8+i*PI)*(.12 if i%2 == 0 else .18)
 if absf(dx) < 260 and attack_clock == 0:
  attack_clock = 2.7;state = "attack";landed.emit(.12)
  target.core.apply_central_impulse(Vector2(signf(dx)*100,-10)*64)
func register_hit(strength: float,support: bool = false) -> void:
 if state == "dead" or not enabled: return
 health = maxf(8 if support else 0,health-clampf(strength,0,1)*40-8)
 linear_velocity.x += 30;modulate = Color(1.25,.9,.8)
 create_tween().tween_property(self,"modulate",Color.WHITE,.24)
 if health <= 0:
  state = "dead";enabled = false;collision_layer = 0;collision_mask = 1;lock_rotation = false;apply_torque_impulse(-65000);defeated.emit()
func set_enabled(value: bool) -> void:
 enabled = value;freeze = not value
