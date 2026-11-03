extends Node
## Intentionally writes malformed configs into a disposable user directory. Parser errors are expected here.

var failures := PackedStringArray()

func _ready() -> void:
	SettingsManager.reset_defaults()
	SettingsManager.set_value("audio/master",.42)
	SettingsManager.flush()
	# Write again so the backup and the primary both contain the known marker.
	SettingsManager.flush()
	_corrupt()
	SettingsManager.reload_from_disk()
	_check(is_equal_approx(float(SettingsManager.get_value("audio/master")),.42),"Corrupt primary recovers backup")
	_check(SettingsManager.startup_notice != "","Recovery is explained")
	DirAccess.remove_absolute(SaveService.BACKUP_PATH)
	_corrupt()
	SettingsManager.reload_from_disk()
	_check(SettingsManager.get_value("audio/master") == .8,"Corrupt primary without backup uses defaults")
	SettingsManager.reset_defaults()
	var version_one := ConfigFile.new()
	version_one.set_value("meta","version",1)
	version_one.set_value("ui","scale",110)
	version_one.save(SaveService.SETTINGS_PATH)
	SettingsManager.reload_from_disk()
	_check(is_equal_approx(float(SettingsManager.get_value("ui/scale")),1.1),"Version 1 scale migrates to version 2")
	var future := ConfigFile.new()
	future.set_value("meta","version",999)
	future.set_value("audio","master",.13)
	future.save(SaveService.SETTINGS_PATH)
	SettingsManager.reload_from_disk()
	_check(SettingsManager.get_value("audio/master") == .8,"Unknown future schema uses defaults")
	SettingsManager.reset_defaults()
	SettingsManager.apply_all()
	print("RECOVERY_RESULT ",JSON.stringify({"failures":failures,"passed":5-failures.size()}))
	get_tree().quit(0 if failures.is_empty() else 1)

func _corrupt() -> void:
	var f := FileAccess.open(SaveService.SETTINGS_PATH,FileAccess.WRITE)
	f.store_string("[meta\nversion = ) garbage")
	f.close()

func _check(value: bool, message: String) -> void:
	print("PASS " if value else "FAIL ",message)
	if not value: failures.append(message)
