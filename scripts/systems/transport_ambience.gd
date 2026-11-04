extends AudioStreamPlayer
## Original seamless rotor/wind bed, owned by the cinematic and routed through SFX.
var briefing_mix := true
static var loop_stream: AudioStreamWAV
func _ready() -> void:
 bus = "SFX";volume_db = -29
 if loop_stream == null: loop_stream = _make_loop()
 stream = loop_stream
 if briefing_mix: AudioManager.set_briefing_active(true)
 play()
func _make_loop() -> AudioStreamWAV:
 var wav := AudioStreamWAV.new();wav.format = AudioStreamWAV.FORMAT_16_BITS;wav.mix_rate = 22050
 var count := 22050*3;var data := PackedByteArray();data.resize(count*2)
 var rng := RandomNumberGenerator.new();rng.seed = 208901
 var noise := 0.0
 for i in range(count):
  var t := float(i)/22050.0
  noise = lerpf(noise,rng.randf_range(-1,1),.025)
  var rotor := sin(TAU*37*t)*(.24+.12*cos(TAU*13*t))+sin(TAU*74*t)*.07
  # Noise fades at the seam; periodic rotor frequencies complete exact cycles.
  var seam := minf(1,minf(t,3-t)*12)
  data.encode_s16(i*2,int(clampf(rotor+noise*seam,-1,1)*23000))
 wav.data = data;wav.loop_mode = AudioStreamWAV.LOOP_FORWARD;wav.loop_begin = 0;wav.loop_end = count
 return wav
func _notification(what: int) -> void:
 if what in [NOTIFICATION_APPLICATION_FOCUS_OUT,NOTIFICATION_APPLICATION_PAUSED]: stream_paused = true
 elif what in [NOTIFICATION_APPLICATION_FOCUS_IN,NOTIFICATION_APPLICATION_RESUMED]: stream_paused = false
func _exit_tree() -> void:
 stop()
 if briefing_mix: AudioManager.set_briefing_active(false)
