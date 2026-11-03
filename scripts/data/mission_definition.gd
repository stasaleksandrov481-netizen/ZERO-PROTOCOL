class_name MissionDefinition
extends Resource

@export var id: StringName
@export var display_name: String
@export_multiline var description: String
@export var scene: PackedScene
@export var available := false

func can_launch() -> bool:
	return available and scene != null
