extends Node2D
const CAPACITY := 48
var positions: Array[Vector2] = []
var velocities: Array[Vector2] = []
var lives: Array[float] = []
var rng := RandomNumberGenerator.new()
func _ready() -> void:
 rng.seed = 734
 for i in range(CAPACITY): positions.append(Vector2.ZERO);velocities.append(Vector2.ZERO);lives.append(0.0)
 set_process(false)
func burst(point: Vector2,strength: float) -> void:
 if bool(SettingsManager.get_value("video/reduced_motion")): return
 var budget: int = [5,9,14][int(SettingsManager.get_value("video/quality"))]
 for i in range(CAPACITY):
  if budget == 0: break
  if lives[i] > 0: continue
  positions[i] = point
  velocities[i] = Vector2(rng.randf_range(-240,240),rng.randf_range(-260,50))*maxf(.4,strength)
  lives[i] = rng.randf_range(.16,.36)
  budget -= 1
 set_process(true)
func _process(delta: float) -> void:
 var active := false
 for i in range(CAPACITY):
  if lives[i] <= 0: continue
  lives[i] -= delta
  positions[i] += velocities[i]*delta
  velocities[i].y += 450*delta
  active = active or lives[i] > 0
 queue_redraw()
 set_process(active)
func _draw() -> void:
 for i in range(CAPACITY):
  if lives[i] > 0:
   draw_line(positions[i],positions[i]-velocities[i].normalized()*7,Color(1,.64,.22,minf(1,lives[i]*6)),2,true)
