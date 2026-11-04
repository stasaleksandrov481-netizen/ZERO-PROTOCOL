extends "res://scripts/gameplay/atlant_2d_controller.gd"
## Catalog scene uses the same current factory as the game; no baked legacy model.
const Factory = preload("res://scripts/models/at01_2d_builder.gd")
func _init() -> void:
 var builder := Factory.new();var rig := builder.create()
 if rig == null: startup_error = builder.startup_error;return
 for child: Node in rig.get_children():
  _clear_owner(child);rig.remove_child(child);add_child(child)
 set_meta("skin","oplot-seven-part");set_meta("view_profile","strict_right_side_2d");rig.free()

func _clear_owner(node: Node) -> void:
 node.owner = null
 for child: Node in node.get_children(): _clear_owner(child)
