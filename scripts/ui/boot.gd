extends Control
## Threaded real resource load; no invented percentages or artificial loading delay.

const TARGET := "res://scenes/menu/main_menu.tscn"
var failed := false

func _ready() -> void:
	var result := ResourceLoader.load_threaded_request(TARGET)
	if result != OK:
		_fail("Ошибка загрузки меню: " + error_string(result))

func _process(_delta: float) -> void:
	if failed: return
	var status := ResourceLoader.load_threaded_get_status(TARGET)
	if status == ResourceLoader.THREAD_LOAD_LOADED:
		set_process(false)
		var scene := ResourceLoader.load_threaded_get(TARGET) as PackedScene
		if scene == null: _fail("Не удалось прочитать сцену меню.")
		else: get_tree().call_deferred("change_scene_to_packed", scene)
	elif status == ResourceLoader.THREAD_LOAD_FAILED or status == ResourceLoader.THREAD_LOAD_INVALID_RESOURCE:
		_fail("Не удалось загрузить меню. Проверьте целостность папки проекта.")

func _fail(message: String) -> void:
	failed = true
	$Center/Column/Status.text = message
	$Center/Column/Retry.visible = true
	$Center/Column/Retry.pressed.connect(func() -> void: get_tree().reload_current_scene())
