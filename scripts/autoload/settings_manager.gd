extends Node
## Validated schema, immediate application and debounced writes shared by all screens.

signal changed(key: StringName, value: Variant)
signal saved(success: bool)
signal save_failed(message: String)

const SCHEMA_VERSION := 2
const DEFAULTS := {
	"audio/master": 0.8, "audio/music": 0.45, "audio/sfx": 0.65, "audio/ui": 0.65,
	"video/quality": 1, "video/fps": 60, "video/reduced_motion": false,
	"ui/scale": 1.0, "ui/high_contrast": false,
	"input/scheme": 0, "input/tilt_sensitivity": 1.0, "input/tilt_deadzone": 0.12,
	"input/tilt_neutral": Vector3.ZERO, "input/calibrated": false,
}
const BUSES := {"audio/master": "Master", "audio/music": "Music", "audio/sfx": "SFX", "audio/ui": "UI"}
var values: Dictionary = DEFAULTS.duplicate(true)
var write_timer: Timer
var dirty := false
var save_error := ""
var startup_notice := ""

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	AudioServer.set_bus_layout(preload("res://resources/configuration/default_bus_layout.tres"))
	TranslationServer.add_translation(preload("res://resources/localization/ui_ru.tres"))
	TranslationServer.set_locale("ru")
	write_timer = Timer.new()
	write_timer.one_shot = true
	write_timer.wait_time = 0.35
	add_child(write_timer)
	write_timer.timeout.connect(flush)
	reload_from_disk()
	apply_all()
	if startup_notice != "":
		# Repaired values replace the damaged file only after a validated read.
		flush()

func get_value(key: StringName) -> Variant:
	return values.get(String(key), DEFAULTS.get(String(key)))

func set_value(key: StringName, value: Variant) -> void:
	var k := String(key)
	if not DEFAULTS.has(k):
		push_warning("Unknown settings key: " + k)
		return
	var validated: Variant = _validate(k, value)
	if values[k] == validated:
		return
	values[k] = validated
	_apply_one(k)
	dirty = true
	write_timer.start()
	changed.emit(key, validated)

func _validate(key: String, value: Variant) -> Variant:
	var fallback: Variant = DEFAULTS[key]
	if typeof(fallback) == TYPE_BOOL:
		return value if typeof(value) == TYPE_BOOL else fallback
	if typeof(fallback) == TYPE_VECTOR3:
		if value is Vector3 and value.is_finite() and value.length() < 40.0:
			return value
		return fallback
	if typeof(fallback) == TYPE_FLOAT:
		if not (value is float or value is int) or not is_finite(float(value)):
			return fallback
		var n := float(value)
		if key.begins_with("audio/"): return clampf(n, 0.0, 1.0)
		if key == "input/tilt_sensitivity": return clampf(n, 0.25, 3.0)
		if key == "input/tilt_deadzone": return clampf(n, 0.02, 0.4)
		if key == "ui/scale": return n if n in [0.9, 1.0, 1.1, 1.25] else fallback
	if typeof(fallback) == TYPE_INT:
		if not (value is float or value is int): return fallback
		var n := int(value)
		if key == "video/quality": return clampi(n, 0, 2)
		if key == "video/fps": return n if n in [0, 30, 60] else fallback
		if key == "input/scheme": return n if n in [0, 1] else fallback
	return fallback

func reload_from_disk() -> void:
	var cfg := SaveService.load_settings()
	startup_notice = SaveService.recovery_message
	values = DEFAULTS.duplicate(true)
	var version: Variant = cfg.get_value("meta", "version", 1)
	if not (version is int) or version > SCHEMA_VERSION:
		startup_notice = "Неизвестная версия настроек. Применены безопасные значения."
		return
	# Version 1 stored the scale as a percentage. All other keys are stable.
	for key: String in DEFAULTS:
		var parts := key.split("/")
		var value: Variant = cfg.get_value(parts[0], parts[1], DEFAULTS[key])
		if version == 1 and key == "ui/scale" and value is int:
			value = float(value) / 100.0
		values[key] = _validate(key, value)

func apply_all() -> void:
	for key: String in values: _apply_one(key)

func _apply_one(key: String) -> void:
	if BUSES.has(key):
		var index := AudioServer.get_bus_index(BUSES[key])
		if index >= 0:
			var volume := float(values[key])
			AudioServer.set_bus_mute(index, volume <= 0.0001)
			AudioServer.set_bus_volume_db(index, linear_to_db(maxf(volume, 0.0001)))
	if key == "video/fps":
		Engine.max_fps = int(values[key])
		# A user cap remains a cap; unlimited is still bounded by hardware/compositor.
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)

func flush() -> bool:
	if is_instance_valid(write_timer): write_timer.stop()
	var cfg := ConfigFile.new()
	cfg.set_value("meta", "version", SCHEMA_VERSION)
	for key: String in values:
		var parts := key.split("/")
		cfg.set_value(parts[0], parts[1], values[key])
	var result := SaveService.store_settings(cfg)
	dirty = result != OK
	save_error = "" if result == OK else "Не удалось сохранить настройки: %s" % error_string(result)
	saved.emit(result == OK)
	if result != OK: save_failed.emit(save_error)
	return result == OK

func reset_defaults() -> void:
	for key: String in DEFAULTS: set_value(key, DEFAULTS[key])
	flush()

func input_config() -> InputSchemeSettings:
	var config := InputSchemeSettings.new()
	config.scheme = int(values["input/scheme"])
	config.tilt_sensitivity = float(values["input/tilt_sensitivity"])
	config.tilt_deadzone = float(values["input/tilt_deadzone"])
	config.neutral_acceleration = values["input/tilt_neutral"]
	config.calibrated = bool(values["input/calibrated"])
	return config

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_PAUSED or what == NOTIFICATION_WM_CLOSE_REQUEST:
		if dirty: flush()
