extends SceneTree
## Bake the same runtime rig for editing, catalog previews and future equipment.
const Builder = preload("res://scripts/models/at01_builder.gd")
const SpriteArt = preload("res://scripts/models/atlant_2d_skin.gd")
var robot: Node2D
func _initialize() -> void:
	robot = Builder.new().create()
	if SpriteArt.atlas != null:
		SpriteArt.atlas.take_over_path("res://assets/atlants/at01_horizon_cutout_atlas.png")
	var packed := PackedScene.new()
	var result := packed.pack(robot)
	if result == OK: result = ResourceSaver.save(packed,"res://scenes/atlants/at01.tscn")
	if result == OK:
		packed.take_over_path("res://scenes/atlants/at01.tscn")
		var definition := AtlantDefinition.new()
		definition.id = &"at01"
		definition.display_name = "АТ-01 «ГОРИЗОНТ»"
		definition.class_tag = &"starter"
		definition.starter_atlant = true
		definition.mass_tonnes = 92.0
		definition.visual_scene = packed
		definition.compatible_slots = [&"left_arm",&"right_arm",&"back_mount"]
		definition.base_stats = {&"walk_speed":2.8,&"physical_height":10.1,&"arm_reach":3.37}
		ResourceSaver.save(definition,"res://resources/atlants/at01.tres")
		definition.take_over_path("res://resources/atlants/at01.tres")
		var catalog := ContentCatalog.new()
		catalog.atlants.append(definition)
		ResourceSaver.save(catalog,"res://resources/future_gameplay/catalog.tres")
	print("AT-01 BUILD ",error_string(result)," / rigid bodies ",robot.get_node("Bodies").get_child_count()," / hinges ",robot.get_node("Joints").get_child_count())
	robot.free()
	quit(0 if result == OK else 1)
