class_name InputSchemeSettings
extends Resource
## Persistent configuration used by the test range and future battle adapters.

enum Scheme { DOUBLE_TAP, TILT }
@export var scheme: Scheme = Scheme.DOUBLE_TAP
@export_range(0.25, 3.0) var tilt_sensitivity := 1.0
@export_range(0.02, 0.4) var tilt_deadzone := 0.12
@export var neutral_acceleration := Vector3.ZERO
@export var calibrated := false

func sensor_available() -> bool:
	return OS.has_feature("android") and Input.get_accelerometer().length_squared() > 0.25

func sample_walk_axis() -> float:
	if scheme != Scheme.TILT or not sensor_available(): return 0.0
	# Device-coordinate x is the landscape horizontal axis. Validate sign on the target phone.
	var raw := (Input.get_accelerometer().x - neutral_acceleration.x) / 9.80665
	if absf(raw) < tilt_deadzone: return 0.0
	return clampf(signf(raw) * (absf(raw) - tilt_deadzone) / (1.0 - tilt_deadzone) * tilt_sensitivity, -1.0, 1.0)
