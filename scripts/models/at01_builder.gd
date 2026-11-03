extends RefCounted
## Compatibility entry point: all active actors now use the strict 2D cutout rig.
const Builder2D = preload("res://scripts/models/at01_2d_builder.gd")
func create() -> Node2D:
 return Builder2D.new().create()
