extends Node2D
var camera: Camera2D
var trauma := 0.0
var clock := 0.0
var shockwaves: Array[Dictionary] = []
func hit(point: Vector2,strength: float,direction: Vector2) -> void:
 trauma = maxf(trauma,clampf(strength,0,1))
 AudioManager.play_impact(strength)
 if shockwaves.size() > 8: shockwaves.pop_front()
 shockwaves.append({"point":point,"age":0.0,"strength":strength,"direction":direction})
func cancel() -> void:
 trauma = 0;shockwaves.clear()
 if is_instance_valid(camera): camera.offset = Vector2.ZERO
func _process(delta: float) -> void:
 clock += delta;trauma = maxf(0,trauma-delta*2.7)
 if is_instance_valid(camera):
  var reduced := bool(SettingsManager.get_value("video/reduced_motion"))
  camera.offset = Vector2(sin(clock*81),cos(clock*63))*trauma*trauma*(0 if reduced else 14)
 for i in range(shockwaves.size()-1,-1,-1):
  shockwaves[i].age += delta
  if shockwaves[i].age > .32: shockwaves.remove_at(i)
 queue_redraw()
func _draw() -> void:
 for shock: Dictionary in shockwaves:
  var fade: float = 1-shock.age/.32
  draw_arc(shock.point,12+shock.age*250,0,TAU,32,Color(.65,.81,.84,fade*.24),2,true)
