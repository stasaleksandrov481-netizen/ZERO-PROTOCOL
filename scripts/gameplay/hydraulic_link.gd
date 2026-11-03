extends Node3D
## A telescopic cylinder follows two actual moving rigid-body anchors.

@export var body_a: NodePath
@export var body_b: NodePath
@export var anchor_a := Vector3(.45,-.45,.38)
@export var anchor_b := Vector3(.45,.55,.38)
@onready var a: Node3D = get_node(body_a)
@onready var b: Node3D = get_node(body_b)

func _process(_delta: float) -> void:
	var start := a.to_global(anchor_a)
	var finish := b.to_global(anchor_b)
	var direction := finish-start
	var length := maxf(.08,direction.length())
	global_position = (start+finish)*.5
	var y_axis := direction/length
	var x_axis := Vector3.FORWARD.cross(y_axis).normalized()
	if x_axis.length_squared() < .01: x_axis = Vector3.RIGHT
	global_basis = Basis(x_axis,y_axis,x_axis.cross(y_axis).normalized())
	$Housing.scale.y = length*.6
	$Housing.position.y = -length*.2
	$Rod.scale.y = length*.6
	$Rod.position.y = length*.2
