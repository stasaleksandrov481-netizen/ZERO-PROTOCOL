extends RigidBody2D
## Contacts and resets stay in the native 2D solver.
var support_contacts := 0
var contact_impulse := 0.0
var opponent_body: PhysicsBody2D
var opponent_impulse := 0.0
var opponent_contact := Vector2.ZERO
var reset_pose: Transform2D
var reset_requested := false
var max_spin := 10.0
var limit_parent: PhysicsBody2D
var limit_lower := -PI
var limit_upper := PI
var anchor_parent := Vector2.ZERO
var anchor_self := Vector2.ZERO
var stop_grace := 0

func configure_stop(parent: PhysicsBody2D,world_anchor: Vector2,lower: float,upper: float) -> void:
 limit_parent = parent;limit_lower = lower;limit_upper = upper
 anchor_parent = parent.global_transform.affine_inverse()*world_anchor
 anchor_self = global_transform.affine_inverse()*world_anchor

func _mechanical_stop(state: PhysicsDirectBodyState2D) -> void:
 if not is_instance_valid(limit_parent): return
 var parent_state := PhysicsServer2D.body_get_direct_state(limit_parent.get_rid())
 var parent_transform: Transform2D = parent_state.transform if parent_state != null else limit_parent.global_transform
 var parent_spin: float = parent_state.angular_velocity if parent_state != null else 0.0
 var relative := wrapf(state.transform.get_rotation()-parent_transform.get_rotation(),-PI,PI)
 if relative >= limit_lower and relative <= limit_upper: return
 var stopped := clampf(relative,limit_lower,limit_upper)
 var outward := state.angular_velocity-parent_spin
 if (relative < limit_lower and outward < 0) or (relative > limit_upper and outward > 0):
  var parent_inverse: float = parent_state.inverse_inertia if parent_state != null else 0.0
  var inverse_sum := state.inverse_inertia+parent_inverse
  if inverse_sum > 0:
   var impulse := -outward/inverse_sum
   state.angular_velocity += impulse*state.inverse_inertia
   if limit_parent is RigidBody2D: limit_parent.apply_torque_impulse(-impulse)
 var pivot := parent_transform*anchor_parent
 var projected := Transform2D(parent_transform.get_rotation()+stopped,Vector2.ZERO)
 projected.origin = pivot-projected.basis_xform(anchor_self)
 state.transform = projected
 var parent_velocity := Vector2.ZERO
 if parent_state != null:
  var parent_radius := pivot-(parent_transform.origin+parent_state.center_of_mass)
  parent_velocity = parent_state.linear_velocity+Vector2(-parent_radius.y,parent_radius.x)*parent_spin
 var radius := projected.basis_xform(anchor_self-state.center_of_mass_local)
 state.linear_velocity = parent_velocity-Vector2(-radius.y,radius.x)*state.angular_velocity

func _integrate_forces(state: PhysicsDirectBodyState2D) -> void:
 if reset_requested:
  state.transform = reset_pose
  state.linear_velocity = Vector2.ZERO
  state.angular_velocity = 0
  reset_requested = false
  opponent_impulse = 0
  stop_grace = 2
  return
 if stop_grace > 0: stop_grace -= 1
 else: _mechanical_stop(state)
 support_contacts = 0
 contact_impulse = 0
 opponent_impulse = 0
 for index in range(state.get_contact_count()):
  var other := state.get_contact_collider_object(index)
  var impulse := state.get_contact_impulse(index).length()
  contact_impulse = maxf(contact_impulse,impulse)
  if other is StaticBody2D and (other.collision_layer & 1) != 0: support_contacts += 1
  if other is PhysicsBody2D and (other.collision_layer & 4) != 0 and impulse > opponent_impulse:
   opponent_body = other
   opponent_impulse = impulse
   opponent_contact = state.get_contact_local_position(index)
 state.angular_velocity = clampf(state.angular_velocity,-max_spin,max_spin)
 if state.linear_velocity.length() > 1700: state.linear_velocity = state.linear_velocity.limit_length(1700)
