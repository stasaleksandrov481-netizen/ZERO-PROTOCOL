extends Node
const Builder = preload("res://scripts/models/at01_2d_builder.gd")
var world: Node2D
var passed := 0
var failed := 0
func _ready() -> void: call_deferred("_run")
func ticks(n: int) -> void:
 for i in range(n): await get_tree().physics_frame
func fist(actor: Node2D) -> Vector2:
 var forearm: RigidBody2D = actor.parts.RightForearm
 return forearm.global_position+Vector2.DOWN.rotated(forearm.rotation)*actor.ARM_LOWER*.5-actor.core.global_position
func check(ok: bool,label: String) -> void:
 if ok: passed += 1;print("PASS ",label)
 else: failed += 1;print("FAIL ",label)
func _run() -> void:
 var errors = NavigationManager.RangeErrors.new();OS.add_logger(errors)
 world = Node2D.new();add_child(world)
 var floor_body := StaticBody2D.new();floor_body.collision_layer = 1;floor_body.position.y = 32;world.add_child(floor_body)
 var shape := CollisionShape2D.new();var box := RectangleShape2D.new();box.size = Vector2(20000,64);shape.shape = box;floor_body.add_child(shape)
 var actor = Builder.new().create();world.add_child(actor);await ticks(240)
 actor.hand_engaged[1] = true;actor.hand_input[1] = Vector2(-.85,.6);await ticks(180)
 var start: Vector2 = fist(actor);var samples: Array[Vector2] = []
 actor.hand_input[1] = Vector2(1,-.42)
 for i in range(240): await ticks(1);samples.append(fist(actor))
 var finish: Vector2 = samples[-1];var reach := finish-start;var t80 := -1.0
 for i in range(samples.size()):
  if (samples[i]-start).dot(reach)/reach.length_squared() >= .80: t80 = (i+1)/120.0;break
 var early := samples[9].distance_to(start)
 actor.reset_stance();await ticks(240);var x: float = actor.core.position.x;var gait: float = actor.gait;var span := 0.0
 actor.walk_axis = 1
 for i in range(600):
  await ticks(1);span = maxf(span,absf(actor.parts.RightFoot.position.x-actor.core.position.x))
 var walk_distance: float = actor.core.position.x-x;var walk_phase: float = actor.gait-gait
 actor.reset_stance();await ticks(240);x = actor.core.position.x;gait = actor.gait
 actor.walk_axis = 1;actor.run_requested = true;await ticks(600)
 print("PACING_METRICS ",JSON.stringify({"t80":t80,"early_83ms":early,"reach":reach,"walk_5s":walk_distance,"run_5s":actor.core.position.x-x,"walk_gait":walk_phase,"run_gait":actor.gait-gait,"foot_span":span}))
 check(t80 > .5 and t80 <= 1.35,"actual fist reaches its attack trajectory promptly while retaining a heavy windup")
 check(early < reach.length()*.05,"the physical hand accelerates instead of snapping on input")
 check(span > 102 and walk_distance > 650,"walking produces a visibly longer physical foot stride and advance")
 actor.queue_free();await ticks(3);AudioManager.shutdown()
 check(errors.snapshot().is_empty(),"zero unexpected script or engine errors")
 for item: Dictionary in errors.snapshot(): print("UNEXPECTED ",item)
 OS.remove_logger(errors);print("ACTUATOR PACING RESULT ",passed," passed / ",failed," failed");get_tree().quit(1 if failed else 0)
