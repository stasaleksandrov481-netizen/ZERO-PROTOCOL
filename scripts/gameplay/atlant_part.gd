class_name AtlantPart
extends RigidBody3D
## A real planar rigid body. Contact telemetry comes from the solver, not the render pose.

var support_contacts := 0
var contact_impulse := 0.0
var reset_pose: Transform3D
var reset_requested := false
var opponent_impulse := 0.0
var opponent_contact := Vector3.ZERO
var max_spin := 14.0

func _integrate_forces(state: PhysicsDirectBodyState3D) -> void:
	if reset_requested:
		state.transform = reset_pose
		state.linear_velocity = Vector3.ZERO
		state.angular_velocity = Vector3.ZERO
		reset_requested = false
		opponent_impulse = 0.0
		return
	support_contacts = 0
	contact_impulse = 0.0
	opponent_impulse = 0.0
	for i in range(state.get_contact_count()):
		var collider := state.get_contact_collider_object(i)
		if collider is StaticBody3D and (collider.collision_layer & 1) != 0: support_contacts += 1
		var impulse := state.get_contact_impulse(i).length()
		contact_impulse = maxf(contact_impulse,impulse)
		if collider is PhysicsBody3D and (collider.collision_layer & 4) != 0 and impulse > opponent_impulse:
			opponent_impulse = impulse
			opponent_contact = state.get_contact_local_position(i)
	# Bound only unstable numerical velocities; normal movement remains force driven.
	if state.angular_velocity.length() > max_spin:
		state.angular_velocity = state.angular_velocity.limit_length(max_spin)
	if state.linear_velocity.length() > 35.0:
		state.linear_velocity = state.linear_velocity.limit_length(35.0)
