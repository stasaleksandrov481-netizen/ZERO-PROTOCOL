extends MultiMeshInstance3D
## Small bounded pool: no particles spawn continuously and no nodes accumulate per impact.

const CAPACITY := 48
var positions: Array[Vector3] = []
var velocities: Array[Vector3] = []
var lives: Array[float] = []
var rng := RandomNumberGenerator.new()

func _ready() -> void:
	rng.seed = 734
	var spark_mesh := BoxMesh.new()
	spark_mesh.size = Vector3(.035,.035,.035)
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = Color(1,.65,.18)
	material.emission_enabled = true
	material.emission = Color(1,.3,.025)
	spark_mesh.material = material
	multimesh = MultiMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.mesh = spark_mesh
	multimesh.instance_count = CAPACITY
	for i in range(CAPACITY):
		positions.append(Vector3.ZERO)
		velocities.append(Vector3.ZERO)
		lives.append(0)
		multimesh.set_instance_transform(i,Transform3D(Basis().scaled(Vector3.ZERO),Vector3.ZERO))
	set_process(false)

func burst(point: Vector3, strength: float) -> void:
	if bool(SettingsManager.get_value("video/reduced_motion")): return
	var budget: int = [5,9,14][int(SettingsManager.get_value("video/quality"))]
	for i in range(CAPACITY):
		if budget <= 0: break
		if lives[i] > 0: continue
		positions[i] = point
		velocities[i] = Vector3(rng.randf_range(-3.8,3.8),rng.randf_range(1,4),rng.randf_range(-1,1))*maxf(.4,strength)
		lives[i] = rng.randf_range(.18,.43)
		budget -= 1
	set_process(true)

func _process(delta: float) -> void:
	var any_alive := false
	for i in range(CAPACITY):
		if lives[i] <= 0: continue
		lives[i] -= delta
		if lives[i] <= 0:
			multimesh.set_instance_transform(i,Transform3D(Basis().scaled(Vector3.ZERO),positions[i]))
			continue
		any_alive = true
		velocities[i].y -= delta*9.8
		positions[i] += velocities[i]*delta
		var transform := Transform3D(Basis.IDENTITY.scaled(Vector3(1,1,1)*clampf(lives[i]*5,.1,1)),positions[i])
		multimesh.set_instance_transform(i,transform)
	set_process(any_alive)
