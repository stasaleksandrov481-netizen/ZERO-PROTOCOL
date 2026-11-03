class_name AtlantDefinition
extends Resource
## Content schema shared by the physical AT-01 and future campaign entries.

@export var id: StringName
@export var display_name: String
@export var class_tag: StringName
@export_range(0.1, 100000.0) var mass_tonnes := 1.0
@export var base_stats: Dictionary[StringName, float] = {}
@export var visual_scene: PackedScene
@export var compatible_slots: Array[StringName] = []
@export var starter_atlant := false
