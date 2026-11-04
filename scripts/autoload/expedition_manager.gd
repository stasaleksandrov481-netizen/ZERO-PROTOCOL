extends Node
## Region-I route graph and atomic, backwards-compatible campaign state.
signal changed
const PATH := "user://campaign.cfg"
const BACKUP := "user://campaign.backup.cfg"
const PENDING := "user://campaign.pending.cfg"
const NODES := {
 "A01":{"name":"ДОК-17","type":"КОРПОРАТИВНЫЙ ДОК","services":"Ремонт · связь · береговой док","map":Vector2(.10,.51)},
 "A02":{"name":"МАЯК","type":"МОРСКОЙ ФОРПОСТ","services":"Ремонт · охладитель · снабжение","map":Vector2(.29,.27)},
 "A03":{"name":"РУБЕЖ-4","type":"ГОРОДСКОЙ ГАРНИЗОН","services":"Ремонт · городские патрули","map":Vector2(.29,.75)},
 "A04":{"name":"ВЕРЕСК","type":"НЕЗАВИСИМЫЙ ДОК","services":"Торговля · ремонт · гражданские грузы","map":Vector2(.48,.51)},
 "A05":{"name":"ПРИСТАНЬ-6","type":"ЭВАКУАЦИОННЫЙ УЗЕЛ","services":"Медицина · эвакуация · причал","map":Vector2(.48,.08)},
 "A06":{"name":"КАСКАД","type":"ЭНЕРГОУЗЕЛ","services":"Энергоснабжение · ремонт","map":Vector2(.48,.94)},
 "A07":{"name":"СТВОР","type":"МОСТОВОЙ ПОСТ","services":"Мост · снабжение · охрана","map":Vector2(.67,.27)},
 "A08":{"name":"СФЕРА","type":"ИССЛЕДОВАТЕЛЬСКИЙ ДОК","services":"Диагностика · береговая станция","map":Vector2(.67,.75)},
 "A09":{"name":"БАСТИОН","type":"ГОРОДСКОЙ ДОК","services":"Ремонт · оборонный периметр","map":Vector2(.86,.08)},
 "A10":{"name":"ОТЛИВ","type":"ПОЛЕВОЙ ПРИЧАЛ","services":"Снабжение · дозор","map":Vector2(.86,.51)},
 "A11":{"name":"ВРАТА-Н","type":"КОНЕЧНЫЙ ПОСТ I РЕГИОНА","services":"Ремонт · граница закрытой сети","map":Vector2(.86,.94)}
}
const MAP_LINKS := [["A01","A02","R01"],["A01","A03","R02"],["A02","A04","R03"],["A02","A05","R04"],["A03","A04","R05"],["A03","A06","R06"],["A04","A07","R07"],["A04","A08","R08"],["A05","A07","R09"],["A06","A08","R10"],["A07","A09","R11"],["A07","A10","R12"],["A08","A10","R13"],["A08","A11","R14"],["A09","A10","R15"],["A10","A11","R16"],["A02","A03","R17"]]
const ROUTE := {"id":"R01","from":"A01","to":"A02","name":"Морской подход","reward":650}
const CHECKPOINTS := ["dock","road","barrier","fight","arrival","mayak","base","landing"]
var pilot_name := "Первый"
var started := false
var completed := false
var current_base := "A01"
var checkpoint := "dock"
var credits := 1200
var alloy := 0
var coolants := 0
var visited: Array[String] = ["A01"]
var flags: Dictionary = {}
var radio_log: Array[Dictionary] = []
var last_error := ""
var notice := ""
var map_zoom := 1.0
var map_pan := Vector2.ZERO
var companion_order := "Прикрывай"
var _saved_signature := ""
var write_count := 0
func _ready() -> void: load_progress()
func snapshot() -> Dictionary:
 return {"schema":1,"started":started,"completed":completed,"pilot":pilot_name,"base":current_base,"checkpoint":checkpoint,"credits":credits,"alloy":alloy,"coolants":coolants,"flags":flags.duplicate(true),"visited":visited.duplicate(),"radio":radio_log.duplicate(true),"order":companion_order,"zoom":map_zoom,"pan":map_pan}
func _signature() -> String: return var_to_str(snapshot()).sha256_text()
func _valid(cfg: ConfigFile) -> bool:
 if int(cfg.get_value("campaign","schema",0)) != 1: return false
 if str(cfg.get_value("campaign","base","")) not in NODES or str(cfg.get_value("campaign","checkpoint","")) not in CHECKPOINTS: return false
 for key: String in ["started","completed"]:
  if not cfg.get_value("campaign",key,null) is bool: return false
 for key: String in ["credits","alloy","coolants"]:
  var value: Variant = cfg.get_value("campaign",key,0)
  if not value is int or value < 0: return false
 if not cfg.get_value("campaign","flags",{}) is Dictionary or not cfg.get_value("campaign","visited",[]) is Array or not cfg.get_value("campaign","radio",[]) is Array: return false
 var zoom: Variant = cfg.get_value("map","zoom",1.0);var pan: Variant = cfg.get_value("map","pan",Vector2.ZERO)
 if not (zoom is float or zoom is int) or not is_finite(float(zoom)) or not pan is Vector2 or not pan.is_finite(): return false
 var saved_flags: Dictionary = cfg.get_value("campaign","flags",{})
 if saved_flags.get("ROUTE_ACTIVE",false):
  var trip: Variant = saved_flags.get("ACTIVE_ROUTE",null)
  if not trip is Dictionary: return false
  if str(trip.get("from","")) != str(cfg.get_value("campaign","base","")) or str(trip.get("to","")) not in NODES: return false
  if trip.get("id","") != "DROP" and route_between(str(trip.get("from","")),str(trip.get("to",""))).is_empty(): return false
 return true
func _apply(data: Dictionary) -> void:
 started = bool(data.started);completed = bool(data.completed);pilot_name = str(data.pilot).left(64)
 current_base = str(data.base);checkpoint = str(data.checkpoint);credits = int(data.credits);alloy = int(data.alloy);coolants = int(data.coolants);flags = data.flags.duplicate(true)
 visited.clear()
 for id: Variant in data.visited:
  if str(id) in NODES and not str(id) in visited: visited.append(str(id))
 if visited.is_empty(): visited.append("A01")
 radio_log.clear()
 for record: Variant in data.get("radio",[]):
  if record is Dictionary and record.get("text",null) is String and record.get("speaker",null) is String: radio_log.append(record.duplicate(true))
 while radio_log.size() > 80: radio_log.pop_front()
 companion_order = str(data.get("order","Прикрывай"))
 if companion_order not in ["Прикрывай","Атакуй","Ко мне"]: companion_order = "Прикрывай"
 map_zoom = clampf(float(data.get("zoom",1.0)),.8,2.0);map_pan = data.get("pan",Vector2.ZERO)
 if not map_pan is Vector2 or not map_pan.is_finite(): map_pan = Vector2.ZERO
func load_progress() -> void:
 var cfg := ConfigFile.new()
 if not FileAccess.file_exists(PATH): return
 if cfg.load(PATH) != OK or not _valid(cfg):
  cfg = ConfigFile.new()
  if cfg.load(BACKUP) != OK or not _valid(cfg): notice = "Сохранение не прочитано. Исходные файлы оставлены.";return
  notice = "Кампания восстановлена из резервной копии."
 var data := snapshot()
 for key: String in data:
  data[key] = cfg.get_value("map" if key in ["zoom","pan"] else "campaign",key,data[key])
 _apply(data)
 # Migrate both completed and in-progress 0.9 saves into the free route graph.
 var migrated := not flags.has("TRAVEL_SCHEMA")
 if migrated:
  flags["TRAVEL_SCHEMA"] = 2
  if completed or checkpoint == "mayak": completed = false;checkpoint = "base";flags["ROUTE_ACTIVE"] = false;flags["REWARD_R01"] = true
  elif started:
   flags["ACTIVE_ROUTE"] = {"id":"R01","from":"A01","to":"A02","name":"Морской подход","biome":"sea","reward":650};flags["ROUTE_ACTIVE"] = true
 _saved_signature = "" if migrated or not notice.is_empty() else _signature()
func save_progress() -> bool:
 var signature := _signature()
 if signature == _saved_signature and last_error.is_empty(): return true
 var cfg := ConfigFile.new();var values := snapshot()
 for key: String in values: cfg.set_value("map" if key in ["zoom","pan"] else "campaign",key,values[key])
 var error := cfg.save(PENDING);var check := ConfigFile.new()
 if error == OK: error = check.load(PENDING)
 if error == OK and not _valid(check): error = ERR_FILE_CORRUPT
 if error == OK:
  var previous := ConfigFile.new()
  if previous.load(PATH) == OK and _valid(previous): error = DirAccess.copy_absolute(PATH,BACKUP)
 if error == OK: error = DirAccess.rename_absolute(PENDING,PATH)
 last_error = "" if error == OK else "Не удалось сохранить: %s"%error_string(error)
 if error != OK:
  if is_instance_valid(NavigationManager): NavigationManager.toast(last_error)
  return false
 _saved_signature = signature;write_count += 1;changed.emit();return true
func begin(name_value: String = "Первый") -> bool:
 if started: return true
 return new_campaign(name_value)
func new_campaign(name_value: String = "Первый",family: String = "",signature: Array = [],choices: Dictionary = {},briefing_skipped: bool = false) -> bool:
 var previous := snapshot()
 pilot_name = (name_value.strip_edges()+" "+family.strip_edges()).strip_edges().left(64)
 if pilot_name.is_empty(): pilot_name = "Первый"
 started = true;completed = false;current_base = "A01";checkpoint = "landing";credits = 1200;alloy = 0;coolants = 0;visited.assign(["A01"]);radio_log.clear()
 flags = {"CH1_STARTED":true,"MECH_OWNED_AT01":true,"TRAVEL_SCHEMA":2,"DANIEL_MET":true,"INTRO_DONE":true,"CONTRACT_SIGNED":not signature.is_empty(),"SIGNATURE":signature.duplicate(true),"PILOT_GIVEN":name_value,"PILOT_FAMILY":family,"INTRO_CHOICES":choices.duplicate(true),"ACTIVE_ROUTE":{"id":"DROP","from":"A01","to":"A01","name":"Морская высадка","biome":"sea","reward":0},"ROUTE_ACTIVE":true}
 flags["INTRO_SKIPPED"] = briefing_skipped
 radio_log.assign(preload("res://scripts/story/prologue_script.gd").field_records(choices))
 map_zoom = 1;map_pan = Vector2.ZERO;companion_order = "Прикрывай"
 if save_progress(): return true
 _apply(previous);return false
func active_route() -> Dictionary:
 var trip: Variant = flags.get("ACTIVE_ROUTE",ROUTE)
 if not trip is Dictionary: return ROUTE.duplicate(true)
 return trip.duplicate(true)
func route_between(a: String,b: String) -> Dictionary:
 for edge: Array in MAP_LINKS:
  if (edge[0] == a and edge[1] == b) or (edge[1] == a and edge[0] == b):
   var number := int(str(edge[2]).trim_prefix("R"))
   var biome: String = ["sea","city","bridge"][(number-1)%3]
   return {"id":edge[2],"from":a,"to":b,"name":{"sea":"Морской подход","city":"Городской периметр","bridge":"Мостовой переход"}[biome],"biome":biome,"reward":650 if number == 1 else 450+number*25}
 return {}
func can_depart(destination: String) -> bool:
 return started and not bool(flags.get("ROUTE_ACTIVE",false)) and destination in NODES and not route_between(current_base,destination).is_empty()
func depart(destination: String) -> bool:
 if not can_depart(destination): return false
 var previous := snapshot();flags["ACTIVE_ROUTE"] = route_between(current_base,destination);flags["ROUTE_ACTIVE"] = true;checkpoint = "road";completed = false
 if save_progress(): return true
 _apply(previous);return false
func mark_checkpoint(value: String) -> void:
 if value not in CHECKPOINTS or checkpoint == value: return
 var previous := checkpoint;checkpoint = value
 if not save_progress(): checkpoint = previous
func arrive() -> bool:
 if not bool(flags.get("ROUTE_ACTIVE",false)): return true
 var previous := snapshot();var route := active_route();current_base = str(route.to);checkpoint = "base";completed = false
 if not current_base in visited: visited.append(current_base)
 flags["ROUTE_ACTIVE"] = false;flags["AERIAL_LANDING_DONE"] = true;flags["A02_VISITED"] = "A02" in visited
 var reward_key := "REWARD_"+str(route.id)
 if not flags.get(reward_key,false):
  credits += int(route.get("reward",0));alloy += 1 if route.id != "DROP" else 0;flags[reward_key] = true
 flags["M01_DONE"] = flags.get("M01_DONE",false) or route.id == "R01"
 if save_progress(): return true
 _apply(previous);return false
func replay_route() -> void: checkpoint = "road"
func mission_title() -> String:
 return "МОРСКАЯ ВЫСАДКА" if active_route().get("id","") == "DROP" else str(active_route().get("name","Пограничный пояс")).to_upper()
func known_nodes() -> Array[String]:
 var result: Array[String] = [];result.assign(NODES.keys());return result
func record_radio(message: Dictionary,time_value: float) -> void:
 var id := str(message.get("id",""))
 for record: Dictionary in radio_log:
  if record.get("id","") == id: return
 radio_log.append({"id":id,"speaker":str(message.get("speaker","КАНАЛ")),"text":str(message.get("full_body",message.get("body",""))),"time":maxf(0,time_value)})
 while radio_log.size() > 80: radio_log.pop_front()
