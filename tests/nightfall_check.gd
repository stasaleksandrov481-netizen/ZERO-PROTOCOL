extends Node
func _ready() -> void: call_deferred("_run")
func _run() -> void:
 print("AUTOLOADS: ",get_tree().root.get_children())
 var paths := ["res://scripts/ui/enlistment_screen.gd","res://scripts/ui/campaign_map.gd","res://scripts/ui/combat_hud.gd","res://scripts/gameplay/expedition_screen.gd","res://scripts/gameplay/coastal_environment.gd","res://scripts/gameplay/klyk_2d.gd","res://scenes/menu/main_menu.tscn"]
 for path: String in paths:
  var resource := load(path)
  print("RESOURCE: ",path," => ",resource)
  if resource is Script: print("CAN INSTANTIATE: ",resource.can_instantiate())
 await get_tree().process_frame
 get_tree().quit()
