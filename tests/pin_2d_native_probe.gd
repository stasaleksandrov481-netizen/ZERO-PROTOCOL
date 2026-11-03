extends SceneTree
func _initialize() -> void: call_deferred("run")
func run() -> void:
 var holder := Node2D.new();root.add_child(holder)
 var bodies: Array[RigidBody2D] = []
 for mode in range(2):
  var base := StaticBody2D.new();base.position = Vector2(mode*300,0);base.rotation = .2;holder.add_child(base)
  var body := RigidBody2D.new();body.position = Vector2(mode*300,100);body.rotation = .7;body.gravity_scale = 0;body.angular_damp = 0
  var proxy := CollisionShape2D.new();var shape := CircleShape2D.new();shape.radius = 15;proxy.shape = shape;body.add_child(proxy)
  holder.add_child(body)
  var pin := PinJoint2D.new();pin.position = Vector2(mode*300,0);pin.node_a = base.get_path();pin.node_b = body.get_path();pin.angular_limit_enabled = true;pin.angular_limit_lower = 0;pin.angular_limit_upper = .5;holder.add_child(pin)
  bodies.append(body)
 for i in range(10): await physics_frame
 print("PIN INITIAL ",bodies[0].rotation," ",bodies[1].rotation)
 bodies[0].apply_torque_impulse(5000);bodies[1].apply_torque_impulse(-5000)
 for i in range(240):await physics_frame
 print("PIN ENDS positive=",bodies[0].rotation," negative=",bodies[1].rotation)
 quit()
