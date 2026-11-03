extends Node
## Transactional local ConfigFile storage. No network or gameplay save is implied.

const SETTINGS_PATH := "user://settings.cfg"
const BACKUP_PATH := "user://settings.backup.cfg"
const PENDING_PATH := "user://settings.pending.cfg"
var recovery_message := ""
var last_error := OK

func load_settings() -> ConfigFile:
	var config := ConfigFile.new()
	recovery_message = ""
	if not FileAccess.file_exists(SETTINGS_PATH):
		if config.load(BACKUP_PATH) == OK:
			recovery_message = "Восстановлена резервная копия настроек."
		return config
	var result := config.load(SETTINGS_PATH)
	if result == OK:
		return config
	var stamp := str(int(Time.get_unix_time_from_system()))
	var quarantine := "user://settings.corrupt-%s.cfg" % stamp
	if DirAccess.rename_absolute(SETTINGS_PATH,quarantine) != OK:
		DirAccess.copy_absolute(SETTINGS_PATH,quarantine)
	config = ConfigFile.new()
	if config.load(BACKUP_PATH) == OK:
		recovery_message = "Файл настроек повреждён. Восстановлена резервная копия."
	else:
		config = ConfigFile.new()
		recovery_message = "Файл настроек повреждён. Применены безопасные значения."
	return config

func store_settings(config: ConfigFile) -> Error:
	last_error = config.save(PENDING_PATH)
	if last_error != OK:
		return last_error
	var check := ConfigFile.new()
	last_error = check.load(PENDING_PATH)
	if last_error != OK:
		return last_error
	# Rotate only a parseable previous copy; never overwrite a good backup with corruption.
	var previous := ConfigFile.new()
	if previous.load(SETTINGS_PATH) == OK:
		last_error = DirAccess.copy_absolute(SETTINGS_PATH, BACKUP_PATH)
		if last_error != OK:
			return last_error
	last_error = DirAccess.rename_absolute(PENDING_PATH, SETTINGS_PATH)
	return last_error
