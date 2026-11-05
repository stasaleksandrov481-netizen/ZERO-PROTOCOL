class_name VirtualHandStick
extends Control
## Each stick owns its own touch index; multi-touch does not depend on mouse emulation.

const UiStyle = preload("res://scripts/ui/rift_ui.gd")

@export var caption := "ЛЕВАЯ РУКА"
@export var hand_index := 0
var value := Vector2.ZERO
var touch_index := -1
var mouse_active := false
var radius := 65.0
var origin := Vector2.ZERO
var active := true
var drive_load := 0.0
var contact_flash := 0.0

func show_contact(strength: float) -> void:
 contact_flash = maxf(contact_flash,clampf(strength,0,1));set_process(true);queue_redraw()
func _process(delta: float) -> void:
 contact_flash = move_toward(contact_flash,0,delta*3.8)
 queue_redraw()
 if contact_flash == 0: set_process(false)

func _ready() -> void:
 mouse_filter = Control.MOUSE_FILTER_IGNORE
 resized.connect(_layout)
 _layout()
 set_process(false)

func _layout() -> void:
 origin = Vector2(roundf(size.x*.5),roundf((size.y-30)*.5))
 radius = floorf(minf(size.x,size.y-30)*.45)
 queue_redraw()

func _input(event: InputEvent) -> void:
 if not active: return
 if event is InputEventScreenTouch:
  var point := _local(event.position)
  if event.pressed and touch_index == -1 and point.distance_to(origin) <= radius*1.15:
   touch_index = event.index
   _update_value(point)
   get_viewport().set_input_as_handled()
  elif not event.pressed and event.index == touch_index:
   release()
   get_viewport().set_input_as_handled()
 elif event is InputEventScreenDrag and event.index == touch_index:
  _update_value(_local(event.position))
  get_viewport().set_input_as_handled()
 elif event is InputEventMouseButton and event.device != InputEvent.DEVICE_ID_EMULATION:
  if event.button_index != MOUSE_BUTTON_LEFT: return
  var point := _local(event.position)
  if event.pressed and point.distance_to(origin) <= radius*1.15:
   mouse_active = true
   _update_value(point)
   get_viewport().set_input_as_handled()
  elif not event.pressed and mouse_active:
   release()
   get_viewport().set_input_as_handled()
 elif event is InputEventMouseMotion and mouse_active:
  _update_value(_local(event.position))
  get_viewport().set_input_as_handled()

func _local(point: Vector2) -> Vector2:
 return get_global_transform_with_canvas().affine_inverse()*point

func _update_value(point: Vector2) -> void:
 value = ((point-origin)/radius).limit_length(1.0)
 if value.length() < .08: value = Vector2.ZERO
 queue_redraw()

func release() -> void:
 touch_index = -1
 mouse_active = false
 value = Vector2.ZERO
 queue_redraw()

func _notification(what: int) -> void:
 if what in [NOTIFICATION_APPLICATION_FOCUS_OUT,NOTIFICATION_APPLICATION_PAUSED]: release()

func _draw() -> void:
 var color := UiStyle.CYAN if hand_index == 1 else Color("bcc6ce")
 var held := touch_index >= 0 or mouse_active
 draw_circle(origin,radius,Color(.025,.04,.055,.19 if held else .09))
 draw_arc(origin,radius+3,0,TAU,128,Color(color,.10),7,true)
 draw_arc(origin,radius,0,TAU,128,Color(color,.88 if held else .50),1.3,true)
 draw_arc(origin,radius+5,-.23,.23,18,Color("d5ac57"),2.0,true)
 draw_arc(origin,radius+5,PI-.23,PI+.23,18,Color("d5ac57"),2.0,true)
 draw_arc(origin,radius*.55,0,TAU,96,Color(color,.16),1.0,true)
 draw_line(origin-Vector2(radius*.72,0),origin+Vector2(radius*.72,0),Color(color,.15),1,true)
 draw_line(origin-Vector2(0,radius*.72),origin+Vector2(0,radius*.72),Color(color,.15),1,true)
 for direction: Vector2 in [Vector2.LEFT,Vector2.RIGHT,Vector2.UP,Vector2.DOWN]:
  draw_line(origin+direction*(radius-7),origin+direction*(radius+4),Color(color,.65),2,true)
 var load_color := Color("d5ac70") if drive_load < .9 else Color("d16a62")
 draw_arc(origin,radius+5,-PI*.5,-PI*.5+TAU*clampf(drive_load,0,1),64,Color(load_color,.6),2,true)
 var knob := origin+value*radius*.72
 draw_circle(knob,radius*.25,Color(.075,.115,.14,.75 if held else .42))
 draw_arc(knob,radius*.25,0,TAU,64,Color(color,.92),2,true)
 draw_circle(knob,3,Color(color,.75))
 if contact_flash > 0:
  var reduced := bool(SettingsManager.get_value("video/reduced_motion"))
  draw_arc(origin,radius+(0 if reduced else (1-contact_flash)*5),-.7,.7,24,Color(.94,.74,.39,contact_flash*.90),3,true)
  draw_arc(knob,radius*.25,0,TAU,48,Color(.97,.82,.53,contact_flash),2.5,true)
 var y := size.y-28.0
 var plate := PackedVector2Array([Vector2(43,y),Vector2(size.x-43,y),Vector2(size.x-34,y+12),Vector2(size.x-43,y+24),Vector2(43,y+24),Vector2(34,y+12),Vector2(43,y)])
 draw_colored_polygon(plate,Color(.02,.05,.07,.7));draw_polyline(plate,Color("a38a54"),1,true)
 var text_width := UiStyle.FONT.get_string_size(caption,HORIZONTAL_ALIGNMENT_LEFT,-1,14).x
 draw_string(UiStyle.FONT,Vector2(roundf((size.x-text_width)*.5),size.y-11),caption,HORIZONTAL_ALIGNMENT_LEFT,-1,14,color)
