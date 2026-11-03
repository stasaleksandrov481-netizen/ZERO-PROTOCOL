class_name ModuleDefinition
extends Resource
## Includes future back-mounted missile modules. Mounts follow the character rig.

@export var id: StringName
@export var display_name: String
@export var module_class: StringName
@export var compatible_slots: Array[StringName] = []
@export var mount_socket: StringName
@export var visual_scene: PackedScene
@export var config: Resource
