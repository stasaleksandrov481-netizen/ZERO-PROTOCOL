extends Control
## Independent environment, Atlant, pilot and low-cost atmosphere. No 3D model is loaded.

@onready var city: TextureRect = $City
@onready var atlant_frame: Control = $AtlantFrame
const Textures = preload("res://scripts/systems/texture_source.gd")
const Builder = preload("res://scripts/models/at01_2d_builder.gd")
var preview: SubViewportContainer
var preview_view: SubViewport
var preview_camera: Camera2D
var preview_actor: Node2D
@onready var pilot: TextureRect = $Pilot
var quality := 1
var reduced := false
var clock := 0.0
var accumulator := 0.0
var focused := true
var rain: Array[Vector3] = []
var parallax := Vector2.ZERO

func _ready() -> void:
 mouse_filter = Control.MOUSE_FILTER_IGNORE
 city.texture = Textures.png("res://assets/environments/night_city.png")
 _build_preview()
 var rng := RandomNumberGenerator.new()
 rng.seed = 2089
 for i in range(80): rain.append(Vector3(rng.randf(), rng.randf(), rng.randf_range(0.65,1.4)))
 SettingsManager.changed.connect(_setting_changed)
 resized.connect(_layout)
 visibility_changed.connect(_refresh)
 _refresh()
 _layout()

func _build_preview() -> void:
 var source := Textures.png("res://assets/background/pilot_menu.png")
 if source != null:
  var region := AtlasTexture.new();region.atlas = source;region.region = Rect2(270,153,463,1229);pilot.texture = region
 var builder := Builder.new();preview_actor = builder.create()
 if preview_actor == null: return
 preview = SubViewportContainer.new();preview.name = "CurrentAtlantPreview";preview.stretch = true;preview.mouse_filter = Control.MOUSE_FILTER_IGNORE;atlant_frame.add_child(preview)
 preview_view = SubViewport.new();preview_view.size = Vector2i(640,600);preview_view.world_2d = World2D.new();preview_view.disable_3d = true;preview_view.transparent_bg = true;preview_view.render_target_update_mode = SubViewport.UPDATE_WHEN_VISIBLE;preview.add_child(preview_view)
 preview_view.add_child(preview_actor);preview_actor.set_enabled(false)
 preview_camera = Camera2D.new();preview_view.add_child(preview_camera)

static func rain_budget(preset: int, reduce: bool) -> int:
 if reduce or preset == 0: return 0
 return 32 if preset == 1 else 80

func _refresh() -> void:
 quality = int(SettingsManager.get_value("video/quality"))
 reduced = bool(SettingsManager.get_value("video/reduced_motion"))
 set_process(focused and is_visible_in_tree() and not reduced and quality > 0)
 if reduced or quality < 2:
  parallax = Vector2.ZERO
  _layout()
 queue_redraw()

func _setting_changed(key: StringName, _value: Variant) -> void:
 if key == &"video/quality" or key == &"video/reduced_motion": _refresh()

func _layout() -> void:
 city.position = Vector2(-7,-5) + parallax * 0.3
 city.size = size + Vector2(14,10)
 atlant_frame.position = Vector2(size.x * 0.51, size.y * 0.055) + parallax
 atlant_frame.size = Vector2(size.x * 0.445, size.y * 0.725)
 if is_instance_valid(preview):
  preview.position = Vector2.ZERO;preview.size = atlant_frame.size
  var zoom := minf(atlant_frame.size.x/420.0,atlant_frame.size.y/650.0)
  preview_camera.zoom = Vector2.ONE*zoom;preview_camera.position = Vector2(0,-315)
 pilot.size = Vector2(size.y*0.104,size.y*0.234)
 pilot.position = Vector2(maxf(size.x*.37,350),size.y*.705) + parallax*1.3

func set_home_active(value: bool) -> void:
 pilot.visible = value
 queue_redraw()

func _process(delta: float) -> void:
 accumulator += delta
 if accumulator < 1.0/30.0: return
 clock += accumulator
 accumulator = 0.0
 if quality == 2 and not OS.has_feature("android"):
  var target := (get_global_mouse_position()/size-Vector2(.5,.5))*Vector2(6,3)
  parallax = parallax.lerp(target,0.07)
  _layout()
 queue_redraw()

func _draw() -> void:
 if is_instance_valid(pilot) and pilot.visible:
  var feet := pilot.position+Vector2(pilot.size.x*.52,pilot.size.y*.995)
  draw_set_transform(feet,0,Vector2(1,.17))
  draw_circle(Vector2.ZERO,pilot.size.x*.36,Color(.005,.009,.015,.5))
  draw_set_transform(Vector2.ZERO)
 if quality > 0:
  var drift := sin(clock*0.055)*0.018 if not reduced else 0.0
  for i in range(2 if quality == 1 else 4):
   var x := size.x*(.38+float(i)*.16+drift)
   draw_colored_polygon(PackedVector2Array([Vector2(x,0),Vector2(x-100,size.y*.76),Vector2(x+70,size.y*.76)]),Color(.4,.6,.85,.012))
  if quality == 2:
   for i in range(3):
    var y := size.y*(.57+i*.10)+sin(clock*.06+i)*6.0
    draw_rect(Rect2(size.x*.32,y,size.x*.68,25),Color(.35,.52,.68,.018))
 for i in range(rain_budget(quality,reduced)):
  var drop := rain[i]
  var x := fposmod(drop.x*size.x-clock*16.0*drop.z,size.x)
  var y := fposmod(drop.y*size.y+clock*150.0*drop.z,size.y)
  if x < size.x*.3: continue
  draw_line(Vector2(x,y),Vector2(x-2,y+13*drop.z),Color(.58,.72,.86,.11),1.0)
 # Foreground rail restores depth over the separately composited robot.
 var rail_y := size.y*.782
 draw_line(Vector2(size.x*.51,rail_y),Vector2(size.x*.95,rail_y),Color("091320"),5)
 draw_line(Vector2(size.x*.51,rail_y+size.y*.055),Vector2(size.x*.95,rail_y+size.y*.055),Color("0b1420"),4)
 for x_ratio: float in [.57,.72,.88]:
  var x := size.x*x_ratio
  draw_line(Vector2(x,rail_y-3),Vector2(x,rail_y+size.y*.09),Color("0b1420"),7)
  var glow := .16 if reduced or quality == 0 else .17+sin(clock*.65+x_ratio*20)*.025
  draw_circle(Vector2(x,rail_y-4),9,Color(1,.13,.16,glow))
  draw_rect(Rect2(x-3,rail_y-8,6,7),Color("ed5054"))

func _notification(what: int) -> void:
 if what == NOTIFICATION_APPLICATION_FOCUS_OUT or what == NOTIFICATION_APPLICATION_PAUSED:
  focused = false
  set_process(false)
 elif what == NOTIFICATION_APPLICATION_FOCUS_IN or what == NOTIFICATION_APPLICATION_RESUMED:
  focused = true
  if is_node_ready(): _refresh()
