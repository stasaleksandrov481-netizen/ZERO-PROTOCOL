extends Control
## Safe-area conversion, adaptive UI zoom, route host and platform Back handling.

@onready var safe_root: Control = $SafeRoot
@onready var route_host: Control = $SafeRoot/RouteHost
@onready var modal_host: Control = $SafeRoot/ModalHost
@onready var toast_host: Control = $SafeRoot/ToastHost
var effective_scale := 1.0

func _ready() -> void:
 theme = RiftUI.design_theme()
 get_tree().auto_accept_quit = false
 get_tree().quit_on_go_back = false
 resized.connect(_layout)
 SettingsManager.changed.connect(_setting_changed)
 SettingsManager.save_failed.connect(_save_error)
 NavigationManager.bind(route_host, modal_host, toast_host)
 NavigationManager.route_changed.connect(_route_changed)
 NavigationManager.route_loading.connect(_route_loading)
 _layout()
 _apply_contrast()
 NavigationManager.go(&"home")
 AudioManager.start_menu()
 if not Expedition.notice.is_empty(): NavigationManager.toast(Expedition.notice)
 if SettingsManager.startup_notice != "":
  NavigationManager.toast(SettingsManager.startup_notice)

func _layout() -> void:
 var rect := Rect2(Vector2.ZERO, size)
 if OS.has_feature("android"):
  var physical := DisplayServer.get_display_safe_area()
  var screen := Vector2(DisplayServer.screen_get_size())
  if screen.x > 0.0 and screen.y > 0.0 and physical.has_area():
   rect.position = Vector2(physical.position) / screen * size
   rect.size = Vector2(physical.size) / screen * size
 # Keep 920x540 logical pixels as a usable minimum; requested zoom is retained on disk.
 effective_scale = minf(float(SettingsManager.get_value("ui/scale")), minf(rect.size.x / 920.0, rect.size.y / 540.0))
 effective_scale = maxf(effective_scale, 0.5)
 safe_root.position = rect.position
 safe_root.scale = Vector2.ONE * effective_scale
 safe_root.size = rect.size / effective_scale

func _setting_changed(key: StringName, _value: Variant) -> void:
 if key == &"ui/scale": _layout()
 if key == &"ui/high_contrast": _apply_contrast()

func _apply_contrast() -> void:
 var enabled := bool(SettingsManager.get_value("ui/high_contrast"))
 $ContrastShade.color = Color(0.0,0.01,0.025,0.38 if enabled else 0.0)
 for type in ["Button", "CheckBox", "OptionButton", "Label"]:
  theme.set_color("font_color", type, Color.WHITE if enabled else RiftUI.TEXT)
 for type in ["Button", "OptionButton"]:
  theme.set_color("font_focus_color", type, Color.WHITE)

func _route_loading(route: StringName) -> void:
 if route != &"home":
  $MenuBackground.hide();$MenuShade.hide();$MenuBackground.set_home_active(false)

func _route_changed(route: StringName) -> void:
 $SectionShade.visible = false
 $MenuBackground.visible = route == &"home"
 $MenuShade.visible = route == &"home"
 $MenuBackground.set_home_active(route == &"home")

func _save_error(message: String) -> void:
 NavigationManager.toast(message)

func _unhandled_input(event: InputEvent) -> void:
 if event.is_action_pressed("ui_cancel"):
  get_viewport().set_input_as_handled()
  if is_instance_valid(NavigationManager.current_screen) and NavigationManager.current_screen.has_method("handle_back"):
   NavigationManager.current_screen.handle_back()
  else: NavigationManager.back()

func _notification(what: int) -> void:
 if what == NOTIFICATION_WM_CLOSE_REQUEST: NavigationManager.confirm_exit()
 elif what == NOTIFICATION_WM_GO_BACK_REQUEST:
  if is_instance_valid(NavigationManager.current_screen) and NavigationManager.current_screen.has_method("handle_back"): NavigationManager.current_screen.handle_back()
  else: NavigationManager.back()
