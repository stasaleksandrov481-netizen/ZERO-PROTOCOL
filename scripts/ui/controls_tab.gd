extends SettingsTab

var sensor_label: Label
var calibrate_button: Button
var calibration_busy := false

func _ready() -> void:
	super._ready()
	intro(tr("CONTROLS_TITLE"),tr("CONTROLS_HINT"))
	add_choice("input/scheme",tr("WALK_SCHEME"),[tr("SCHEME_A_SHORT"),tr("SCHEME_B_SHORT")],[0,1],tr("WALK_HINT"))
	var diagram := preload("res://scripts/ui/control_diagram.gd").new()
	add_child(RiftUI.panel(diagram,10))
	var run_help := "БЕГ: включите кнопку над групповым каналом. После падения — кнопка «Встать»." if OS.has_feature("android") else "БЕГ: кнопка над групповым каналом или Shift. После падения — «Встать» или R."
	add_child(RiftUI.paragraph(run_help+" Для прямого удара отведите стик и вынесите вперёд; движение вверх выводит кулак к голове, вниз — к корпусу и ногам.",15,RiftUI.CYAN))
	add_slider("input/tilt_sensitivity",tr("SENSITIVITY"),tr("SENSITIVITY_HINT"),0.25,3.0,0.05,func(v: float) -> String: return "%.2f×" % v)
	add_slider("input/tilt_deadzone",tr("DEADZONE"),tr("DEADZONE_HINT"),0.02,0.4,0.01,percent)
	var sensor_row := RiftUI.row(20)
	var sensor_text := RiftUI.column(5)
	sensor_text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sensor_text.add_child(RiftUI.label(tr("CALIBRATION"),18))
	sensor_label = RiftUI.paragraph("",14)
	sensor_text.add_child(sensor_label)
	sensor_row.add_child(sensor_text)
	calibrate_button = RiftUI.button(tr("CALIBRATE"),_calibrate)
	sensor_row.add_child(calibrate_button)
	add_child(RiftUI.panel(sensor_row,16))
	_refresh_sensor()
	var timer := Timer.new()
	timer.wait_time = 1.0
	timer.autostart = true
	add_child(timer)
	timer.timeout.connect(_refresh_sensor)

func _refresh_sensor() -> void:
	if calibration_busy: return
	var config := SettingsManager.input_config()
	if not config.sensor_available():
		sensor_label.text = tr("NO_SENSOR")
		sensor_label.add_theme_color_override("font_color",RiftUI.MUTED)
	else:
		sensor_label.text = tr("SENSOR_CALIBRATED") if config.calibrated else tr("SENSOR_READY")
		sensor_label.add_theme_color_override("font_color",RiftUI.CYAN)

func _calibrate() -> void:
	if calibration_busy: return
	if not SettingsManager.input_config().sensor_available():
		NavigationManager.show_info(tr("CALIBRATION"),tr("NO_SENSOR_DETAIL"))
		return
	calibration_busy = true
	calibrate_button.disabled = true
	sensor_label.text = tr("HOLD_STILL")
	var samples: Array[Vector3] = []
	var mean := Vector3.ZERO
	for i in range(24):
		await get_tree().create_timer(0.025).timeout
		var sample := Input.get_accelerometer()
		samples.append(sample)
		mean += sample
	mean /= float(samples.size())
	var variance := 0.0
	for sample in samples: variance += (sample-mean).length_squared()
	variance /= float(samples.size())
	if mean.length_squared() < 0.25 or variance > 0.8:
		NavigationManager.toast(tr("CALIBRATION_FAILED"))
	else:
		SettingsManager.set_value("input/tilt_neutral",mean)
		SettingsManager.set_value("input/calibrated",true)
		SettingsManager.flush()
		NavigationManager.toast(tr("CALIBRATION_DONE"))
	calibration_busy = false
	calibrate_button.disabled = false
	_refresh_sensor()
