extends Node
## One active screen, one modal at a time. Persistent background lives outside the route host.

signal route_changed(route: StringName)
signal route_loading(route: StringName)
const Textures = preload("res://scripts/systems/texture_source.gd")
signal quit_requested

const ROUTES := {
	"home": "res://scenes/menu/home_screen.tscn",
	"enlistment": "res://scenes/screens/enlistment_screen.tscn",
	"campaign": "res://scenes/screens/campaign_screen.tscn",
	"operations": "res://scenes/screens/operations_screen.tscn",
	"hangar": "res://scenes/screens/hangar_screen.tscn",
	"archive": "res://scenes/screens/archive_screen.tscn",
	"settings": "res://scenes/settings/settings_screen.tscn",
	"test": "res://scenes/gameplay/test_screen.tscn",
	"expedition": "res://scenes/gameplay/expedition_screen.tscn",
}
var current_route: StringName = &""
var current_screen: Control
var host: Control
var modal_host: Control
var active_modal: Control
var toast_host: Control
var last_home_focus := "Campaign"
var transitioning := false

# Installed only while opening the range. Keep the original engine error,
# including script path and line, instead of guessing an engine-version issue.
class RangeErrors extends Logger:
	var mutex := Mutex.new()
	var records: Array[Dictionary] = []
	func _log_error(function: String, file: String, line: int, code: String, rationale: String,
			_editor_notify: bool, error_type: int, _backtraces: Array[ScriptBacktrace]) -> void:
		if error_type == Logger.ERROR_TYPE_WARNING: return
		mutex.lock()
		if records.size() < 16:
			records.append({"function":function,"file":file,"line":line,
				"message":rationale if rationale != "" else code,"type":error_type})
		mutex.unlock()
	func snapshot() -> Array[Dictionary]:
		mutex.lock()
		var result: Array[Dictionary] = records.duplicate(true)
		mutex.unlock()
		return result

func bind(screen_host: Control, dialogs: Control, notifications: Control) -> void:
	host = screen_host
	modal_host = dialogs
	toast_host = notifications

func go(route: StringName) -> void:
	if transitioning or route == current_route: return
	if not ROUTES.has(String(route)) or not is_instance_valid(host): return
	if is_instance_valid(active_modal): return
	transitioning = true
	route_loading.emit(route)
	if route in [&"test",&"expedition",&"hangar"]:
		var required: Array[String] = ["res://assets/atlants/at01_oplot_atlas.png"]
		if route == &"expedition":
			required.append_array(["res://assets/creatures/klyk_atlas.png","res://assets/environments/night_"+str(Expedition.active_route().get("biome","sea"))+".png","res://assets/environments/heavy_transport.png"])
		var problem := Textures.require_png(required)
		if not problem.is_empty():
			await _range_failed({"stage":"Проверка изображений","reason":problem},[])
			return
	if is_instance_valid(current_screen):
		current_screen.mouse_filter = Control.MOUSE_FILTER_IGNORE
		current_screen.process_mode = Node.PROCESS_MODE_DISABLED
		if not bool(SettingsManager.get_value("video/reduced_motion")):
			await create_tween().tween_property(current_screen, "modulate:a", 0.0, 0.09).finished
		current_screen.get_parent().remove_child(current_screen)
		current_screen.queue_free()
	var range_errors: RangeErrors
	if route in [&"test",&"expedition"]:
		range_errors = RangeErrors.new()
		OS.add_logger(range_errors)
	var scene := load(ROUTES[String(route)]) as PackedScene
	if scene == null:
		if range_errors != null:
			OS.remove_logger(range_errors)
			await _range_failed({"stage":"Загрузка сцены полигона","reason":"Не удалось прочитать " + ROUTES[String(route)]},range_errors.snapshot())
			return
		transitioning = false
		show_info("Ошибка загрузки", "Не удалось открыть раздел. Вернитесь в главное меню.")
		return
	current_screen = scene.instantiate()
	# Never expose a half-built world, including top-level SubViewportContainers.
	current_screen.hide();current_screen.modulate.a = 0
	var world_view := current_screen.get_node_or_null("WorldView") as Control
	if world_view != null: world_view.hide()
	current_route = route
	host.add_child(current_screen)
	current_screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	if route in [&"test",&"expedition"]:
		# Layout and child readiness can finish on the next frame after insertion.
		await get_tree().process_frame
		await get_tree().process_frame
		OS.remove_logger(range_errors)
		if not current_screen.has_method("is_range_ready") or not current_screen.call("is_range_ready") or not range_errors.snapshot().is_empty():
			var details := {"stage":"Загрузка скрипта полигона","reason":"Не загрузился scripts/gameplay/test_screen.gd"}
			if current_screen.has_method("range_startup_details"):
				details = current_screen.call("range_startup_details")
			await _range_failed(details,range_errors.snapshot())
			return
	current_screen.set_meta("startup_validated",true)
	current_screen.show()
	if world_view != null: world_view.show()
	if not bool(SettingsManager.get_value("video/reduced_motion")):
		current_screen.modulate.a = 0.0
		await create_tween().tween_property(current_screen, "modulate:a", 1.0, 0.14).finished
	current_screen.modulate.a = 1
	transitioning = false
	route_changed.emit(route)
	if current_screen.has_method("focus_initial"): call_deferred("_focus_screen",current_screen)

func _focus_screen(screen: Variant) -> void:
	if not is_instance_valid(screen) or not screen.is_inside_tree(): return
	if screen == current_screen and not transitioning and not is_instance_valid(active_modal):
		screen.call("focus_initial")

func _range_failed(details: Dictionary, errors: Array[Dictionary]) -> void:
	var report := {"patch":"RIFT-0.14.0","engine":Engine.get_version_info()["string"],
		"platform":OS.get_name(),"startup":details,"errors":errors}
	var log_file := FileAccess.open("user://at01_startup_report.json",FileAccess.WRITE)
	if log_file != null:
		log_file.store_string(JSON.stringify(report,"  "))
		log_file.close()
	var message := "Этап: %s" % details.get("stage","Запуск АТ-01")
	var reason := str(details.get("reason",""))
	if reason != "": message += "\n"+reason
	# Prefer the first script error to secondary missing-resource messages.
	var selected: Dictionary = {}
	for entry: Dictionary in errors:
		if selected.is_empty() or int(entry["type"]) == Logger.ERROR_TYPE_SCRIPT:
			selected = entry
		if int(entry["type"]) == Logger.ERROR_TYPE_SCRIPT: break
	if not selected.is_empty():
		message += "\n\n%s:%d\n%s" % [str(selected["file"]).trim_prefix("res://"),
			int(selected["line"]),str(selected["message"]).left(360)]
	message += "\n\nПатч RIFT-0.14.0 · Godot %s" % Engine.get_version_info()["string"]
	transitioning = false
	current_route = &""
	await go(&"home")
	show_info("Не удалось открыть игровую сцену",message)

func back() -> void:
	if is_instance_valid(active_modal):
		active_modal.dismiss(false)
		return
	if transitioning: return
	AudioManager.play_ui("back")
	if current_route != &"home":
		SettingsManager.flush()
		go(&"home")
	else:
		confirm_exit()

func show_confirm(title: String, message: String, accept_text: String, action: Callable) -> void:
	if is_instance_valid(active_modal) or not is_instance_valid(modal_host): return
	var dialog: Control = load("res://scenes/ui/confirm_dialog.tscn").instantiate()
	active_modal = dialog
	dialog.configure(title, message, accept_text, action, false)
	modal_host.add_child(dialog)
	dialog.closed.connect(_modal_closed, CONNECT_ONE_SHOT)

func show_info(title: String, message: String) -> void:
	if is_instance_valid(active_modal) or not is_instance_valid(modal_host): return
	var dialog: Control = load("res://scenes/ui/confirm_dialog.tscn").instantiate()
	active_modal = dialog
	dialog.configure(title, message, "Понятно", Callable(), true)
	modal_host.add_child(dialog)
	dialog.closed.connect(_modal_closed, CONNECT_ONE_SHOT)

func _modal_closed() -> void:
	active_modal = null
	if is_instance_valid(current_screen) and current_screen.has_method("focus_initial"): call_deferred("_focus_screen",current_screen)

func confirm_exit() -> void:
	show_confirm(tr("QUIT_TITLE"), tr("QUIT_BODY"), tr("QUIT"), _quit)

func _quit() -> void:
	if Expedition.started and not Expedition.save_progress(): return
	if not SettingsManager.flush():
		call_deferred("show_info", "Сохранение", SettingsManager.save_error)
		return
	AudioManager.shutdown()
	# Give the audio server time to release active playback before engine teardown.
	await get_tree().create_timer(0.08).timeout
	quit_requested.emit()
	get_tree().quit()

func toast(message: String) -> void:
	if not is_instance_valid(toast_host): return
	# Replace the previous toast; repeated settings actions never queue an unbounded stack.
	for child in toast_host.get_children():
		toast_host.remove_child(child)
		child.queue_free()
	var notification: Control = load("res://scenes/ui/notification.tscn").instantiate()
	notification.message = message
	toast_host.add_child(notification)
