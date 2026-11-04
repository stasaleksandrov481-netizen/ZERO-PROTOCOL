extends RefCounted
## Shared recovery timing and instability for both combatants. Actors apply real forces.
var state := "steady"
var age := 0.0
var strain := 0.0
var severity := 0.0
var direction := 1.0
var lean := 0.0
var catch_step := 0.0
var falls := 0
var brace_time := 0.0
var rng := RandomNumberGenerator.new()
func _init() -> void: rng.randomize()
func hit(strength: float,push_direction: float,moving: float = 0.0,grounded: bool = true,bracing: bool = false) -> bool:
 strength = clampf(strength,0,1)
 if strength < .20: return false
 direction = signf(push_direction) if absf(push_direction) > .01 else 1.0
 severity = maxf(severity,strength);strain = minf(1.7,strain+strength*.72)
 if state in ["falling","down"]: return false
 if state == "rising" or brace_time > 0 or (bracing and strength < .55):
  strain = minf(strain,.95);return false
 var chance := clampf((strength-.58)*.70+maxf(0,strain-.7)*.16+moving*.07+(.13 if not grounded else 0),0,.55)
 if strain >= 1.34 or (strength >= .65 and rng.randf() < chance):
  fall(direction);return true
 if state != "stagger": state = "stagger";age = 0
 return false
func fall(push_direction: float) -> void:
 if state in ["falling","down"]: return
 direction = signf(push_direction) if absf(push_direction) > .01 else 1.0
 state = "falling";age = 0;falls += 1;severity = maxf(.65,severity)
func request_recovery() -> void:
 if state == "down" and age > .22: state = "rising";age = 0
func tick(delta: float,upright: bool = true,grounded: bool = true) -> void:
 age += delta
 brace_time = maxf(0,brace_time-delta)
 strain = move_toward(strain,0,delta*(.24 if state == "steady" else .08))
 var desired := 0.0
 catch_step = 0
 match state:
  "stagger":
   desired = direction*(.12+severity*.44)*exp(-age*1.9)
   catch_step = sin(minf(1,age/.95)*PI)*severity
   if age > 1.0+severity*.45: state = "steady";age = 0;severity = 0;strain = minf(strain,.65);brace_time = 1.0
  "falling":
   desired = direction*1.18
   if age > 1.0 and grounded: state = "down";age = 0
  "down":
   desired = direction*1.18
   if age > 1.0: state = "rising";age = 0
  "rising":
   desired = direction*1.18*(1-smoothstep(0,1,age/2.0))
   catch_step = .40*(1-clampf(age/2.5,0,1))
   if age > 2.3 and upright: state = "steady";age = 0;strain = .20;severity = 0;brace_time = 1.6
 lean = lerpf(lean,desired,1-exp(-delta*8))
func clear() -> void:
 state = "steady";age = 0;strain = 0;severity = 0;lean = 0;catch_step = 0;brace_time = 0
func is_prone() -> bool: return state in ["falling","down","rising"]
