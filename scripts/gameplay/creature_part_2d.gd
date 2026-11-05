extends "res://scripts/gameplay/atlant_2d_part.gd"
## A true rigid limb: native contacts, mass, pin-joint anchors and mechanical stops.
var creature: RigidBody2D
var part_index := 0
func _integrate_forces(physics: PhysicsDirectBodyState2D) -> void:
 super._integrate_forces(physics)
 if is_instance_valid(creature) and creature.enabled and creature.state != "dead":
  creature.try_attack_contact(physics,part_index)
