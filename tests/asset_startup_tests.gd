extends Node
const Textures = preload("res://scripts/systems/texture_source.gd")
const ArtSkin = preload("res://scripts/models/atlant_2d_skin.gd")
const Enemy = preload("res://scripts/gameplay/klyk_2d.gd")
var passed := 0
var failed := 0
var app: Control
var hidden_candidates := 0
var visible_before_validated := false
class ErrorCollector extends Logger:
 var errors: Array[String] = []
 func _log_error(_function: String,file: String,line: int,code: String,rationale: String,_notify: bool,kind: int,_backtraces: Array[ScriptBacktrace]) -> void:
  if kind != Logger.ERROR_TYPE_WARNING: errors.append(file+":"+str(line)+" "+code+" "+rationale)
func check(value: bool,label: String) -> void:
 if value: passed += 1;print("PASS ",label)
 else: failed += 1;push_error("FAIL "+label)
func frames(n: int = 4) -> void:
 for i in range(n): await get_tree().process_frame
func _ready() -> void: call_deferred("_run")
func _node_added(node: Node) -> void:
 if node != NavigationManager.current_screen or NavigationManager.current_route not in [&"test",&"expedition"]: return
 hidden_candidates += 1
 if node.visible or node.get_node("WorldView").visible: visible_before_validated = true
func _run() -> void:
 var errors := ErrorCollector.new();OS.add_logger(errors)
 var bad := Enemy.new();bad.atlas_path = "res://tests/asset-that-does-not-exist.png";add_child(bad)
 check(not bad.initialized and not bad.enabled and bad.freeze,"missing enemy image fails before building parts")
 check(not bad.startup_error.is_empty(),"missing image has an actionable error")
 check(bad.get_child_count() == 0,"missing image never reaches get_width or creates a partial enemy")
 bad.queue_free();await frames()
 var good := Enemy.new();add_child(good)
 check(good.initialized and good.atlas != null and good.atlas.get_width() > 0,"enemy reads its original PNG")
 good.queue_free()
 check(ArtSkin.prepare() and ArtSkin.atlas.get_width() == 1774,"current seven-part atlas is loaded")
 check(ArtSkin.PATH == "res://assets/atlants/at01_oplot_atlas.png","only the current mech atlas is selected")
 var saved = load("res://scenes/atlants/at01.tscn").instantiate();add_child(saved)
 check(saved.initialized and saved.parts.size() == 12,"catalog scene builds the same current rig")
 check(saved.get_meta("skin","") == ArtSkin.SKIN_ID,"catalog scene does not contain a baked legacy robot")
 for part: Node2D in saved.parts.values():
  check(part.get_node("Visual").get_meta("skin","") == ArtSkin.SKIN_ID,"current art on "+str(part.name))
 saved.queue_free();await frames()
 for old: String in ["res://assets/atlants/at01_horizon_cutout_atlas.png","res://assets/background/atlant_menu.png","res://scripts/models/atlant_mesh_factory.gd","res://scripts/gameplay/atlant_controller.gd"]:
  check(not FileAccess.file_exists(old),"removed "+old.get_file())
 get_tree().node_added.connect(_node_added)
 app = load("res://scenes/menu/main_menu.tscn").instantiate();add_child(app);app.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);await frames(25)
 var menu := app.get_node("MenuBackground")
 check(menu.preview_actor != null and menu.preview_actor.get_meta("skin","") == ArtSkin.SKIN_ID,"menu preview uses the current in-game mech")
 check(menu.get_node_or_null("AtlantFrame/Atlant") == null,"legacy menu image node is absent")
 await NavigationManager.go(&"test");await frames()
 check(NavigationManager.current_screen.is_range_ready(),"range starts with current art")
 check(not menu.visible,"menu model is hidden while in game")
 await NavigationManager.go(&"campaign")
 Expedition.new_campaign("Тест","Импортов",[[Vector2(.1,.4),Vector2(.6,.7)]],{})
 await NavigationManager.go(&"expedition");await frames()
 check(NavigationManager.current_screen.is_range_ready(),"expedition starts with current art")
 check(hidden_candidates == 2 and not visible_before_validated,"candidate screens and top-level viewports start hidden")
 check(NavigationManager.current_screen.get_meta("startup_validated",false),"world becomes visible after startup validation")
 check(Textures.source_reads >= 5 and Textures.import_reads == 0,"raster images load from source without import-cache reads")
 await NavigationManager.go(&"home");AudioManager.shutdown();await frames(8)
 check(errors.errors.is_empty(),"zero unexpected errors including the missing-image case")
 for error: String in errors.errors: print("UNEXPECTED ",error)
 OS.remove_logger(errors)
 print("ASSET STARTUP RESULT ",passed," passed / ",failed," failed")
 get_tree().quit(1 if failed else 0)
