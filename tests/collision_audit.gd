extends Node2D
var robot: Node2D
var enemy: Node2D
func _draw() -> void:
 var colliders: Array = []
 for part: Node in robot.parts.values(): colliders.append(part.get_node("Collision"))
 for binding: Dictionary in enemy.collider_bindings: colliders.append(binding.collision)
 for node: CollisionShape2D in colliders:
  draw_set_transform_matrix(global_transform.affine_inverse()*node.global_transform)
  var points: PackedVector2Array = node.shape.points
  draw_colored_polygon(points,Color(.20,.85,.9,.14));points.append(points[0]);draw_polyline(points,Color(.45,1,.85,.8),1.2,true)
 draw_set_transform_matrix(Transform2D.IDENTITY)
