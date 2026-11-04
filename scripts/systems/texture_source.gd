extends RefCounted
## Source PNGs work in the Android editor even with absent or stale desktop imports.
## Exported remaps remain supported when source bytes are not included in a pack.
static var cache: Dictionary = {}
static var last_error := ""
static var source_reads := 0
static var import_reads := 0
static func png(path: String) -> Texture2D:
 last_error = ""
 if cache.has(path): return cache[path]
 var texture: Texture2D
 if FileAccess.file_exists(path):
  var bytes := FileAccess.get_file_as_bytes(path)
  var image := Image.new()
  if bytes.size() >= 8 and image.load_png_from_buffer(bytes) == OK and not image.is_empty():
   image.generate_mipmaps();texture = ImageTexture.create_from_image(image);source_reads += 1
 elif ResourceLoader.exists(path):
  texture = ResourceLoader.load(path,"Texture2D") as Texture2D
  if texture != null: import_reads += 1
 if texture == null or texture.get_width() <= 0 or texture.get_height() <= 0:
  last_error = "Не удалось прочитать изображение «%s». Проверьте, что проект распакован целиком."%path.trim_prefix("res://")
  return null
 cache[path] = texture;return texture
static func require_png(paths: Array[String]) -> String:
 for path: String in paths:
  if png(path) == null: return last_error
 return ""
static func forget(path: String) -> void: cache.erase(path)
