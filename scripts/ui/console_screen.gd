extends Control
const UI = preload("res://scripts/ui/rift_ui.gd")
const Textures = preload("res://scripts/systems/texture_source.gd")
@export var kind := "operations"
var content: HBoxContainer
var viewport: SubViewport
var preview_actor: Node2D
var preview_camera: Camera2D
var selected_part := "Head"
var selection_label: Label
var selection_info: Label
var clock := 0.0
var portrait_atlas: Texture2D
func _ready() -> void:
 theme = UI.design_theme()
 var bg := ColorRect.new();bg.color = Color("091218");bg.mouse_filter = Control.MOUSE_FILTER_IGNORE;add_child(bg);bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 var margin := MarginContainer.new();margin.name = "Margin";add_child(margin);margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 for edge in ["left","right"]: margin.add_theme_constant_override("margin_"+edge,28)
 for edge in ["top","bottom"]: margin.add_theme_constant_override("margin_"+edge,22)
 var column := UI.column(18);column.name = "Column";margin.add_child(column)
 var header := UI.row(18);header.name = "Header";column.add_child(header)
 var back := UI.icon_button("back",NavigationManager.back,"В главное меню");back.name = "Back";header.add_child(back)
 var titles := UI.column(3);header.add_child(titles)
 titles.add_child(UI.heading({"operations":"ОПЕРАЦИИ / СЕКТОР 01","hangar":"АНГАР / ГОРИЗОНТ","archive":"БОРТОВОЙ АРХИВ"}.get(kind,"ОПЛОТ"),28))
 titles.add_child(UI.micro("ENTERA / ПРОГРАММА «ОПЛОТ»"))
 header.add_child(UI.label("%d CR"%Expedition.credits,20,Color("c9bc96")))
 content = UI.row(24);content.size_flags_vertical = Control.SIZE_EXPAND_FILL;column.add_child(content)
 match kind:
  "hangar": _hangar()
  "archive": _archive()
  _: _operations()
func _picture(path: String) -> Texture2D: return Textures.png(path)
func _scroll_column(parent: Node) -> VBoxContainer:
 var scroll := ScrollContainer.new();scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED;scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL;scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL;parent.add_child(scroll)
 var box := UI.column(14);scroll.add_child(box);return box
func _operations() -> void:
 var main := _scroll_column(content)
 main.add_child(UI.section_title("ПЕРВИЧНЫЙ ДОПУСК" if Expedition.checkpoint == "dock" else "ГЛАВА I / ВЫХОДЫ ПО СЕТИ БАЗ"))
 main.add_child(UI.heading("НОЧНОЙ БЕРЕГ",36))
 var art := TextureRect.new();art.texture = _picture("res://assets/environments/night_"+str(Expedition.active_route().get("biome","sea"))+".png");art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE;art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED;art.custom_minimum_size.y = 184;main.add_child(art)
 main.add_child(UI.paragraph("Первая высадка — на морскую отмель у ДОК-17. После стыковки выберите соседнюю базу на карте. Морские, городские и мостовые маршруты проходят ночью.",19,UI.TEXT))
 var step_index := 5 if Expedition.checkpoint == "base" else (4 if Expedition.checkpoint == "arrival" else (3 if Expedition.checkpoint == "fight" else (2 if Expedition.started else 0)))
 var names := ["Оформить личное дело и подписать соглашение","Пройти инструктаж и познакомиться с Кедром","Высадиться в море и дойти до дока","Выбрать соседнюю базу на региональной карте","Пройти маршрут и занять полевой док"]
 for i in range(5):
  var row := UI.row(12);row.add_child(UI.icon("check" if step_index > i else "target",22,UI.CYAN if step_index > i else UI.MUTED));row.add_child(UI.label(names[i],17,UI.TEXT if step_index >= i else UI.MUTED));main.add_child(row)
 var side := UI.column(14);side.custom_minimum_size.x = 310;side.size_flags_horizontal = Control.SIZE_FILL;content.add_child(side)
 side.add_child(UI.section_title("КАНАЛ КОМАНДОВАНИЯ"))
 portrait_atlas = _picture("res://assets/ui/radio_personnel.png")
 if portrait_atlas != null:
  var atlas := AtlasTexture.new();atlas.atlas = portrait_atlas;var cell := Vector2(portrait_atlas.get_size())*.5;atlas.region = Rect2(Vector2(0,cell.y),cell)
  var portrait := TextureRect.new();portrait.texture = atlas;portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE;portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED;portrait.custom_minimum_size.y = 200;side.add_child(portrait)
 side.add_child(UI.heading("ЕЛЕНА ВЕТРОВА",21));side.add_child(UI.micro("КОМАНДИР СЕКТОРА"));side.add_child(UI.paragraph("«Первый, Кедр — на внешнюю отмель. После стыковки маршрут выбираете сами».",18,UI.TEXT))
 side.add_child(UI.rule());side.add_child(UI.section_title("НАГРАДА ЗА ПЕРВЫЙ ПРОХОД"));side.add_child(UI.heading("%d CR"%int(Expedition.active_route().get("reward",0)),30));side.add_child(UI.paragraph("Повторная стыковка не дублирует награду.",15))
 var gap := Control.new();gap.size_flags_vertical = Control.SIZE_EXPAND_FILL;side.add_child(gap)
 side.add_child(UI.primary("ОТКРЫТЬ КАРТУ" if not bool(Expedition.flags.get("ROUTE_ACTIVE",false)) else "ПРОДОЛЖИТЬ ОПЕРАЦИЮ",func() -> void: NavigationManager.go(&"expedition" if bool(Expedition.flags.get("ROUTE_ACTIVE",false)) else &"campaign")))
func _archive() -> void:
 var side := UI.column(14);side.custom_minimum_size.x = 260;side.size_flags_horizontal = Control.SIZE_FILL;content.add_child(side)
 side.add_child(UI.section_title("СВОДКА / 2089"));side.add_child(UI.heading("ПРОГРАММА\n«ОПЛОТ»",26))
 side.add_child(UI.paragraph("Эксперимент на объекте «Горизонт» нарушил границу реальностей. ЭНТЕРА развёртывает Атлантов для защиты путей снабжения и эвакуации.",17,UI.TEXT))
 side.add_child(UI.rule());side.add_child(UI.micro("ПОСЕЩЕНО БАЗ: %d"%Expedition.visited.size()));side.add_child(UI.micro("ЗАПИСЕЙ СВЯЗИ: %d"%Expedition.radio_log.size()))
 var log := _scroll_column(content);log.add_child(UI.heading("ЖУРНАЛ ПИЛОТА",26))
 if Expedition.flags.get("AERIAL_LANDING_DONE",false):
  var report := UI.column(7);report.add_child(UI.section_title("M01 / РЕЙС ПРИНЯТ"));report.add_child(UI.paragraph("Высадка завершена. Доступна сеть одиннадцати баз Пограничного пояса. Два следующих региона закрыты туманом навигации.",18,UI.TEXT));log.add_child(UI.panel(report,20))
 if Expedition.radio_log.is_empty():
  log.add_child(UI.spacer(60));log.add_child(UI.icon("radio",44));log.add_child(UI.heading("КАНАЛ ОЖИДАЕТ ПРИЁМА",24));log.add_child(UI.paragraph("Радиопереговоры сохраняются здесь после приёма. Инструктаж проходит после электронного соглашения.",18));log.add_child(UI.primary("ПЕРЕЙТИ К КАМПАНИИ",func() -> void: NavigationManager.go(&"campaign")))
 for entry: Dictionary in Expedition.radio_log:
  var card := UI.column(9);card.add_child(UI.section_title(entry.speaker));card.add_child(UI.paragraph(entry.text,18,UI.TEXT));log.add_child(UI.panel(card,20))
func _hangar() -> void:
 var preview_col := UI.column(10);content.add_child(preview_col)
 preview_col.add_child(UI.section_title("АТ-01 / СТАРТОВЫЙ КОРПУС"))
 var container := SubViewportContainer.new();container.stretch = true;container.size_flags_horizontal = Control.SIZE_EXPAND_FILL;container.size_flags_vertical = Control.SIZE_EXPAND_FILL;container.mouse_filter = Control.MOUSE_FILTER_IGNORE;preview_col.add_child(container)
 viewport = SubViewport.new();viewport.size = Vector2i(640,520);viewport.world_2d = World2D.new();viewport.disable_3d = true;viewport.transparent_bg = false;viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS;container.add_child(viewport)
 var world := Node2D.new();viewport.add_child(world)
 var ground := StaticBody2D.new();ground.name = "Floor";ground.position.y = 64;ground.collision_layer = 1;ground.collision_mask = 2;world.add_child(ground)
 var shape := CollisionShape2D.new();var rect := RectangleShape2D.new();rect.size = Vector2(1800,128);shape.shape = rect;ground.add_child(shape)
 var floor_art := Polygon2D.new();floor_art.polygon = PackedVector2Array([Vector2(-900,0),Vector2(900,0),Vector2(900,128),Vector2(-900,128)]);floor_art.color = Color("202e35");world.add_child(floor_art)
 var line := Line2D.new();line.points = PackedVector2Array([Vector2(-900,0),Vector2(900,0)]);line.default_color = Color("58737b");line.width = 2;world.add_child(line)
 preview_camera = Camera2D.new();world.add_child(preview_camera)
 preview_actor = load("res://scripts/models/at01_2d_builder.gd").new().create();world.add_child(preview_actor)
 preview_col.add_child(UI.micro("ОСМОТР УЗЛОВ / ГОЛОВА · КОРПУС · КОНЕЧНОСТИ"))
 var side := UI.column(10);side.custom_minimum_size.x = 306;side.size_flags_horizontal = Control.SIZE_FILL;content.add_child(side)
 side.add_child(UI.heading("ГОРИЗОНТ",34));side.add_child(UI.micro("ENTERA / АТ-01"));side.add_child(UI.paragraph("Базовый Атлант программы «Оплот». Два независимых привода рук, отдельная головная кабина и механические ограничители.",17,UI.TEXT))
 side.add_child(UI.rule());side.add_child(UI.heading("92 Т",28));side.add_child(UI.micro("12 ФИЗИЧЕСКИХ УЗЛОВ / 11 ШАРНИРОВ"))
 side.add_child(UI.section_title("ВЫБРАТЬ УЗЕЛ"))
 var nodes := UI.row(7);side.add_child(nodes)
 for item: Array in [["Head","ГОЛОВА"],["Core","КОРПУС"],["RightForearm","РУКА"]]:
  var button := UI.button(item[1],_select_part.bind(item[0]));button.add_theme_font_size_override("font_size",11);nodes.add_child(button)
 selection_label = UI.heading("",20);selection_info = UI.paragraph("",16);side.add_child(selection_label);side.add_child(selection_info)
 var spacer := Control.new();spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL;side.add_child(spacer)
 side.add_child(UI.primary("ИСПЫТАТЬ В ПОЛИГОНЕ",func() -> void: NavigationManager.go(&"test")))
 _select_part("Head")
func _select_part(id: String) -> void:
 if not is_instance_valid(preview_actor): return
 selected_part = id
 for key: String in preview_actor.parts:
  var visual: Node2D = preview_actor.parts[key].get_node("Visual")
  visual.modulate = Color(1.20,1.12,.90) if key == id else Color.WHITE
 var body: RigidBody2D = preview_actor.parts.get(id,preview_actor.parts["Core"])
 selection_label.text = {"Head":"ГОЛОВНАЯ КАБИНА","Core":"СИЛОВОЙ КОРПУС","RightForearm":"ПРАВОЕ ПРЕДПЛЕЧЬЕ"}.get(id,id)
 selection_info.text = "Масса узла: %.1f т"%body.mass
 if body.get("limit_parent") != null: selection_info.text += "\nХод шарнира: %d° … %d°"%[roundi(rad_to_deg(body.get("limit_lower"))),roundi(rad_to_deg(body.get("limit_upper")))]
func _process(delta: float) -> void:
 if not is_instance_valid(preview_actor): return
 clock += delta
 var zoom := clampf(float(viewport.size.y)/850.0,.30,.78);preview_camera.zoom = Vector2.ONE*zoom;preview_camera.position = Vector2(18,-float(viewport.size.y)*.35/zoom)
 if clock > 2.8 and preview_actor.enabled: preview_actor.set_enabled(false)
func focus_initial() -> void: $Margin/Column/Header/Back.grab_focus()
