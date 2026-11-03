extends RefCounted
## Fixed painted cutouts. No meshes, lights, billboards, yaw or 3D projection.
static var atlas: Texture2D
static var cutout: ShaderMaterial
const PATH := "res://assets/atlants/at01_horizon_cutout_atlas.png"
const DATA := {
 "core": [Vector2i(0,0),Vector2(310,350),Vector2.ZERO,Vector2.ZERO],
 "upper_arm": [Vector2i(1,0),Vector2(288,165),Vector2(261,453),Vector2.ZERO],
 "forearm": [Vector2i(2,0),Vector2(157,75),Vector2(233,377),Vector2.ZERO],
 "thigh": [Vector2i(0,1),Vector2(229,119),Vector2(293,440),Vector2.ZERO],
 "shin": [Vector2i(1,1),Vector2(261,68),Vector2(238,437),Vector2.ZERO],
 "foot": [Vector2i(2,1),Vector2(133,252),Vector2.ZERO,Vector2.ZERO],
}
static func _load_art() -> void:
 if atlas == null:
  if FileAccess.file_exists(PATH):
   var source := Image.new()
   if source.load_png_from_buffer(FileAccess.get_file_as_bytes(PATH)) == OK:
    source.generate_mipmaps()
    atlas = ImageTexture.create_from_image(source)
  elif ResourceLoader.exists(PATH): atlas = load(PATH)
 if cutout == null:
  cutout = ShaderMaterial.new()
  cutout.shader = load("res://resources/theme/at01_cutout_2d.gdshader")

static func attach(body: Node2D, kind: String, length: float, far_side: bool, layer: int) -> void:
 _load_art()
 if kind == "head":
  _attach_head(body,layer);return
 var visual := Node2D.new()
 visual.name = "Visual"
 visual.z_index = layer
 body.add_child(visual)
 visual.owner = body.owner
 var data: Array = DATA[kind]
 var region := AtlasTexture.new()
 region.atlas = atlas
 region.region = Rect2(Vector2(data[0])*512.0,Vector2(512,512))
 var sprite := Sprite2D.new()
 sprite.name = "PaintedArmor"
 sprite.texture = region
 sprite.centered = false
 sprite.offset = -Vector2(data[1])
 sprite.material = cutout.duplicate() if kind == "core" else cutout
 if kind == "core": sprite.material.set_shader_parameter("hide_head",true)
 sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
 var scale_value := .70
 if kind in ["upper_arm","forearm","thigh","shin"]:
  var line: Vector2 = Vector2(data[2])-Vector2(data[1])
  scale_value = length/line.length()
  sprite.rotation = -atan2(-line.x,line.y)
  visual.position = Vector2(0,-length*.5)
 elif kind == "foot":
  scale_value = .29
  visual.position = Vector2(-.24,-.28)*64.0
 sprite.scale = Vector2.ONE*scale_value
 sprite.modulate = Color(.75,.77,.80,1) if far_side else Color.WHITE
 visual.add_child(sprite)
 sprite.owner = body.owner

static func _attach_head(body: Node2D,layer: int) -> void:
 var visual := Node2D.new();visual.name = "Visual";visual.z_index = layer;body.add_child(visual)
 var region := AtlasTexture.new();region.atlas = atlas;region.region = Rect2(263,105,208,154)
 var sprite := Sprite2D.new();sprite.name = "PaintedArmor";sprite.texture = region;sprite.material = cutout;sprite.centered = false;sprite.offset = Vector2(-102,-72);sprite.scale = Vector2.ONE*.7;visual.add_child(sprite)
