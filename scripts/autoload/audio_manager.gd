extends Node
## Original offline audio: independent Music, SFX and UI buses; bounded voice pool.

var music: AudioStreamPlayer
var ambience: AudioStreamPlayer
var voices: Array[AudioStreamPlayer] = []
var voice_index := 0
var mechanical_voices: Array[AudioStreamPlayer] = []
var mechanical_index := 0
var last_step_time := 0
var test_active := false
var expedition_active := false
var briefing_active := false
var focused := true
var step_stream: AudioStream
var servo_stream: AudioStream
var radio_stream: AudioStreamWAV
var impact_stream: AudioStreamWAV
var last_impact_time := -1000
var weight_step_stream: AudioStreamWAV
var weight_step_player: AudioStreamPlayer
const SOUND_PATHS := {
 "click": "res://assets/audio/ui_click.wav",
 "back": "res://assets/audio/ui_back.wav",
 "confirm": "res://assets/audio/ui_confirm.wav",
}
var sounds: Dictionary = {}

func _ready() -> void:
 process_mode = Node.PROCESS_MODE_PAUSABLE
 for id: String in SOUND_PATHS: sounds[id] = load(SOUND_PATHS[id])
 music = AudioStreamPlayer.new()
 music.bus = "Music"
 music.stream = load("res://assets/audio/hangar_drone.wav")
 _loop(music.stream as AudioStreamWAV)
 add_child(music)
 ambience = AudioStreamPlayer.new()
 ambience.bus = "SFX"
 ambience.stream = load("res://assets/audio/rain_air.wav")
 _loop(ambience.stream as AudioStreamWAV)
 add_child(ambience)
 for i in range(4):
  var player := AudioStreamPlayer.new()
  player.bus = "UI"
  add_child(player)
  voices.append(player)
 step_stream = load("res://assets/audio/at01_step.wav")
 servo_stream = load("res://assets/audio/at01_servo.wav")
 impact_stream = _make_impact()
 radio_stream = _make_radio()
 for i in range(3):
  var player := AudioStreamPlayer.new()
  player.bus = "SFX"
  add_child(player)
  mechanical_voices.append(player)

func set_test_active(value: bool) -> void:
 test_active = value
 expedition_active = false
 briefing_active = false
 if is_instance_valid(music): music.volume_db = 0
 if is_instance_valid(music): music.stream_paused = value or not focused
 if is_instance_valid(ambience):
  ambience.volume_db = 0
  ambience.stream_paused = value or not focused

func set_expedition_active(value: bool) -> void:
 set_test_active(value)
 expedition_active = value
 if value and is_instance_valid(ambience):
  ambience.volume_db = -8
  ambience.stream_paused = not focused

func play_mechanical(strength: float = .5, servo: bool = false) -> void:
 if not focused or not test_active: return
 var now := Time.get_ticks_msec()
 if not servo and now-last_step_time < 90: return
 last_step_time = now
 var player := mechanical_voices[mechanical_index]
 mechanical_index = (mechanical_index+1)%mechanical_voices.size()
 player.stream = servo_stream if servo else step_stream
 player.pitch_scale = 1.0
 player.volume_db = lerpf(-21,-9,clampf(strength,0,1))
 player.play()

func _loop(stream: AudioStreamWAV) -> void:
 if stream == null: return
 stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
 stream.loop_begin = 0
 stream.loop_end = int(stream.get_length() * stream.mix_rate)

func _make_impact() -> AudioStreamWAV:
 # Bounded original low impact + damped metal resonance; no new import-cache dependency.
 var stream := AudioStreamWAV.new()
 stream.format = AudioStreamWAV.FORMAT_16_BITS
 stream.mix_rate = 22050
 var samples := 13230
 var data := PackedByteArray()
 data.resize(samples*2)
 var rng := RandomNumberGenerator.new()
 rng.seed = 73401
 var filtered := 0.0
 for i in range(samples):
  var t := float(i)/float(stream.mix_rate)
  filtered = lerpf(filtered,rng.randf_range(-1,1),.24)
  var attack := minf(1,t/.004)
  var bass := sin(TAU*(48*t+.8*(1-exp(-t*30))))*exp(-t*11)
  var clang := (sin(TAU*183*t)*.22+sin(TAU*307*t)*.14+sin(TAU*523*t)*.07)*exp(-t*8)
  var hit := filtered*(exp(-t*65)*1.3+exp(-t*14)*.14)
  data.encode_s16(i*2,int(clampf((bass*.58+clang+hit)*attack,-1,1)*28000))
 stream.data = data
 return stream

func play_impact(strength: float) -> void:
 if not focused or not test_active: return
 var now := Time.get_ticks_msec()
 if now-last_impact_time < 70: return
 last_impact_time = now
 var player := mechanical_voices[mechanical_index]
 mechanical_index = (mechanical_index+1)%mechanical_voices.size()
 player.stream = impact_stream
 player.volume_db = lerpf(-21,-2,clampf(strength,0,1))
 player.pitch_scale = lerpf(1.16,.80,clampf(strength,0,1))
 player.play()

func start_menu() -> void:
 if not music.playing: music.play()
 if not ambience.playing: ambience.play()

func play_ui(id: String = "click") -> void:
 if not sounds.has(id): return
 var player := voices[voice_index]
 voice_index = (voice_index + 1) % voices.size()
 player.stream = sounds[id]
 player.play()

func shutdown() -> void:
 for player: AudioStreamPlayer in voices+mechanical_voices:
  player.stream_paused = false
  player.stop()
  player.stream = null
 for player: AudioStreamPlayer in [music, ambience, splash_player,weight_step_player]:
  if is_instance_valid(player):
   player.stream_paused = false
   player.stop()
   player.stream = null

func _exit_tree() -> void:
 shutdown()

func _notification(what: int) -> void:
 if what == NOTIFICATION_APPLICATION_FOCUS_OUT or what == NOTIFICATION_APPLICATION_PAUSED:
  focused = false
  if is_instance_valid(music): music.stream_paused = true
  if is_instance_valid(ambience): ambience.stream_paused = true
 elif what == NOTIFICATION_APPLICATION_FOCUS_IN or what == NOTIFICATION_APPLICATION_RESUMED:
  focused = true
  if expedition_active: set_expedition_active(true)
  elif briefing_active: set_briefing_active(true)
  else: set_test_active(test_active)

func _make_radio() -> AudioStreamWAV:
 var stream := AudioStreamWAV.new();stream.format = AudioStreamWAV.FORMAT_16_BITS;stream.mix_rate = 22050
 var data := PackedByteArray();data.resize(2646*2)
 var rng := RandomNumberGenerator.new();rng.seed = 14180
 var filtered := 0.0
 for i in range(2646):
  var t := float(i)/22050.0;filtered = lerpf(filtered,rng.randf_range(-1,1),.38)
  var envelope := minf(1,t/.004)*exp(-t*37)
  var tone := sin(TAU*1430*t)*.14+filtered*.2
  data.encode_s16(i*2,int(clampf(tone*envelope,-1,1)*26000))
 stream.data = data;return stream
func play_radio() -> void:
 if not focused or not expedition_active: return
 var player := mechanical_voices[mechanical_index];mechanical_index = (mechanical_index+1)%mechanical_voices.size()
 player.stream = radio_stream;player.pitch_scale = 1;player.volume_db = -16;player.play()

func set_briefing_active(value: bool) -> void:
 if not value and not briefing_active: return
 set_test_active(false);briefing_active = value
 if is_instance_valid(music): music.volume_db = -7 if value else 0
 if is_instance_valid(ambience): ambience.volume_db = -13 if value else 0

func play_briefing_radio() -> void:
 if not focused or not briefing_active or mechanical_voices.is_empty(): return
 var player := mechanical_voices[mechanical_index];mechanical_index = (mechanical_index+1)%mechanical_voices.size()
 player.stream = radio_stream;player.pitch_scale = .96;player.volume_db = -24;player.play()

var splash_stream: AudioStreamWAV
var splash_player: AudioStreamPlayer
func play_weight_step(strength: float,wet: bool) -> void:
 if not focused or not test_active: return
 if weight_step_stream == null:
  weight_step_stream = AudioStreamWAV.new();weight_step_stream.format = AudioStreamWAV.FORMAT_16_BITS;weight_step_stream.mix_rate = 22050
  var data := PackedByteArray();data.resize(22050*2)
  for i in range(22050):
   var t := float(i)/22050.0
   var envelope := minf(1,t/.013)*exp(-t*6)
   var sample := sin(TAU*(49*t+.25*(1-exp(-t*12))))*.54+sin(TAU*93*t)*.18*exp(-t*8)+sin(TAU*157*t)*.1*exp(-t*11)
   data.encode_s16(i*2,int(sample*envelope*24000))
  weight_step_stream.data = data;weight_step_player = AudioStreamPlayer.new();weight_step_player.bus = "SFX";weight_step_player.stream = weight_step_stream;add_child(weight_step_player)
 weight_step_player.pitch_scale = .88 if wet else 1.0;weight_step_player.volume_db = lerpf(-16,-7,clampf(strength,0,1));weight_step_player.play()
func play_splash(strength: float = .5) -> void:
 if not focused or not test_active: return
 if splash_stream == null:
  splash_stream = AudioStreamWAV.new();splash_stream.format = AudioStreamWAV.FORMAT_16_BITS;splash_stream.mix_rate = 22050
  var data := PackedByteArray();data.resize(17640*2);var rng := RandomNumberGenerator.new();rng.seed = 7521;var filtered := 0.0
  for i in range(17640):
   var t := float(i)/22050.0;filtered = lerpf(filtered,rng.randf_range(-1,1),.27)
   var envelope := minf(1,t/.025)*exp(-t*7)
   data.encode_s16(i*2,int(clampf((filtered*.65+sin(t*230)*exp(-t*15)*.18)*envelope,-1,1)*25000))
  splash_stream.data = data;splash_player = AudioStreamPlayer.new();splash_player.bus = "SFX";splash_player.stream = splash_stream;add_child(splash_player)
 splash_player.pitch_scale = lerpf(.97,.68,clampf(strength,0,1));splash_player.volume_db = lerpf(-17,-4,clampf(strength,0,1));splash_player.play()
