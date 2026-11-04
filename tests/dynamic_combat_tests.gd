extends Node
const Builder = preload("res://scripts/models/at01_2d_builder.gd")
const Balance = preload("res://scripts/systems/balance_response.gd")
const Armor = preload("res://scripts/systems/impact_armor.gd")
var passed := 0
var failed := 0
var app: Control
func _ready() -> void: call_deferred("_run")
func check(ok: bool,label: String) -> void:
 if ok: passed += 1;print("PASS ",label)
 else: failed += 1;print("FAIL ",label)
func ticks(n: int) -> void:
 for i in range(n): await get_tree().physics_frame
func frames(n: int = 5) -> void:
 for i in range(n): await get_tree().process_frame
func _run() -> void:
 var errors = NavigationManager.RangeErrors.new();OS.add_logger(errors)
 var armor := Armor.new()
 while armor.health > 0 and armor.elapsed < 60:
  armor.hit(1);armor.hit(1);armor.hit(1);armor.tick(1.0/120)
 print("MAX_DAMAGE_MINIMUM_SECONDS ",armor.elapsed)
 check(armor.health == 0 and armor.elapsed >= 40 and armor.elapsed < 44,"even maximum-rate double-arm impacts need at least 40 seconds")
 var b := Balance.new();b.rng.seed = 12;b.hit(.45,1,0,true)
 check(b.state == "stagger","moderate heavy impact gives a recovery step")
 var falls := 0
 for seed_value in range(64):
  b.clear();b.rng.seed = seed_value;b.hit(.95,1,0,true)
  if b.state == "falling": falls += 1
 check(falls > 0 and falls < 64,"single heavy blows have a real chance to fall or recover")
 b.clear();b.hit(.45,1,0,true,true);check(b.state == "steady","a braced attack resists a medium interruption")
 b.clear();b.hit(.22,1)
 for i in range(8): b.tick(.16);b.hit(.22,1)
 check(b.state == "steady" and b.brace_time > 0,"repeated light contacts cannot restart stagger forever")
 var support_armor := Armor.new()
 for i in range(1000): support_armor.tick(.5);support_armor.hit(1,true)
 check(support_armor.health == 8,"companion cannot take the finishing blow")
 support_armor.hit(1);support_armor.hit(1,true);check(support_armor.health == 0,"support cannot resurrect a defeated target")
 app = load("res://scenes/menu/main_menu.tscn").instantiate();add_child(app);app.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);await frames(25)
 await NavigationManager.go(&"test");await frames()
 var game = NavigationManager.current_screen;var world = game.get_node("WorldView/World/Range")
 var hud = game.get_node("HUD")
 game.left_stick.touch_index = 30;game.right_stick.touch_index = 31
 var touch := InputEventScreenTouch.new();touch.index = 32;touch.pressed = true;touch.position = hud.run_button.get_global_rect().get_center();hud.run_button._input(touch)
 touch.pressed = false;hud.run_button._input(touch)
 check(hud.run_button.button_pressed and game.left_stick.touch_index == 30 and game.right_stick.touch_index == 31,"third-finger run toggle preserves both hand owners")
 game._release_input();check(not hud.run_button.button_pressed,"release and pause clear the run toggle")
 var actor = Builder.new().create(-2400);world.add_child(actor);await ticks(180)
 var start: float = actor.core.position.x;var gait_start: float = actor.gait
 actor.walk_axis = 1;await ticks(600);actor.walk_axis = 0
 var walk_distance: float = actor.core.position.x-start;var walk_phase: float = actor.gait-gait_start
 actor.reset_stance();await ticks(240);start = actor.core.position.x;gait_start = actor.gait
 actor.walk_axis = 1;actor.run_requested = true;await ticks(600);actor.walk_axis = 0;actor.run_requested = false
 var run_distance: float = actor.core.position.x-start;var run_phase: float = actor.gait-gait_start
 print("RUN_METRICS walk=",walk_distance," run=",run_distance," phase=",walk_phase," / ",run_phase," angle=",actor.core.rotation)
 check(run_distance > walk_distance*1.22,"run moves farther through a longer stride")
 check(run_phase <= walk_phase*1.10,"running does not turn the legs into a fast windmill")
 actor.reset_stance();await ticks(240)
 actor.hand_engaged[1] = true;actor.hand_input[1] = Vector2(1,0);await ticks(180)
 var straight: Vector2 = fist_offset(actor)
 actor.hand_input[1] = Vector2(0,-.9);await ticks(180);var upper: Vector2 = fist_offset(actor)
 actor.hand_input[1] = Vector2(0,.85);await ticks(180);var lower: Vector2 = fist_offset(actor)
 print("ARM_POSES straight=",straight," upper=",upper," lower=",lower," goal=",actor.arm_goals[1]," wrist=",actor.wrist_targets[1]," balance=",actor.balance.state)
 check(upper.y < straight.y-40 and lower.y > straight.y+25,"straight upper and downward inputs produce distinct articulated punches")
 actor.reset_stance();await ticks(240);actor.balance.rng.seed = 12;start = actor.core.position.x
 actor.receive_impact(.45,Vector2.RIGHT);await ticks(60)
 print("STAGGER_PLAYER ",actor.balance.state," angle=",actor.core.rotation," shift=",actor.core.position.x-start)
 check(actor.core.position.x > start+4,"player is physically pushed back by a strong hit")
 check(absf(actor.core.rotation) > .025 and actor.balance.catch_step > 0,"player leans and attempts a recovery step")
 actor.reset_stance();await ticks(240);actor.balance.rng.seed = 12
 actor.receive_impact(1,Vector2.RIGHT);await ticks(10);actor.receive_impact(1,Vector2.RIGHT)
 var max_angle := 0.0;var saw_down := false;var saw_rising := false
 for i in range(1000):
  await ticks(1);max_angle = maxf(max_angle,absf(wrapf(actor.core.rotation,-PI,PI)))
  saw_down = saw_down or actor.balance.state == "down";saw_rising = saw_rising or actor.balance.state == "rising"
  if i%180 == 179: print("FALL_PLAYER ",actor.balance.state," angle=",actor.core.rotation," y=",actor.core.position.y)
 check(max_angle > .8 and saw_down,"stacked heavy blows can physically topple the player")
 check(saw_rising and actor.balance.state == "steady","player gets back onto the feet without teleporting")
 actor.reset_stance();await ticks(180)
 var enemy = load("res://scripts/gameplay/klyk_2d.gd").new();enemy.position = Vector2(1700,-330);enemy.target = game.robot;world.add_child(enemy);enemy.rng.seed = 9;enemy.balance.rng.seed = 12
 var enemy_start: float = enemy.position.x;await ticks(960)
 print("AI_METRICS ",enemy.state_visits," travel=",enemy.position.x-enemy_start," rot=",enemy.rotation)
 check(enemy.position.x < enemy_start-350,"enemy actively pursues the player")
 check(enemy.state_visits.has("rush") and enemy.state_visits.has("charge_windup"),"enemy announces a charge and runs into it")
 var hand: RigidBody2D = game.robot.parts.RightForearm
 enemy.set_enabled(false);enemy.position = Vector2(hand.global_position.x+300,-330);await ticks(4);enemy.set_enabled(true);enemy.evade_cooldown = 0;enemy.behavior = "guard";enemy.threat_age = 0
 hand.linear_velocity = Vector2(190,0)
 enemy._choose_action(-450);enemy._choose_action(-450)
 check(enemy.behavior == "evade" and enemy.evade_cooldown > 3,"enemy reacts to a physically incoming hand with a limited evade")
 enemy.set_enabled(false);enemy.position = Vector2(1700,-330);enemy.balance.clear();await ticks(3);enemy.set_enabled(true);enemy.balance.rng.seed = 12
 enemy.register_hit(1,false,Vector2.RIGHT);await ticks(10);enemy.register_hit(1,false,Vector2.RIGHT)
 max_angle = 0;saw_down = false;saw_rising = false
 for i in range(1000):
  await ticks(1);max_angle = maxf(max_angle,absf(wrapf(enemy.rotation,-PI,PI)))
  saw_down = saw_down or enemy.balance.state == "down";saw_rising = saw_rising or enemy.balance.state == "rising"
  if i%180 == 179: print("FALL_ENEMY ",enemy.balance.state," angle=",enemy.rotation," y=",enemy.position.y)
 check(max_angle > .8 and saw_down,"enemy can topple under accumulated heavy blows")
 check(saw_rising and enemy.balance.state == "steady","enemy physically recovers from the fall")
 enemy.set_enabled(false);game.robot.reset_stance();game._release_input();enemy.position = Vector2(500,-330);enemy.rotation = 0;enemy.linear_velocity = Vector2.ZERO;enemy.angular_velocity = 0;enemy.balance.clear();await ticks(180)
 enemy.attack_clock = 0;enemy.attack_time = -1;enemy._set_behavior("guard");enemy.set_enabled(true)
 var received: Array[float] = []
 enemy.landed.connect(func(strength: float) -> void:
  received.append(strength);game.robot.receive_impact(strength,enemy.last_hit_direction,enemy.last_hit_point))
 await ticks(1100)
 print("IDLE_DEFENDER_CONTACTS ",received.size()," distance=",enemy.position.x-game.robot.core.position.x," AI=",enemy.behavior)
 check(not received.is_empty(),"enemy can land a real contact attack on an idle player")
 for viewport: Vector2i in [Vector2i(1280,720),Vector2i(1024,459)]:
  get_window().content_scale_size = viewport;get_window().size = viewport;await frames(12);hud.layout_hud()
  var card: Rect2 = hud._enemy_card()
  check(not card.intersects(Rect2(22,89,225,91)) and not card.intersects(hud.radio.get_rect()) and card.encloses(hud.enemy_health.get_rect()),"enemy status fits between objective and radio %s"%viewport)
 enemy.queue_free();actor.queue_free();await NavigationManager.go(&"home");AudioManager.shutdown();await frames()
 check(errors.snapshot().is_empty(),"zero unexpected script or engine errors")
 for item: Dictionary in errors.snapshot(): print("UNEXPECTED ",item)
 OS.remove_logger(errors);print("DYNAMIC COMBAT RESULT ",passed," passed / ",failed," failed");get_tree().quit(1 if failed else 0)
func fist_offset(actor: Node2D) -> Vector2:
 var forearm: RigidBody2D = actor.parts.RightForearm
 return forearm.global_position+Vector2.DOWN.rotated(forearm.rotation)*actor.ARM_LOWER*.5-actor.core.global_position
