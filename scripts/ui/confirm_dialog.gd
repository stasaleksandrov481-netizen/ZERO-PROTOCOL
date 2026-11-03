extends Control

signal closed
var title_text := ""
var body_text := ""
var accept_text := ""
var action: Callable
var info_only := false
var previous_focus: Control

func configure(title: String, body: String, accept: String, callback: Callable, info: bool) -> void:
	title_text = title
	body_text = body
	accept_text = accept
	action = callback
	info_only = info

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	previous_focus = get_viewport().gui_get_focus_owner()
	var column := $Center/Panel/Margin/Column
	column.get_node("Title").text = title_text
	column.get_node("Body").text = body_text
	var accept := column.get_node("Actions/Accept") as Button
	var cancel := column.get_node("Actions/Cancel") as Button
	accept.text = accept_text
	cancel.visible = not info_only
	accept.pressed.connect(dismiss.bind(true))
	cancel.pressed.connect(dismiss.bind(false))
	if info_only: accept.grab_focus()
	else: cancel.grab_focus()
	# Trap keyboard focus inside the modal, including Tab and arrow navigation.
	for button: Button in [accept, cancel]:
		if not button.visible: continue
		var other := accept if info_only else (cancel if button == accept else accept)
		for property in ["focus_next", "focus_previous", "focus_neighbor_left", "focus_neighbor_right", "focus_neighbor_top", "focus_neighbor_bottom"]:
			button.set(property, button.get_path_to(other))

func dismiss(accepted: bool) -> void:
	AudioManager.play_ui("confirm" if accepted else "back")
	get_parent().remove_child(self)
	closed.emit()
	queue_free()
	if accepted and action.is_valid(): action.call()
