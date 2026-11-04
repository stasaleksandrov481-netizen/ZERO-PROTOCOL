extends Node
## The new flow is checked as a running UI, including branch text and actual layouts.
const Story = preload("res://scripts/story/prologue_script.gd")
var passed := 0
var failed := 0
var app: Control
class ErrorCollector extends Logger:
 var errors: Array[String] = []
 func _log_error(_function: String,file: String,line: int,code: String,rationale: String,_notify: bool,kind: int,_backtraces: Array[ScriptBacktrace]) -> void:
  if kind != Logger.ERROR_TYPE_WARNING: errors.append(file+":"+str(line)+" "+code+" "+rationale)
func check(value: bool,label: String) -> void:
 if value: passed += 1;print("PASS ",label)
 else: failed += 1;push_error("FAIL "+label)
func frames(n: int = 5) -> void:
 for i in range(n): await get_tree().process_frame
func _ready() -> void: call_deferred("_run")
func enter_briefing() -> Control:
 await NavigationManager.go(&"enlistment");await frames()
 var flow = NavigationManager.current_screen
 flow.form_first.text = "Стас";flow.form_family.text = "Александров";flow._identity_next();await frames()
 flow.signature_pad._start(Vector2(30,45));flow.signature_pad._append(Vector2(175,65));flow.signature_pad.drawing = false
 flow._sign_next();await frames(8);return flow
func key(view: Control,code: Key) -> void:
 var event := InputEventKey.new();event.pressed = true;event.keycode = code;view._input(event)
func layout_ok(view: Control) -> bool:
 var result := true
 for node: Control in [view.back_button,view.scene_title,view.panel,view.face,view.speaker,view.body,view.reply_caption,view.continue_button,view.summary]:
  if not node.visible: continue
  var rect := node.get_global_rect()
  if not view.get_global_rect().grow(1).encloses(rect): result = false;print("OUTSIDE ",node," ",rect," screen ",view.get_global_rect())
 if view.phase != "summary":
  var font: Font = view.body.get_theme_font("font")
  var text_height: float = font.get_height(view.body.get_theme_font_size("font_size"))*view.body.get_line_count()
  if view.body.position.y+text_height > view.reply_caption.position.y-1:
   result = false;print("TEXT OVERLAP ",view.body.text," ",text_height)
  if view.face.get_rect().intersects(view.speaker.get_rect()): result = false
  if view.body.get_rect().position.y <= view.speaker.get_rect().end.y: result = false
 if view.phase == "question":
  for button: Control in view.answer_buttons:
   if not view.panel.get_global_rect().encloses(button.get_global_rect()): result = false
  if view.answer_buttons[0].get_rect().intersects(view.answer_buttons[1].get_rect()): result = false
 return result
func _run() -> void:
 var errors := ErrorCollector.new();OS.add_logger(errors)
 app = load("res://scenes/menu/main_menu.tscn").instantiate();add_child(app);app.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);await frames(25)
 Expedition.new_campaign("Архивный","Пилот",[[Vector2(.1,.3),Vector2(.5,.6)]],{})
 var saved := Expedition.snapshot()
 var flow = await enter_briefing()
 check(flow.step == 2 and flow.briefing_phase == "question","signature opens cinematic question")
 check(Expedition.snapshot() == saved,"cinematic does not replace existing save")
 check(AudioManager.briefing_active and not AudioManager.test_active,"convoy mix is active outside gameplay")
 check(flow.cinematic.get_node("ConvoyAmbience").playing,"original rotor bed is playing through SFX")
 flow._advance_briefing();check(flow.dialogue_index == 0 and flow.briefing_phase == "question","continue cannot bypass a choice")
 flow._answer(-1);flow._answer(7);check(flow.choices.is_empty(),"invalid answer indices ignored")
 key(flow.cinematic,KEY_2);await frames()
 check(flow.briefing_phase == "reply" and flow.dialogue_text.text == Story.SCENES[0].replies[1],"keyboard choice shows its immediate reply")
 flow._answer(0);check(flow.choices["0"] == 1,"double activation cannot replace an in-flight answer")
 key(flow.cinematic,KEY_SPACE);await frames()
 check(flow.dialogue_text.visible_characters == -1 and flow.dialogue_index == 0,"space reveals without skipping reply")
 flow._back();check(flow.briefing_phase == "question" and flow.dialogue_index == 0,"back allows reselecting current answer")
 flow._answer(0);check(flow.dialogue_text.text == Story.SCENES[0].replies[0],"alternative branch has its own response")
 flow._advance_briefing();check(flow.dialogue_index == 1 and flow.briefing_phase == "question","next scene follows the response")
 flow.cinematic._toggle_instant();await frames(12)
 check(flow.dialogue_text.visible_characters == -1,"instant text survives subsequent process frames")
 flow.cinematic._toggle_instant()
 SettingsManager.set_value(&"video/reduced_motion",true);flow._refresh_briefing();await frames()
 var still_time: float = flow.cinematic.backdrop.clock
 await frames(12)
 check(flow.dialogue_text.visible_characters == -1 and flow.cinematic.backdrop.clock == still_time,"reduced motion stops drift and reveals full text")
 AudioManager._notification(NOTIFICATION_APPLICATION_FOCUS_OUT);flow.cinematic.get_node("ConvoyAmbience")._notification(NOTIFICATION_APPLICATION_FOCUS_OUT)
 check(flow.cinematic.get_node("ConvoyAmbience").stream_paused,"focus loss pauses rotor audio")
 AudioManager._notification(NOTIFICATION_APPLICATION_FOCUS_IN);flow.cinematic.get_node("ConvoyAmbience")._notification(NOTIFICATION_APPLICATION_FOCUS_IN)
 check(AudioManager.briefing_active and AudioManager.music.volume_db == -7,"focus return preserves cinematic audio mix")
 SettingsManager.set_value(&"video/reduced_motion",false)
 # Real window resizing also exercises SafeRoot and the user's UI scale.
 for layout: Array in [[1280,720,1.0],[1024,459,1.0],[800,450,1.25],[1600,900,1.25]]:
  get_window().content_scale_size = Vector2i(layout[0],layout[1]);get_window().size = Vector2i(layout[0],layout[1]);SettingsManager.set_value(&"ui/scale",layout[2]);await frames(12)
  var all_fit := true
  for i in range(5):
   flow.dialogue_index = i;flow.briefing_phase = "question";flow._refresh_briefing();flow.cinematic.reveal_text();await frames()
   all_fit = layout_ok(flow.cinematic) and all_fit
   flow._answer(1);flow.cinematic.reveal_text();await frames();all_fit = layout_ok(flow.cinematic) and all_fit
  flow.briefing_phase = "summary";flow._refresh_briefing();await frames();all_fit = layout_ok(flow.cinematic) and all_fit
  check(all_fit,"all scenes / replies / summary fit %dx%d scale %.2f"%layout)
 check(Expedition.snapshot() == saved,"all browsing and backtracking keep old campaign untouched")
 flow._advance_briefing();await frames(30)
 check(NavigationManager.current_route == &"expedition","readiness launches sea expedition")
 check(not AudioManager.briefing_active and AudioManager.expedition_active,"cinematic audio hands over to gameplay")
 check(Expedition.radio_log.size() >= 5,"field journal retains the five prologue records")
 check(Expedition.radio_log[0].text.contains("Первый:") and Expedition.radio_log[0].text.contains(Story.SCENES[0].answers[1]),"journal retains actual selected response")
 Expedition.load_progress();check(Expedition.radio_log[4].id == "prologue_4","prologue records survive disk reload")
 var game = NavigationManager.current_screen
 check(is_instance_valid(game.field_guide) and not game.field_guide.visible,"first controls guide waits for landing")
 check(is_instance_valid(game.landing_audio) and game.landing_audio.playing,"convoy audio continues over the sea drop")
 game._set_paused(true,false);var drop_time: float = game.landing_time;await get_tree().create_timer(.2).timeout
 check(game.landing_audio.stream_paused and game.landing_time == drop_time,"pause freezes landing and its rotor sound")
 game._set_paused(false)
 await get_tree().create_timer(5.4).timeout
 check(not game.landing and game.field_guide.visible,"guide appears when player control returns")
 check(not is_instance_valid(game.landing_audio),"rotor player is released once the transports depart")
 var guide = game.field_guide
 game._set_paused(true,false)
 for i in range(2): game.robot.hand_engaged[i] = true;game.robot.hand_input[i] = Vector2(.7,.2);guide.observe(game.robot,.1)
 check(guide.phase == 1 and guide.hands[0] and guide.hands[1],"guide tracks both actual hand inputs")
 game.robot.core.position.x += 120;guide.observe(game.robot,.1)
 check(guide.complete and Expedition.flags.get("FIELD_GUIDE_DONE",false),"first steps finish guide and persist completion")
 guide.dismiss();check(not guide.visible,"optional guide can be dismissed")
 game.get_node("HUD").show_history(Expedition.radio_log);await frames()
 game.get_node("HUD")._filter_history(Expedition.radio_log,"prologue");await frames()
 check(game.get_node("HUD").history_records.get_child_count() == 5,"journal filter isolates the five prologue records")
 game.get_node("HUD")._filter_history(Expedition.radio_log,"field");await frames()
 check(game.get_node("HUD").history_records.get_child_count() >= 1,"journal filter shows field transmissions")
 game.get_node("HUD").close_overlay()
 game._set_paused(false)
 await NavigationManager.go(&"campaign");var after_play := Expedition.snapshot()
 flow = await enter_briefing();flow._skip_briefing();await frames()
 check(flow.briefing_phase == "summary" and flow.choices.is_empty(),"skip opens readiness without inventing choices")
 check(Expedition.snapshot() == after_play,"skip still waits before replacing save")
 flow._advance_briefing();await frames(30)
 check(Expedition.flags.INTRO_SKIPPED and Expedition.radio_log.size() >= 5,"skipped briefing still saves essential facts")
 check(not Expedition.radio_log[0].text.contains("Первый:"),"journal does not fabricate an unselected answer")
 await NavigationManager.go(&"home");await frames(8)
 check(not AudioManager.briefing_active and AudioManager.music.volume_db == 0,"menu sound mix restored after cinematic")
 SettingsManager.set_value(&"ui/scale",1.0);AudioManager.shutdown();await frames()
 check(errors.errors.is_empty(),"zero unexpected runtime errors")
 for error: String in errors.errors: print("UNEXPECTED ",error)
 OS.remove_logger(errors);print("PROLOGUE RESULT ",passed," passed / ",failed," failed");get_tree().quit(1 if failed else 0)
