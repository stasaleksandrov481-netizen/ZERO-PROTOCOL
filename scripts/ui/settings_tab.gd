class_name SettingsTab
extends VBoxContainer
## Settings controls bind through one validator and refresh after reset or external changes.

var bindings: Dictionary = {}

func _ready() -> void:
	add_theme_constant_override("separation", 12)
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	SettingsManager.changed.connect(_sync_key)

func intro(title: String, message: String) -> void:
	add_child(RiftUI.section_title(title))
	add_child(RiftUI.paragraph(message, 16))
	add_child(RiftUI.spacer(2))

func add_slider(key: String, title: String, hint: String, minimum: float, maximum: float, step: float, formatter: Callable) -> HSlider:
	var line := RiftUI.row(16)
	var titles := RiftUI.column(5)
	titles.custom_minimum_size.x = 200
	titles.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	titles.add_child(RiftUI.label(title, 18))
	if hint != "": titles.add_child(RiftUI.paragraph(hint, 13))
	line.add_child(titles)
	var slider := HSlider.new()
	slider.name = key.get_slice("/", 1).to_pascal_case() + "Slider"
	slider.min_value = minimum
	slider.max_value = maximum
	slider.step = step
	slider.custom_minimum_size = Vector2(180,48)
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slider.value = float(SettingsManager.get_value(key))
	line.add_child(slider)
	var readout := RiftUI.label(formatter.call(slider.value),18,RiftUI.CYAN)
	readout.custom_minimum_size.x = 64
	readout.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	line.add_child(readout)
	bindings[key] = {"node":slider,"kind":"slider","readout":readout,"formatter":formatter}
	slider.value_changed.connect(func(value: float) -> void: SettingsManager.set_value(key,value))
	add_child(RiftUI.panel(line,16))
	return slider

func add_choice(key: String, title: String, labels: Array, options: Array, hint: String = "") -> OptionButton:
	var line := RiftUI.row(16)
	var titles := RiftUI.column(5)
	titles.custom_minimum_size.x = 200
	titles.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	titles.add_child(RiftUI.label(title,18))
	if hint != "": titles.add_child(RiftUI.paragraph(hint,13))
	line.add_child(titles)
	var choice := OptionButton.new()
	choice.name = key.get_slice("/",1).to_pascal_case() + "Choice"
	choice.custom_minimum_size = Vector2(246,48)
	choice.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	for item: String in labels: choice.add_item(item)
	choice.select(maxi(0, options.find(SettingsManager.get_value(key))))
	choice.item_selected.connect(func(index: int) -> void:
		AudioManager.play_ui()
		SettingsManager.set_value(key, options[index]))
	line.add_child(choice)
	bindings[key] = {"node":choice,"kind":"choice","options":options}
	add_child(RiftUI.panel(line,16))
	return choice

func add_toggle(key: String, title: String, hint: String) -> CheckBox:
	var box := RiftUI.column(5)
	var check := CheckBox.new()
	check.text = title
	check.custom_minimum_size.y = 48
	check.button_pressed = bool(SettingsManager.get_value(key))
	check.toggled.connect(func(enabled: bool) -> void:
		AudioManager.play_ui()
		SettingsManager.set_value(key, enabled))
	box.add_child(check)
	if hint != "": box.add_child(RiftUI.paragraph(hint,14))
	bindings[key] = {"node":check,"kind":"toggle"}
	add_child(RiftUI.panel(box,16))
	return check

func _sync_key(key: StringName, value: Variant) -> void:
	if not bindings.has(String(key)): return
	var binding: Dictionary = bindings[String(key)]
	var node: Control = binding["node"]
	if binding["kind"] == "slider":
		(node as HSlider).set_value_no_signal(float(value))
		binding["readout"].text = binding["formatter"].call(value)
	elif binding["kind"] == "choice":
		(node as OptionButton).select(maxi(0,binding["options"].find(value)))
	elif binding["kind"] == "toggle":
		(node as CheckBox).set_pressed_no_signal(bool(value))

static func percent(value: float) -> String: return "%d%%" % roundi(value*100.0)
