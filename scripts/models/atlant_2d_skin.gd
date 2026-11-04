extends RefCounted
## The current seven-part OPLOT atlas is the only runtime Atlant skin.
const Textures = preload("res://scripts/systems/texture_source.gd")
const PATH := "res://assets/atlants/at01_oplot_atlas.png"
const SKIN_ID := "oplot-seven-part"
# Cell, first joint, second joint. Coordinates are measured inside one 443.5px cell.
const DATA := {
 "core":[Vector2i(0,0),Vector2(245,245),Vector2.ZERO],
 "upper_arm":[Vector2i(1,0),Vector2(271,137),Vector2(236,360)],
 "forearm":[Vector2i(2,0),Vector2(232,45),Vector2(237,391)],
 "head":[Vector2i(3,0),Vector2(228,205),Vector2.ZERO],
 "thigh":[Vector2i(0,1),Vector2(228,62),Vector2(195,397)],
 "shin":[Vector2i(1,1),Vector2(227,42),Vector2(225,393)],
 "foot":[Vector2i(2,1),Vector2(163,275),Vector2.ZERO]
}
static var atlas: Texture2D
static var atlas_origin := ""
static var cutout: ShaderMaterial
static var last_error := ""
static func prepare() -> bool:
 if atlas == null or atlas_origin != PATH:
  atlas = Textures.png(PATH);atlas_origin = PATH if atlas != null else ""
 if atlas == null: last_error = Textures.last_error;return false
 if cutout == null:
  cutout = ShaderMaterial.new();cutout.shader = preload("res://resources/theme/at01_cutout_2d.gdshader")
 last_error = "";return true
static func attach(body: Node2D,kind: String,length: float,far_side: bool,layer: int) -> void:
 if not prepare(): return
 var visual := Node2D.new();visual.name = "Visual";visual.z_index = layer;visual.set_meta("skin",SKIN_ID);body.add_child(visual);visual.owner = body.owner
 var data: Array = DATA[kind];var cell := Vector2(atlas.get_width()/4.0,atlas.get_height()/2.0)
 var region := AtlasTexture.new();region.atlas = atlas;region.region = Rect2(Vector2(data[0])*cell,cell);region.filter_clip = true
 var sprite := Sprite2D.new();sprite.name = "PaintedArmor";sprite.texture = region;sprite.centered = false;sprite.offset = -Vector2(data[1]);sprite.material = cutout
 sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
 var scale_value := .65
 if kind in ["upper_arm","forearm","thigh","shin"]:
  var line: Vector2 = Vector2(data[2])-Vector2(data[1]);scale_value = length/line.length();sprite.rotation = -atan2(-line.x,line.y);visual.position = Vector2(0,-length*.5)
 elif kind == "foot": scale_value = .40;visual.position = Vector2(-.24,-.28)*64.0
 elif kind == "head": scale_value = .43
 sprite.scale = Vector2.ONE*scale_value;sprite.modulate = Color(.70,.77,.83) if far_side else Color.WHITE
 visual.add_child(sprite);sprite.owner = body.owner
 # Use the same cell, pivot, rotation and scale as the painted armor.
 var cell_index: int = int(data[0].y)*4+int(data[0].x)
 var silhouette: PackedVector2Array = PackedVector2Array(preload("res://scripts/models/collision_profiles.gd").ATLANT[cell_index])
 var points := PackedVector2Array()
 for point: Vector2 in silhouette: points.append(visual.position+((point-Vector2(data[1]))*scale_value).rotated(sprite.rotation))
 var shape := ConvexPolygonShape2D.new();shape.points = points
 var collision := body.get_node("Collision") as CollisionShape2D;collision.shape = shape
