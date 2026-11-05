extends Node2D
var camera: Camera2D
var trauma := 0.0
var clock := 0.0
var shockwaves: Array[Dictionary] = []
var foot_weight := 0.0
var foot_age := 0.0
var kick_age := 1.0
var kick_strength := 0.0
var kick_direction := Vector2.RIGHT
func step_weight(strength: float) -> void:
 foot_weight = maxf(foot_weight,clampf(strength,0,1));foot_age = 0
func hit(point: Vector2,strength: float,direction: Vector2) -> void:
 strength = clampf(strength,0,1)
 trauma = maxf(trauma,clampf(strength,0,1))
 AudioManager.play_impact(strength)
 if kick_age > .10 or strength > kick_strength+.12:
  kick_age = 0;kick_strength = strength
  kick_direction = direction.normalized() if direction.length_squared() > .001 else Vector2.RIGHT
 # One contact burst must not become dozens of visual rings from solver chatter.
 for recent: Dictionary in shockwaves:
  if recent.age < .08 and point.distance_squared_to(recent.point) < 96*96:
   recent.strength = maxf(recent.strength,strength);return
 if shockwaves.size() >= 8: shockwaves.pop_front()
 shockwaves.append({"point":point,"age":0.0,"strength":strength,"direction":direction})
func framing_pullback() -> float:
 if bool(SettingsManager.get_value("video/reduced_motion")) or kick_age >= .65: return 0
 return sin(kick_age/.65*PI)*kick_strength*.10
func cancel() -> void:
 trauma = 0;shockwaves.clear();foot_weight = 0;foot_age = 0
 kick_age = 1;kick_strength = 0
 if is_instance_valid(camera): camera.offset = Vector2.ZERO
func _process(delta: float) -> void:
 clock += delta;trauma = maxf(0,trauma-delta*2.7)
 kick_age += delta
 foot_age += delta
 if foot_age > .55: foot_weight = 0
 if is_instance_valid(camera):
  var reduced := bool(SettingsManager.get_value("video/reduced_motion"))
  camera.offset = Vector2.ZERO
  if not reduced:
   var rebound := sin(minf(kick_age/.42,1)*TAU)*exp(-kick_age*6)*kick_strength*18
   camera.offset = kick_direction*rebound+Vector2(sin(clock*81),cos(clock*63))*trauma*trauma*3.5
   camera.offset.y += sin(foot_age*25)*exp(-foot_age*8)*foot_weight*4.5
 for i in range(shockwaves.size()-1,-1,-1):
  shockwaves[i].age += delta
  if shockwaves[i].age > .32: shockwaves.remove_at(i)
 queue_redraw()
func _draw() -> void:
 for shock: Dictionary in shockwaves:
  var fade: float = 1-shock.age/.32
  var aim: float = Vector2(shock.direction).angle()
  draw_arc(shock.point,12+shock.age*250,aim-1.25,aim+1.25,24,Color(.65,.81,.84,fade*.24),2,true)
  if shock.age < .10: draw_circle(shock.point,3+shock.age*28,Color(.94,.83,.61,(1-shock.age/.10)*.45))
