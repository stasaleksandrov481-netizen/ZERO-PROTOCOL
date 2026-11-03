extends Control
@export var kind := "radio"
@export var color := Color("b8cccd")
func _ready() -> void: mouse_filter = Control.MOUSE_FILTER_IGNORE
func _draw() -> void:
 var s := minf(size.x,size.y);var p := (size-Vector2.ONE*s)*.5
 draw_set_transform(p,0,Vector2.ONE*s/24.0)
 match kind:
  "settings":
   draw_arc(Vector2(12,12),7,0,TAU,36,color,2,true);draw_arc(Vector2(12,12),2.8,0,TAU,24,color,1.6,true)
   for i in range(8):
    var d := Vector2.RIGHT.rotated(i*TAU/8);draw_line(Vector2(12,12)+d*7,Vector2(12,12)+d*10.5,color,3,true)
  "campaign":
   draw_colored_polygon(PackedVector2Array([Vector2(2,4),Vector2(10,4),Vector2(12,8),Vector2(17,4),Vector2(22,4),Vector2(12,22)]),Color("92b6c5"))
   draw_colored_polygon(PackedVector2Array([Vector2(9,10),Vector2(15,10),Vector2(12,15)]),Color("cf6a63"))
  "radio":
   draw_arc(Vector2(12,11),8,-.85,.85,24,color,1.5,true);draw_arc(Vector2(12,11),4,-.85,.85,16,color,1.5,true)
   draw_line(Vector2(8,7),Vector2(8,18),color,1.5,true);draw_line(Vector2(8,18),Vector2(14,18),color,1.5,true);draw_circle(Vector2(8,5),2,color)
  "pause":
   draw_rect(Rect2(6,5,4,14),color);draw_rect(Rect2(14,5,4,14),color)
  "map":
   draw_polyline(PackedVector2Array([Vector2(3,5),Vector2(9,3),Vector2(15,6),Vector2(21,3),Vector2(21,19),Vector2(15,22),Vector2(9,19),Vector2(3,21),Vector2(3,5)]),color,1.3,true)
   draw_line(Vector2(9,3),Vector2(9,19),color,1,true);draw_line(Vector2(15,6),Vector2(15,22),color,1,true)
  "target":
   draw_arc(Vector2(12,12),7,0,TAU,32,color,1.3,true);draw_circle(Vector2(12,12),2,color)
   for d: Vector2 in [Vector2.UP,Vector2.DOWN,Vector2.LEFT,Vector2.RIGHT]: draw_line(Vector2(12,12)+d*8,Vector2(12,12)+d*11,color,1)
  "shield":
   draw_polyline(PackedVector2Array([Vector2(4,4),Vector2(20,4),Vector2(19,15),Vector2(12,21),Vector2(5,15),Vector2(4,4)]),color,1.5,true)
  "box":
   draw_rect(Rect2(5,5,14,14),color,false,1.4);draw_line(Vector2(5,8),Vector2(19,8),color,1.4);draw_line(Vector2(10,5),Vector2(10,11),color,1.4)
  "back": draw_polyline(PackedVector2Array([Vector2(15,5),Vector2(8,12),Vector2(15,19)]),color,1.8,true)
  "next": draw_polyline(PackedVector2Array([Vector2(9,5),Vector2(16,12),Vector2(9,19)]),color,1.8,true)
  "history":
   for i in range(3): draw_line(Vector2(6,6+i*6),Vector2(19,6+i*6),color,1.5);draw_circle(Vector2(3,6+i*6),.8,color)
  "crew":
   draw_circle(Vector2(10,7),3.4,color);draw_arc(Vector2(10,19),6,PI,TAU,20,color,1.5,true);draw_arc(Vector2(17,8),3,-1.5,1.5,16,color,1.2,true)
  "check": draw_polyline(PackedVector2Array([Vector2(5,12),Vector2(10,17),Vector2(20,6)]),color,2,true)
  "reset":
   draw_arc(Vector2(12,12),7,-PI*.7,PI*.9,24,color,1.5,true);draw_polyline(PackedVector2Array([Vector2(4,5),Vector2(7,5),Vector2(7,8)]),color,1.5,true)
 draw_set_transform(Vector2.ZERO)
