extends MarginContainer

var message := ""

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	offset_left = 36
	offset_right = -36
	offset_top = -100
	offset_bottom = -24
	$Panel/Label.text = message
	await get_tree().create_timer(4.0).timeout
	queue_free()
