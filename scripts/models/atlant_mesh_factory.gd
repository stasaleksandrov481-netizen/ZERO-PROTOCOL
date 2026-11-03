class_name AtlantMeshFactory
extends RefCounted
## Authored, reproducible 3D hard-surface model. Each part is baked to a few material surfaces.

var materials: Array[StandardMaterial3D] = []
var tools: Dictionary = {}
static var paint_texture: Texture2D

static func _paint() -> Texture2D:
	if paint_texture != null: return paint_texture
	var path := "res://assets/materials/at01_painted_steel.png"
	# An Android editor can see the source PNG before its import cache is ready.
	# Decode source bytes in that case; exported projects use the imported texture.
	if FileAccess.file_exists(path):
		var image := Image.new()
		if image.load_png_from_buffer(FileAccess.get_file_as_bytes(path)) == OK:
			paint_texture = ImageTexture.create_from_image(image)
	elif ResourceLoader.exists(path):
		paint_texture = load(path) as Texture2D
	return paint_texture

func _init(far_side: bool = false) -> void:
	var colors := [Color("b3b1a6"),Color("96958b"),Color("242a2c"),Color("899393"),Color("a83c3c"),Color("ffb53d"),Color("151b1d"),Color("e0e2d8")]
	for i in range(colors.size()):
		var mat := StandardMaterial3D.new()
		mat.resource_name = ["Horizon worn gray armor","Secondary gray armor","Graphite mechanisms","Piston alloy","ENTERA red stripe","Amber optics","Rubber","ENTERA marking"][i] + (" far" if far_side else "")
		mat.albedo_color = colors[i] * (Color(.72,.76,.80,1) if far_side else Color.WHITE)
		mat.roughness = .82 if i != 3 else .36
		mat.metallic = .38 if i in [0,2,3] else .08
		if i in [0,1,4]:
			mat.albedo_texture = _paint()
			mat.uv1_triplanar = true
			mat.uv1_scale = Vector3(.7,.7,.7)
		if i == 5:
			mat.emission_enabled = true
			mat.emission = Color(1,.4,.05)
			mat.emission_energy_multiplier = 1.4
		mat.cull_mode = BaseMaterial3D.CULL_DISABLED
		materials.append(mat)

func part(kind: String, length: float = 1.0) -> ArrayMesh:
	tools.clear()
	match kind:
		"core": _core()
		"upper_arm": _upper_arm(length)
		"forearm": _forearm(length)
		"thigh": _thigh(length)
		"shin": _shin(length)
		"foot": _foot()
	var mesh := ArrayMesh.new()
	mesh.resource_name = "AT-01 / " + kind
	for i in range(materials.size()):
		if tools.has(i):
			(tools[i] as SurfaceTool).commit(mesh)
			mesh.surface_set_material(mesh.get_surface_count()-1,materials[i])
	return mesh

func _add(mesh: Mesh, transform: Transform3D, index: int) -> void:
	if not tools.has(index):
		var surface := SurfaceTool.new()
		surface.begin(Mesh.PRIMITIVE_TRIANGLES)
		tools[index] = surface
	(tools[index] as SurfaceTool).append_from(mesh,0,transform)

func _box(size: Vector3, point: Vector3, material: int, bevel: float = .09, rotate: Vector3 = Vector3.ZERO) -> void:
	_add(_plate(size,bevel),Transform3D(Basis.from_euler(rotate),point),material)

func _cyl(radius: float, height: float, point: Vector3, material: int, axis: Vector3 = Vector3.UP) -> void:
	var cylinder := CylinderMesh.new()
	cylinder.top_radius = radius
	cylinder.bottom_radius = radius
	cylinder.height = height
	cylinder.radial_segments = 12
	cylinder.rings = 1
	var basis := Basis.IDENTITY
	if axis == Vector3.RIGHT: basis = Basis(Vector3.FORWARD,PI*.5)
	if axis == Vector3.FORWARD: basis = Basis(Vector3.RIGHT,PI*.5)
	_add(cylinder,Transform3D(basis,point),material)

func _plate(size: Vector3, bevel: float) -> ArrayMesh:
	var half := size*.5
	var bevel_size := minf(bevel,minf(half.x,minf(half.y,half.z))*.65)
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for axis in range(3):
		var b := (axis+1)%3
		var c := (axis+2)%3
		for sign_value: float in [-1,1]:
			var normal := Vector3.ZERO
			normal[axis] = sign_value
			var corners: Array[Vector3] = []
			for signs: Vector2 in [Vector2(-1,-1),Vector2(1,-1),Vector2(1,1),Vector2(-1,1)]:
				var p := Vector3.ZERO
				p[axis] = half[axis]*sign_value
				p[b] = signs.x*(half[b]-bevel_size)
				p[c] = signs.y*(half[c]-bevel_size)
				corners.append(p)
			_tri(surface,corners[0],corners[1],corners[2],normal)
			_tri(surface,corners[0],corners[2],corners[3],normal)
	for a in range(3):
		for b in range(a+1,3):
			var c := 3-a-b
			for sa: float in [-1,1]:
				for sb: float in [-1,1]:
					var p := Vector3.ZERO
					var q := Vector3.ZERO
					p[a] = half[a]*sa
					p[b] = (half[b]-bevel_size)*sb
					q[a] = (half[a]-bevel_size)*sa
					q[b] = half[b]*sb
					p[c] = -(half[c]-bevel_size)
					q[c] = p[c]
					var p2 := p
					var q2 := q
					p2[c] = -p[c]
					q2[c] = -q[c]
					var normal := Vector3.ZERO
					normal[a] = sa
					normal[b] = sb
					_tri(surface,p,q,q2,normal.normalized())
					_tri(surface,p,q2,p2,normal.normalized())
	for sx: float in [-1,1]:
		for sy: float in [-1,1]:
			for sz: float in [-1,1]:
				var p := (half-Vector3.ONE*bevel_size)*Vector3(sx,sy,sz)
				var a := p+Vector3(sx*bevel_size,0,0)
				var b := p+Vector3(0,sy*bevel_size,0)
				var c := p+Vector3(0,0,sz*bevel_size)
				_tri(surface,a,b,c,Vector3(sx,sy,sz).normalized())
	return surface.commit()

func _side_hatch(point: Vector3, height: float, depth: float, main_material: int = 1) -> void:
	for side: float in [-1,1]:
		var center := Vector3(side*point.x,point.y,point.z)
		_box(Vector3(.13,height,depth),center,2,.045)
		_box(Vector3(.15,height*.86,depth*.8),center+Vector3(side*.04,0,0),main_material,.04)
		_bolts(center+Vector3(side*.13,0,0),depth*.62,height*.65,Vector3.RIGHT)

func _tri(surface: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, normal: Vector3) -> void:
	for vertex: Vector3 in [a,b,c]:
		surface.set_normal(normal)
		surface.set_uv(Vector2(vertex.x+vertex.z,vertex.y)*.65)
		surface.add_vertex(vertex)

func _bolts(center: Vector3, width: float, height: float, axis: Vector3 = Vector3.FORWARD) -> void:
	for x: float in [-1,1]:
		for y: float in [-1,1]:
			var p := center + Vector3(x*width*.5,y*height*.5,0)
			if axis == Vector3.RIGHT: p = center+Vector3(0,y*height*.5,x*width*.5)
			_cyl(.055,.045,p,3,axis)

func _joint(point: Vector3, radius: float, width: float) -> void:
	_cyl(radius,width,point,2,Vector3.RIGHT)
	for sign_value: float in [-1,1]:
		var p := point+Vector3(sign_value*(width*.5+.025),0,0)
		_cyl(radius*.83,.07,p,3,Vector3.RIGHT)
		_cyl(radius*.52,.085,p,6,Vector3.RIGHT)
		_cyl(radius*.19,.1,p,4,Vector3.RIGHT)

func _emblem(point: Vector3, scale_value: float, side: float) -> void:
	# A native mesh decal follows its armor through every turn, with no billboard.
	var outer := [Vector2(-.5,.42),Vector2(.5,.42),Vector2(0,-.47)]
	var inner := [Vector2(-.34,.31),Vector2(.34,.31),Vector2(0,-.29)]
	for i in range(3):
		var j := (i+1)%3
		var surface := SurfaceTool.new()
		surface.begin(Mesh.PRIMITIVE_TRIANGLES)
		var a := point+Vector3(0,outer[i].y,outer[i].x)*scale_value
		var b := point+Vector3(0,outer[j].y,outer[j].x)*scale_value
		var c := point+Vector3(0,inner[i].y,inner[i].x)*scale_value
		var d := point+Vector3(0,inner[j].y,inner[j].x)*scale_value
		_tri(surface,a,b,c,Vector3.RIGHT*side)
		_tri(surface,c,b,d,Vector3.RIGHT*side)
		_add(surface.commit(),Transform3D.IDENTITY,7)
	var red := SurfaceTool.new()
	red.begin(Mesh.PRIMITIVE_TRIANGLES)
	_tri(red,point+Vector3(side*.006,.13,-.14)*scale_value,
		point+Vector3(side*.006,.13,.14)*scale_value,
		point+Vector3(side*.006,-.13,0)*scale_value,Vector3.RIGHT*side)
	_add(red.commit(),Transform3D.IDENTITY,4)

func _side_text(value: String, point: Vector3, side: float, text_scale: float = .0033) -> void:
	var text := TextMesh.new()
	text.text = value
	text.font = load("res://assets/fonts/DejaVuSans-Bold.ttf")
	text.font_size = 48
	text.pixel_size = text_scale
	text.depth = .002
	text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_add(text,Transform3D(Basis(Vector3.UP,side*PI*.5),point),7)

func _scuffs(point: Vector3, height: float, depth: float, side: float) -> void:
	# Small exposed edge chips supplement the source steel texture at game scale.
	for i in range(7):
		var y := point.y-height*.42+float(i)*height*.13
		var z := point.z+sin(float(i)*12.4)*depth*.39
		_box(Vector3(.012,.018+float(i%3)*.012,.045+float(i%2)*.03),Vector3(point.x,y,z),2,.003)
	for j in range(3):
		_box(Vector3(.014,.065,.025),Vector3(point.x,point.y+height*.44,point.z-depth*.25+float(j)*depth*.24),3,.003,Vector3(.3,0,0))

func _core() -> void:
	# Broad chest, exposed flexible waist, rear power pack and low wedge helmet.
	_box(Vector3(2.48,2.65,1.57),Vector3(0,.08,-.02),2,.19)
	_box(Vector3(2.2,.62,1.65),Vector3(0,-1.35,0),0,.13)
	_box(Vector3(2.74,.48,1.75),Vector3(0,1.2,.06),0,.1)
	for side: float in [-1,1]:
		_box(Vector3(1.2,1.4,.48),Vector3(side*.65,.42,.96),0,.16,Vector3(-.08,side*.10,side*.07))
		_box(Vector3(1.22,.13,.51),Vector3(side*.65,-.16,1.0),4,.02,Vector3(0,side*.10,side*.07))
		_box(Vector3(.17,1.65,1.45),Vector3(side*1.29,.28,.07),0,.075)
		_box(Vector3(.19,.13,1.38),Vector3(side*1.31,-.39,.08),4,.02)
		_joint(Vector3(side*1.40,.9,-.04),.48,.46)
		_cyl(.14,.97,Vector3(side*.79,-.86,.55),3)
		_cyl(.22,.46,Vector3(side*.79,-.56,.55),2)
		_scuffs(Vector3(side*1.39,.3,.06),1.5,1.3,side)
		_bolts(Vector3(side*1.395,.34,.07),1.12,1.16,Vector3.RIGHT)
		_side_text("AT-01",Vector3(side*1.4,.71,.08),side,.0030)
	for i in range(5):
		_box(Vector3(1.74,.11,1.34),Vector3(0,-.57-i*.15,0),2,.025)
		_box(Vector3(1.55,.035,.04),Vector3(0,-.56-i*.15,.7),3,.005)
	for side: float in [-1,1]:
		for i in range(3):
			_box(Vector3(.045,.23,.03),Vector3(side*.68+float(i)*.12,.25,1.24),5,.007,Vector3(0,0,-.28))
	_box(Vector3(2.3,2.25,.54),Vector3(0,.27,-1.01),2,.13)
	for side: float in [-1,1]:
		_box(Vector3(.69,1.85,.57),Vector3(side*.68,.43,-1.29),1,.09)
		for i in range(5):
			_box(Vector3(.59,.10,.09),Vector3(side*.68,.95-float(i)*.24,-1.6),2,.012)
	_cyl(.43,.46,Vector3(0,1.61,.08),2)
	_cyl(.27,.42,Vector3(0,1.78,.13),3)
	_box(Vector3(1.47,.77,1.54),Vector3(0,2.2,.2),0,.14)
	_box(Vector3(1.6,.38,1.72),Vector3(0,2.51,.19),0,.13,Vector3(-.13,0,0))
	_box(Vector3(1.32,.19,.18),Vector3(0,2.27,1.03),6,.025)
	_box(Vector3(1.20,.076,.19),Vector3(0,2.29,1.05),5,.008)
	_box(Vector3(1.80,.19,1.28),Vector3(0,2.26,.54),6,.025)
	_box(Vector3(1.825,.085,1.26),Vector3(0,2.28,.58),5,.012)
	_box(Vector3(.9,.42,.83),Vector3(0,1.97,.49),0,.1,Vector3(-.16,0,0))
	_box(Vector3(.55,.24,.13),Vector3(0,1.99,.95),2,.04)
	for side: float in [-1,1]:
		_cyl(.20,.17,Vector3(side*.77,2.20,-.35),2,Vector3.RIGHT)
		_cyl(.115,.19,Vector3(side*.78,2.20,-.35),3,Vector3.RIGHT)
		_box(Vector3(.13,.12,1.09),Vector3(side*.80,2.29,.45),2,.015)
		_box(Vector3(.14,.066,1.04),Vector3(side*.81,2.30,.48),5,.009)
		_box(Vector3(.13,.36,.6),Vector3(side*.72,2.08,.37),0,.05)
	_cyl(.055,1.13,Vector3(-.63,2.97,-.71),2)
	_cyl(.074,.19,Vector3(-.63,3.6,-.71),5)

func _upper_arm(length: float) -> void:
	_cyl(.33,length*.86,Vector3.ZERO,2)
	_joint(Vector3(0,length*.5,0),.43,1.10)
	_box(Vector3(1.60,1.09,1.77),Vector3(0,length*.34,.08),0,.20,Vector3(.03,0,0))
	_box(Vector3(1.45,.15,1.80),Vector3(0,length*.34-.41,.08),4,.025)
	_box(Vector3(.91,length*.66,1.08),Vector3(0,-.22,.04),2,.13)
	_box(Vector3(.70,length*.56,.18),Vector3(0,-.25,.65),1,.07)
	for side: float in [-1,1]:
		_cyl(.11,length*.69,Vector3(side*.43,-.18,-.21),3)
		_box(Vector3(.025,.78,.88),Vector3(side*.807,length*.34+.03,.1),2,.005)
		_emblem(Vector3(side*.827,length*.34+.05,.10),.69,side)
		_scuffs(Vector3(side*.81,length*.34,.08),.97,1.62,side)
		_bolts(Vector3(side*.82,length*.34,.08),1.4,.80,Vector3.RIGHT)
	_joint(Vector3(0,-length*.5,0),.34,.94)

func _forearm(length: float) -> void:
	_cyl(.28,length*.87,Vector3.ZERO,2)
	_box(Vector3(1.12,length*.87,1.26),Vector3(0,.01,.06),0,.15)
	_box(Vector3(.78,length*.63,.19),Vector3(0,.07,.77),1,.07)
	for side: float in [-1,1]:
		_cyl(.105,length*.69,Vector3(side*.42,-.03,-.48),3)
		_box(Vector3(.145,.16,1.1),Vector3(side*.59,.09,.07),4,.025)
		_box(Vector3(.14,length*.64,.92),Vector3(side*.60,-.01,.08),0,.04)
		_box(Vector3(.155,.12,.96),Vector3(side*.61,.16,.08),4,.018)
		_scuffs(Vector3(side*.68,-.01,.08),length*.6,.88,side)
		_bolts(Vector3(side*.685,-.02,.08),.7,length*.43,Vector3.RIGHT)
		_side_text("AT-01",Vector3(side*.69,-.42,.07),side,.0028)
	_cyl(.28,.36,Vector3(0,-length*.5,.03),3)
	_box(Vector3(1.06,.72,1.18),Vector3(0,-length*.5-.35,.12),2,.12)
	_box(Vector3(1.08,.26,1.2),Vector3(0,-length*.5-.17,.12),0,.07)
	for i in range(4):
		_box(Vector3(.205,.29,.30),Vector3(-.34+float(i)*.225,-length*.5-.51,.75),6,.045)
		_box(Vector3(.16,.07,.32),Vector3(-.34+float(i)*.225,-length*.5-.39,.77),3,.02)
	_box(Vector3(.27,.46,.49),Vector3(.53,-length*.5-.30,.19),2,.055)

func _thigh(length: float) -> void:
	_cyl(.32,length*.94,Vector3.ZERO,2)
	_joint(Vector3(0,length*.5,0),.43,1.0)
	_box(Vector3(.97,length*.83,1.15),Vector3(0,.02,.03),0,.13)
	_box(Vector3(.72,length*.68,.23),Vector3(0,.04,.68),1,.08)
	_box(Vector3(.74,.13,.26),Vector3(0,.30,.72),4,.02)
	for side: float in [-1,1]:
		_cyl(.13,length*.68,Vector3(side*.43,-.04,-.30),3)
		_box(Vector3(.17,length*.66,.80),Vector3(side*.55,.04,.12),0,.07)
		_box(Vector3(.18,.15,.83),Vector3(side*.56,.39,.12),4,.02)
		_bolts(Vector3(side*.65,.03,.12),.62,length*.46,Vector3.RIGHT)
		_scuffs(Vector3(side*.65,.05,.12),length*.60,.77,side)
	_joint(Vector3(0,-length*.5,0),.40,1.09)

func _shin(length: float) -> void:
	_box(Vector3(.76,length*.91,.87),Vector3(0,.02,-.08),2,.10)
	_box(Vector3(1.10,length*.84,1.31),Vector3(0,-.05,.12),0,.17)
	_box(Vector3(.77,.63,.27),Vector3(0,length*.36,.82),1,.12)
	_box(Vector3(.57,length*.63,.24),Vector3(0,-.29,.84),0,.08,Vector3(-.07,0,0))
	for side: float in [-1,1]:
		_cyl(.13,length*.75,Vector3(side*.48,-.12,-.54),3)
		_cyl(.19,length*.34,Vector3(side*.48,.18,-.54),2)
		_box(Vector3(.15,length*.63,.92),Vector3(side*.59,-.14,.13),1,.07)
		_box(Vector3(.17,.12,.89),Vector3(side*.60,-.40,.14),4,.015,Vector3(.35,0,0))
		_scuffs(Vector3(side*.67,-.13,.14),length*.60,.9,side)
		_bolts(Vector3(side*.68,-.12,.14),.7,length*.44,Vector3.RIGHT)
	_joint(Vector3(0,-length*.5,0),.30,.92)

func _foot() -> void:
	_box(Vector3(1.22,.48,1.98),Vector3(0,-.04,.36),6,.09)
	_box(Vector3(1.17,.41,1.85),Vector3(0,.23,.37),0,.11)
	_box(Vector3(.99,.29,.99),Vector3(0,.44,.72),1,.08,Vector3(-.10,0,0))
	for i in range(5):
		_box(Vector3(1.26,.11,.17),Vector3(0,-.29,-.39+float(i)*.35),2,.015)
	for i in range(4):
		_box(Vector3(.23,.28,.26),Vector3(-.43+float(i)*.285,.04,1.29),2,.04)
	for side: float in [-1,1]:
		_box(Vector3(.14,.32,1.14),Vector3(side*.65,.2,.47),0,.035)
		_bolts(Vector3(side*.73,.2,.48),.88,.15,Vector3.RIGHT)
		_scuffs(Vector3(side*.73,.2,.48),.29,1.06,side)
