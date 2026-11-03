# Actors: strict side-view 2D

Current user decision: all Atlants, distorted creatures and training targets use a strictly lateral 2D projection. No 3D character models, perspective view, isometric view, frontal pose or three-quarter pose. Turning is disabled until the user approves its design. Walking backward does not flip the actor.

The active training range uses Node2D, Camera2D, RigidBody2D and PinJoint2D. Its SubViewport explicitly disables 3D. There are no lights or cast shadows. Armor highlights are painted into the fixed sprite artwork.

AT-01 has eleven separate rigid bodies and painted cutouts. Stable part names identify torso/head, each upper arm, forearm/fist, thigh, shin and foot. The `damage_part` metadata and the matching `Visual/PaintedArmor` child keep future localized damage, armor masks and detachable parts in 2D. Do not replace the actor with a single merged image or a 3D mesh.

Use `at01_2d_builder.gd` and `atlant_2d_controller.gd`. `at01_builder.gd` is only a compatibility wrapper for this 2D builder. The old 3D controller and mesh-authoring files are legacy source and are not used by the game. New actors must follow the 2D path.

Each arm joystick controls wrist position. Distance from the center controls reach, so an engaged stick at/near its center folds the elbow, while an engaged stick at its edge extends the arm. Releasing the stick returns to a relaxed pose. Independent touch ownership must be preserved.
