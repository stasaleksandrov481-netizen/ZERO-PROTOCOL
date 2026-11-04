extends Node2D
## Infinite mirrored panoramic layers, bounded rain and water particles.
const Textures = preload("res://scripts/systems/texture_source.gd")
var initialized := false
var startup_error := ""
var camera: Camera2D
var biome := "sea"
var route_end := 5200.0
var clock := 0.0
var landing_phase := 1.0
var helicopter_x := 0.0
var helicopter_y := -910.0
var atlas: Texture2D
var transport: Texture2D
var water: Polygon2D
var water_material: ShaderMaterial
var splashes: Array[Dictionary] = []
var wakes: Array[Dictionary] = []
var last_splash := -1.0
var rain: Node2D
var foreground: Node2D
var view := Rect2(-1600,-1100,3200,1500)
const WATER_Y := -145.0
const MAX_SPRAY := 320
var last_splashes: Dictionary = {}
class FrontEffects extends Node2D:
 var environment: Node2D
 func _draw() -> void: environment.draw_effects(self)
func _ready() -> void:
 z_index = -15
 atlas = Textures.png("res://assets/environments/night_"+biome+".png")
 transport = Textures.png("res://assets/environments/heavy_transport.png")
 if atlas == null or transport == null:
  startup_error = "Не загружены изображения окружения или транспорта.";set_process(false);return
 if biome == "sea":
  water = Polygon2D.new();water.name = "WaterSurface";water.z_index = 25;water.z_as_relative = false;add_child(water)
  water_material = ShaderMaterial.new();water_material.shader = load("res://resources/theme/coastal_water.gdshader");water.material = water_material
 foreground = FrontEffects.new();foreground.environment = self;foreground.z_index = 30;foreground.z_as_relative = false;add_child(foreground)
 initialized = true
func _process(delta: float) -> void:
 clock += delta
 if is_instance_valid(camera):
  var extent := Vector2(get_viewport_rect().size)/camera.zoom
  view = Rect2(camera.get_screen_center_position()-extent*.5,extent)
 if is_instance_valid(water):
  var poly := PackedVector2Array()
  var start := view.position.x-120
  for i in range(83):
   var x := start+float(i)/82*(view.size.x+240)
   poly.append(Vector2(x,surface_y(x)))
  poly.append(Vector2(start+view.size.x+240,maxf(500,view.end.y+200)));poly.append(Vector2(start,maxf(500,view.end.y+200)))
  water.polygon = poly;water_material.set_shader_parameter("clock",clock)
 for i in range(splashes.size()-1,-1,-1):
  var spray: Dictionary = splashes[i];spray.age += delta;spray.velocity.y += 420*delta;spray.point += spray.velocity*delta
  if spray.age > spray.life: splashes.remove_at(i)
 for i in range(wakes.size()-1,-1,-1):
  wakes[i].age += delta
  if wakes[i].age > 2.4: wakes.remove_at(i)
 queue_redraw();foreground.queue_redraw()
func surface_y(x: float) -> float:
 var y := WATER_Y+sin(x*.013+clock*1.3)*2.4+sin(x*.031-clock)*1.2
 for wake: Dictionary in wakes:
  var front: float = absf(x-float(wake.x))-float(wake.age)*175.0
  y += sin(front*.07)*exp(-absf(front)*.017)*(1-float(wake.age)/2.4)*float(wake.strength)*13
 return y
func splash(x: float,strength: float = .5) -> void:
 if biome != "sea": return
 var bucket := roundi(x/56.0)
 if clock-float(last_splashes.get(bucket,-10.0)) < .18 and strength < .9: return
 last_splashes[bucket] = clock
 if last_splashes.size() > 24:
  for key: int in last_splashes.keys():
   if clock-float(last_splashes[key]) > 2: last_splashes.erase(key)
 last_splash = clock
 if wakes.size() >= 16: wakes.pop_front()
 wakes.append({"x":x,"age":0.0,"strength":strength})
 var count := 46 if strength < .9 else 84
 if int(SettingsManager.get_value("video/quality")) == 0: count = int(count*.65)
 for i in range(count):
  if splashes.size() >= MAX_SPRAY: splashes.pop_front()
  var t := float(i)/count
  splashes.append({"point":Vector2(x+sin(i*21.2)*30,WATER_Y),"velocity":Vector2((t-.5)*(220+strength*220),-85-absf(sin(i*8.1))*(125+strength*190)),"age":0.0,"life":.65+absf(sin(i*3.4))*.55})
 if AudioManager.has_method("play_splash"): AudioManager.play_splash(strength)
func _draw() -> void:
 if atlas == null: return
 draw_rect(view.grow(500),Color("06101b"))
 var source := Rect2(Vector2.ZERO,Vector2(atlas.get_size()))
 var height := maxf(1250,view.size.y*1.4);var width := height*source.size.x/source.size.y
 var parallax_x: float = camera.get_screen_center_position().x*.80 if is_instance_valid(camera) else 0.0
 parallax_x -= width*.50
 var top := -145-height*.54 if biome == "sea" else -height*(.78 if biome == "city" else .82)
 var base_index := floori((view.position.x-parallax_x)/width)
 for i in range(base_index,base_index+3):
  var x := float(i)*width+parallax_x
  if posmod(i,2) == 0: draw_texture_rect_region(atlas,Rect2(x,top,width,height),source)
  else:
   draw_set_transform(Vector2(x+width,0),0,Vector2(-1,1))
   draw_texture_rect_region(atlas,Rect2(0,top,width,height),source)
   draw_set_transform(Vector2.ZERO)
 if biome != "sea": draw_line(Vector2(view.position.x-200,0),Vector2(view.end.x+200,0),Color(.48,.62,.69,.35),1.5,true)
 # A docking mast provides a readable destination in the live world.
 var dock_x := route_end-100
 draw_rect(Rect2(dock_x,-545,27,545),Color("233442"));draw_rect(Rect2(dock_x+27,-505,130,17),Color("50616a"))
 draw_circle(Vector2(dock_x+13,-558),7,Color("e2a343"));draw_circle(Vector2(dock_x+13,-558),26,Color(.9,.55,.15,.07))
 for j in range(6): draw_line(Vector2(dock_x+2,-110-j*70),Vector2(dock_x+24,-126-j*70),Color("a08848"),6)
 if landing_phase < 1.0:
  var p := Vector2(helicopter_x,helicopter_y)
  for i in range(2):
   var offset := Vector2(-430,-95) if i == 0 else Vector2(130,0)
   var color := Color(.65,.76,.84,.90) if i == 0 else Color(.84,.90,1)
   draw_texture_rect(transport,Rect2(p+offset-Vector2(355,115),Vector2(710,237)),false,color)
   for rotor in [-230,180]:
    draw_line(p+offset+Vector2(rotor-155,-87),p+offset+Vector2(rotor+155,-87),Color(.61,.73,.78,.25+sin(clock*95)*.10),4,true)
   if landing_phase < .28:
    draw_line(p+offset+Vector2(-100,108),p+offset+Vector2(-30,350),Color("6e8791"),2,true)
    draw_line(p+offset+Vector2(125,108),p+offset+Vector2(40,350),Color("6e8791"),2,true)
func draw_effects(canvas: Node2D) -> void:
 # Deterministic rain; fixed work independent of route length.
 var amount := 125 if int(SettingsManager.get_value("video/quality")) > 0 else 55
 for i in range(amount):
  var x := view.position.x+fposmod(i*187.51-clock*155,view.size.x)
  var y := view.position.y+fposmod(i*93.71+clock*(800+i%7*40),view.size.y)
  canvas.draw_line(Vector2(x,y),Vector2(x-5,y+28),Color(.52,.71,.82,.10+float(i%3)*.025),1,true)
 if biome == "sea":
  var edge := PackedVector2Array()
  for i in range(100):
   var x := view.position.x-20+float(i)/99*(view.size.x+40);edge.append(Vector2(x,surface_y(x)))
  canvas.draw_polyline(edge,Color(.53,.77,.82,.55),2,true)
 for wake: Dictionary in wakes:
  var radius: float = 18+wake.age*175
  for direction: int in [-1,1]:
   var x: float = wake.x+direction*radius
   canvas.draw_line(Vector2(x-18,surface_y(x)-1),Vector2(x+18,surface_y(x+18)-1),Color(.76,.90,.93,(1-wake.age/2.4)*.68),2.6,true)
  var foam_width: float = 36+wake.age*38
  canvas.draw_line(Vector2(wake.x-foam_width,WATER_Y-1),Vector2(wake.x+foam_width,WATER_Y-1),Color(.65,.85,.89,maxf(0,1-wake.age/1.2)*.45),3,true)
 for spray: Dictionary in splashes:
  var alpha: float = 1-spray.age/spray.life
  canvas.draw_line(spray.point,spray.point-spray.velocity*.025,Color(.73,.88,.93,alpha*.82),2.2,true)
 # Shore marker lights and their broken reflections stay in world coordinates.
 if biome == "sea":
  for i in range(floori(view.position.x/780),ceili(view.end.x/780)+1):
   var x := i*780.0+500
   canvas.draw_line(Vector2(x,-143),Vector2(x,-215),Color("425763"),5)
   canvas.draw_circle(Vector2(x,-218),5,Color("efb24d"));canvas.draw_circle(Vector2(x,-218),20,Color(.94,.58,.15,.08))
   canvas.draw_line(Vector2(x-12,WATER_Y),Vector2(x+12,WATER_Y),Color(.9,.60,.22,.45),2,true)
