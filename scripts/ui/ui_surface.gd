extends PanelContainer
@export var accent := Color("bd9d59")
@export var opacity := .96
@export var inset_border := false
func _ready() -> void:
 add_theme_stylebox_override("panel",StyleBoxEmpty.new())
 resized.connect(queue_redraw)
func _draw() -> void:
 var w := size.x;var h := size.y;var cut := 10.0
 var p := PackedVector2Array([Vector2(0,0),Vector2(w-cut,0),Vector2(w,cut),Vector2(w,h),Vector2(cut,h),Vector2(0,h-cut)])
 draw_colored_polygon(p,Color(.042,.067,.082,opacity))
 var edge := p;edge.append(p[0]);draw_polyline(edge,Color(.34,.43,.46,.58),1,true)
 draw_line(Vector2(1,1),Vector2(minf(60,w-12),1),accent,2,true)
 draw_line(Vector2(w-1,h-26),Vector2(w-1,h-10),Color(.58,.68,.69,.6),2)
 if inset_border and w>28 and h>28: draw_rect(Rect2(10,10,w-20,h-20),Color(.35,.46,.48,.13),false,1)
