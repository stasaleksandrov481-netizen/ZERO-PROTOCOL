extends RefCounted
## One readable transmission at a time. Paging never loses text or advances story state.
signal message_started(message: Dictionary)
signal message_finished(id: String)
signal state_changed
const LIMIT := 12
var pending: Array[Dictionary] = []
var current: Dictionary = {}
var seen: Dictionary = {}
var elapsed := 0.0
var duration := 0.0
var paused := false
var page := 0
var pages: Array[String] = []
var serial := 0
var page_fits: Callable
func enqueue(speaker: String,text: String,priority: int = 0,id: String = "") -> bool:
 text = text.strip_edges()
 if text.is_empty(): return false
 if id.is_empty(): id = (speaker+"|"+text).sha256_text()
 if seen.has(id): return false
 priority = clampi(priority,0,3)
 if pending.size() >= LIMIT and priority == 0: return false
 seen[id] = true;serial += 1
 var message := {"id":id,"speaker":speaker,"full_body":text,"priority":priority,"sequence":serial}
 if not current.is_empty() and priority >= 2 and priority > int(current.priority):
  pending.append(current);current = {}
 pending.append(message)
 pending.sort_custom(func(a: Dictionary,b: Dictionary) -> bool: return a.priority > b.priority if a.priority != b.priority else a.sequence < b.sequence)
 if current.is_empty(): _begin_next()
 while pending.size() > LIMIT: pending.pop_back()
 state_changed.emit();return true
func _begin_next() -> void:
 if pending.is_empty(): current = {};state_changed.emit();return
 current = pending.pop_front();pages = paginate_measured(str(current.full_body),page_fits) if page_fits.is_valid() else paginate(str(current.full_body),118);page = 0;_show_page()
func _show_page() -> void:
 current.body = pages[page];current.page = page+1;current.pages = pages.size();current.queued = pending.size()
 duration = clampf(float(pages[page].split(" ",false).size())/2.8+1.8,5.5,10.0);elapsed = 0
 message_started.emit(current.duplicate(true));state_changed.emit()
func tick(delta: float) -> void:
 if paused or current.is_empty(): return
 elapsed += maxf(0,delta)
 if elapsed >= duration: advance()
func advance() -> void:
 if current.is_empty(): _begin_next();return
 if page+1 < pages.size(): page += 1;_show_page();return
 var id := str(current.id);current = {};message_finished.emit(id);_begin_next()
func clear() -> void:
 current = {};pending.clear();pages.clear();elapsed = 0;state_changed.emit()
func fraction() -> float: return clampf(elapsed/maxf(duration,.01),0,1)
static func paginate(text: String,limit: int) -> Array[String]:
 var output: Array[String] = [];var line := ""
 for word: String in text.split(" ",false):
  if not line.is_empty() and line.length()+word.length()+1 > limit: output.append(line);line = ""
  line += (" " if not line.is_empty() else "")+word
 if not line.is_empty(): output.append(line)
 if output.is_empty(): output.append(text)
 return output
static func paginate_measured(text: String,fits: Callable) -> Array[String]:
 var output: Array[String] = [];var line := ""
 for word: String in text.split(" ",false):
  var candidate := line+(" " if not line.is_empty() else "")+word
  if not line.is_empty() and not bool(fits.call(candidate)): output.append(line);line = word
  else: line = candidate
 if not line.is_empty(): output.append(line)
 if output.is_empty(): output.append(text)
 return output
