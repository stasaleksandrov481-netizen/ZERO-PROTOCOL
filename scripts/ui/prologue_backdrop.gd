extends Control
## A bounded side-on convoy shot. Text remains separate and crisp at any UI scale.
const Textures = preload("res://scripts/systems/texture_source.gd")
var sea: Texture2D
var transport: Texture2D
var clock := 0.0
var shot := 0
var reduced_motion := false
var approach := 0.0
func _ready() -> void:
 mouse_filter = Control.MOUSE_FILTER_IGNORE
 sea = Textures.png("res://assets/environments/night_sea.png")
 transport = Textures.png("res://assets/environments/heavy_transport.png")
 resized.connect(queue_redraw)
func _process(delta: float) -> void:
 reduced_motion = bool(SettingsManager.get_value("video/reduced_motion"))
 if not reduced_motion: clock += minf(delta,.05)
 approach = float(shot)/4.0 if reduced_motion else lerpf(approach,float(shot)/4.0,1-exp(-delta*.8))
 queue_redraw()
func _draw() -> void:
 draw_rect(Rect2(Vector2.ZERO,size),Color("040c14"))
 var compact := size.y < 620
 var horizon := size.y*.40
 if sea != null:
  var scale_value := maxf(size.x/sea.get_width(),size.y/sea.get_height())*(1.07+approach*.025)
  var extent := sea.get_size()*scale_value
  var drift := Vector2(sin(clock*.045)*12,sin(clock*.07)*4)
  draw_texture_rect(sea,Rect2((size-extent)*.5+drift,extent),false,Color(.55,.69,.82))
 # A smooth dark field behind the typography, preserving the distant shore lights.
 for i in range(48):
  var x := float(i)*size.x/48
  var amount := pow(1.0-float(i)/48.0,2)*.82+.04
  draw_rect(Rect2(x,0,size.x/48+1,size.y),Color(.006,.018,.031,amount))
 for i in range(18):
  draw_rect(Rect2(0,size.y*.63+float(i)*size.y*.37/18,size.x,size.y*.37/18+1),Color(.004,.012,.022,.08+float(i)*.038))
 var main := Vector2(size.x*(.73-.025*approach),size.y*(.27 if compact else .31))+Vector2(sin(clock*.23)*8,sin(clock*.43)*4)
 _craft(main+Vector2(-size.x*.19,-31),size.x*.23,.48)
 _craft(main,size.x*(.38+.035*approach),.97)
 # Rain is deliberately sparse and deterministic; no flashing or camera shake.
 var quality := int(SettingsManager.get_value("video/quality"))
 if not reduced_motion and quality > 0:
  for i in range(42 if quality == 1 else 68):
   var p := Vector2(fposmod(i*143.7-clock*43,size.x+30)-15,fposmod(i*83.19+clock*215,size.y+40)-20)
   draw_line(p,p+Vector2(-4,17+fposmod(i*4.1,11)),Color(.56,.73,.84,.07),.8,true)
 for i in range(9):
  var y := horizon+i*15
  draw_line(Vector2(size.x*.52,y),Vector2(size.x*(.78+sin(i)*.1),y),Color(.4,.65,.75,.018),1)
func _craft(centre: Vector2,width: float,opacity: float) -> void:
 var extent := Vector2(width,width/3.0)
 var light := centre+extent*Vector2(.36,.28)
 draw_colored_polygon(PackedVector2Array([light,light+Vector2(-width*.12,width*.65),light+Vector2(width*.35,width*.65)]),Color(.53,.70,.77,.018*opacity))
 if transport != null: draw_texture_rect(transport,Rect2(centre-extent*.5,extent),false,Color(.70,.81,.88,opacity))
 for offset: float in [-.25,.24]:
  var p := centre+extent*Vector2(offset,-.36)
  draw_line(p-Vector2(width*.23,0),p+Vector2(width*.23,0),Color(.63,.80,.86,.18*opacity),2,true)
 var beacon := centre+extent*Vector2(.32,.31)
 draw_circle(beacon,13,Color(.95,.58,.23,.035*opacity));draw_circle(beacon,2,Color(.96,.68,.36,opacity))
