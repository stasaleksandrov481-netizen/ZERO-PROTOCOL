extends Node
## Run once with -- --write, then in another process with -- --read using the same user dir.

func _ready() -> void:
	if "--write" in OS.get_cmdline_user_args():
		SettingsManager.set_value("audio/master",.37)
		SettingsManager.set_value("input/scheme",1)
		SettingsManager.set_value("input/tilt_deadzone",.23)
		SettingsManager.set_value("ui/scale",1.1)
		SettingsManager.set_value("video/quality",2)
		var ok := SettingsManager.flush()
		print("PERSISTENCE_WRITE ",ok)
		get_tree().quit(0 if ok else 1)
	else:
		var ok := is_equal_approx(float(SettingsManager.get_value("audio/master")),.37)
		ok = ok and SettingsManager.get_value("input/scheme") == 1
		ok = ok and is_equal_approx(float(SettingsManager.get_value("input/tilt_deadzone")),.23)
		ok = ok and is_equal_approx(float(SettingsManager.get_value("ui/scale")),1.1)
		ok = ok and SettingsManager.get_value("video/quality") == 2
		print("PERSISTENCE_READ ",ok)
		SettingsManager.reset_defaults()
		get_tree().quit(0 if ok else 1)
