extends Node3D
class_name BeanVisual

# Node references
var body_mesh_instance: MeshInstance3D
var body_material: StandardMaterial3D
var eyes_root: Node3D
var eye_nodes: Dictionary = {}

var current_color: Color = Color("ff4500")
var current_eye_style: int = 0

func _init() -> void:
	_setup_visuals()

func _ready() -> void:
	# Apply initial values
	apply_customization(current_color, current_eye_style)

func _setup_visuals() -> void:
	# Avoid duplicate setup if already instantiated
	if body_mesh_instance != null:
		return

	# 1. Body Capsule Mesh
	body_mesh_instance = MeshInstance3D.new()
	body_mesh_instance.name = "BodyMesh"
	var capsule = CapsuleMesh.new()
	capsule.radius = 0.5
	capsule.height = 2.0
	capsule.radial_segments = 32
	capsule.rings = 8
	body_mesh_instance.mesh = capsule
	body_mesh_instance.position = Vector3(0, 1.0, 0)

	body_material = StandardMaterial3D.new()
	body_material.roughness = 0.3
	body_material.metallic = 0.05
	body_material.clearcoat_enabled = true
	body_material.clearcoat = 0.25
	body_material.albedo_color = current_color
	body_mesh_instance.material_override = body_material
	add_child(body_mesh_instance)

	# 2. Eyes Root Container (centered near eye height Y=1.4, facing -Z)
	eyes_root = Node3D.new()
	eyes_root.name = "EyesRoot"
	eyes_root.position = Vector3(0, 1.4, 0)
	add_child(eyes_root)

	# Create all eye styles
	_build_style_classic()
	_build_style_derp()
	_build_style_angry()
	_build_style_happy()
	_build_style_shades()
	_build_style_cyclops()
	_build_style_shocked()
	_build_style_sleepy()
	_build_style_inferno()
	_build_style_dizzy()

func apply_customization(color: Color, eye_id: int) -> void:
	set_color(color)
	set_eye_style(eye_id)

func set_color(new_color: Color) -> void:
	current_color = new_color
	if body_material:
		body_material.albedo_color = new_color
	# Also update matching eyelids for sleepy style
	if eye_nodes.has(7):
		var sleepy_node = eye_nodes[7]
		for child in sleepy_node.get_children():
			if child.is_in_group("eyelid"):
				var mat = child.material_override as StandardMaterial3D
				if mat:
					mat.albedo_color = new_color

func set_eye_style(eye_id: int) -> void:
	current_eye_style = posmod(eye_id, eye_nodes.size())
	for id in eye_nodes:
		var node = eye_nodes[id] as Node3D
		if node:
			node.visible = (id == current_eye_style)

# --- Helper material creators ---
func _make_mat(albedo: Color, roughness: float = 0.2, emission: Color = Color.BLACK, emission_energy: float = 0.0) -> StandardMaterial3D:
	var mat = StandardMaterial3D.new()
	mat.albedo_color = albedo
	mat.roughness = roughness
	if emission != Color.BLACK and emission_energy > 0.0:
		mat.emission_enabled = true
		mat.emission = emission
		mat.emission_energy_multiplier = emission_energy
	return mat

func _make_sphere_mesh(r: float, h: float, mat: StandardMaterial3D) -> MeshInstance3D:
	var mi = MeshInstance3D.new()
	var sm = SphereMesh.new()
	sm.radius = r
	sm.height = h
	sm.radial_segments = 16
	sm.rings = 8
	mi.mesh = sm
	mi.material_override = mat
	return mi

func _make_box_mesh(size: Vector3, mat: StandardMaterial3D) -> MeshInstance3D:
	var mi = MeshInstance3D.new()
	var bm = BoxMesh.new()
	bm.size = size
	mi.mesh = bm
	mi.material_override = mat
	return mi

# --- Eye Style Builders ---

# Style 0: Classic Cute Eyes (2x large & stylized)
func _build_style_classic() -> void:
	var root = Node3D.new()
	root.name = "Style_Classic"
	eyes_root.add_child(root)
	eye_nodes[0] = root

	var sclera_mat = _make_mat(Color.WHITE, 0.25)
	var pupil_mat = _make_mat(Color("111111"), 0.1)
	var shine_mat = _make_mat(Color.WHITE, 0.05, Color.WHITE, 0.5)

	for side in [-1.0, 1.0]:
		var x = side * 0.18
		# Sclera (giant cartoon eye)
		var sclera = _make_sphere_mesh(0.15, 0.30, sclera_mat)
		sclera.scale = Vector3(1.0, 1.15, 0.45)
		sclera.position = Vector3(x, 0.0, -0.45)
		root.add_child(sclera)

		# Pupil
		var pupil = _make_sphere_mesh(0.085, 0.17, pupil_mat)
		pupil.scale = Vector3(1.0, 1.1, 0.35)
		pupil.position = Vector3(x + (side * -0.015), -0.01, -0.505)
		root.add_child(pupil)

		# Cute eye gleam / shine
		var shine1 = _make_sphere_mesh(0.035, 0.07, shine_mat)
		shine1.position = Vector3(x + (side * -0.035), 0.045, -0.525)
		root.add_child(shine1)

		var shine2 = _make_sphere_mesh(0.02, 0.04, shine_mat)
		shine2.position = Vector3(x + (side * 0.03), -0.035, -0.522)
		root.add_child(shine2)

# Style 1: Derp / Googly Eyes (2x large & goofy)
func _build_style_derp() -> void:
	var root = Node3D.new()
	root.name = "Style_Derp"
	eyes_root.add_child(root)
	eye_nodes[1] = root

	var sclera_mat = _make_mat(Color.WHITE, 0.3)
	var pupil_mat = _make_mat(Color("0d0d0d"), 0.1)

	# Left eye: Giant, pupil looking up & out
	var l_sclera = _make_sphere_mesh(0.18, 0.36, sclera_mat)
	l_sclera.scale = Vector3(1.0, 1.1, 0.45)
	l_sclera.position = Vector3(-0.19, 0.04, -0.44)
	root.add_child(l_sclera)

	var l_pupil = _make_sphere_mesh(0.08, 0.16, pupil_mat)
	l_pupil.scale = Vector3(1.0, 1.0, 0.35)
	l_pupil.position = Vector3(-0.24, 0.09, -0.505)
	root.add_child(l_pupil)

	# Right eye: Big, pupil looking down & sideways
	var r_sclera = _make_sphere_mesh(0.13, 0.26, sclera_mat)
	r_sclera.scale = Vector3(1.0, 1.0, 0.45)
	r_sclera.position = Vector3(0.18, -0.03, -0.45)
	root.add_child(r_sclera)

	var r_pupil = _make_sphere_mesh(0.065, 0.13, pupil_mat)
	r_pupil.scale = Vector3(1.0, 1.0, 0.35)
	r_pupil.position = Vector3(0.20, -0.08, -0.505)
	root.add_child(r_pupil)

# Style 2: Angry / Determined Eyes (2x large with heavy brows)
func _build_style_angry() -> void:
	var root = Node3D.new()
	root.name = "Style_Angry"
	eyes_root.add_child(root)
	eye_nodes[2] = root

	var sclera_mat = _make_mat(Color.WHITE, 0.25)
	var pupil_mat = _make_mat(Color("1a0505"), 0.1)
	var brow_mat = _make_mat(Color("1a1a1a"), 0.4)

	for side in [-1.0, 1.0]:
		var x = side * 0.18
		var sclera = _make_sphere_mesh(0.14, 0.28, sclera_mat)
		sclera.scale = Vector3(1.15, 0.85, 0.45)
		sclera.position = Vector3(x, -0.01, -0.45)
		sclera.rotation_degrees = Vector3(0, 0, side * 18.0)
		root.add_child(sclera)

		var pupil = _make_sphere_mesh(0.075, 0.15, pupil_mat)
		pupil.scale = Vector3(1.0, 1.0, 0.35)
		pupil.position = Vector3(x + (side * 0.02), -0.01, -0.505)
		root.add_child(pupil)

		# Giant Angry eyebrow
		var brow = _make_box_mesh(Vector3(0.24, 0.055, 0.05), brow_mat)
		brow.position = Vector3(x, 0.11, -0.49)
		brow.rotation_degrees = Vector3(0, 0, side * -24.0)
		root.add_child(brow)

# Style 3: Happy / Kawaii Squint Eyes (2x large with blush)
func _build_style_happy() -> void:
	var root = Node3D.new()
	root.name = "Style_Happy"
	eyes_root.add_child(root)
	eye_nodes[3] = root

	var line_mat = _make_mat(Color("111111"), 0.3)
	var blush_mat = _make_mat(Color(1.0, 0.4, 0.5, 0.8), 0.5)

	for side in [-1.0, 1.0]:
		var x = side * 0.18
		var bar1 = _make_box_mesh(Vector3(0.13, 0.045, 0.04), line_mat)
		bar1.position = Vector3(x - (side * 0.04), 0.02, -0.49)
		bar1.rotation_degrees = Vector3(0, 0, side * 30.0)
		root.add_child(bar1)

		var bar2 = _make_box_mesh(Vector3(0.13, 0.045, 0.04), line_mat)
		bar2.position = Vector3(x + (side * 0.04), 0.02, -0.49)
		bar2.rotation_degrees = Vector3(0, 0, side * -30.0)
		root.add_child(bar2)

		# Giant Rosy cheek blush
		var blush = _make_sphere_mesh(0.07, 0.04, blush_mat)
		blush.scale = Vector3(1.2, 0.5, 0.4)
		blush.position = Vector3(side * 0.27, -0.11, -0.44)
		root.add_child(blush)

# Style 4: Cool Shades / Sunglasses (2x large boss shades)
func _build_style_shades() -> void:
	var root = Node3D.new()
	root.name = "Style_Shades"
	eyes_root.add_child(root)
	eye_nodes[4] = root

	var frame_mat = _make_mat(Color("151515"), 0.15)
	frame_mat.metallic = 0.3

	# Nose bridge
	var bridge = _make_box_mesh(Vector3(0.14, 0.05, 0.05), frame_mat)
	bridge.position = Vector3(0, 0.03, -0.50)
	root.add_child(bridge)

	# Left & Right sunglass lenses
	for side in [-1.0, 1.0]:
		var x = side * 0.19
		var lens = _make_box_mesh(Vector3(0.28, 0.16, 0.05), frame_mat)
		lens.position = Vector3(x, 0.0, -0.495)
		lens.rotation_degrees = Vector3(0, side * -10.0, 0)
		root.add_child(lens)

		# White specular glint strip on sunglasses
		var glint = _make_box_mesh(Vector3(0.10, 0.02, 0.015), _make_mat(Color.WHITE, 0.05, Color.WHITE, 0.8))
		glint.position = Vector3(x - (side * 0.05), 0.045, -0.525)
		glint.rotation_degrees = Vector3(0, side * -10.0, -25.0)
		root.add_child(glint)

		# Side frame arms wrapping back
		var temple = _make_box_mesh(Vector3(0.04, 0.04, 0.32), frame_mat)
		temple.position = Vector3(side * 0.34, 0.02, -0.38)
		root.add_child(temple)

# Style 5: Cyclops Big Eye (2x giant eye - FIXED: pupil now in front of sclera!)
func _build_style_cyclops() -> void:
	var root = Node3D.new()
	root.name = "Style_Cyclops"
	eyes_root.add_child(root)
	eye_nodes[5] = root

	var sclera_mat = _make_mat(Color.WHITE, 0.25)
	var pupil_mat = _make_mat(Color("111111"), 0.1)
	var shine_mat = _make_mat(Color.WHITE, 0.05, Color.WHITE, 0.5)

	# Giant center eyeball
	var eye = _make_sphere_mesh(0.25, 0.50, sclera_mat)
	eye.scale = Vector3(1.05, 1.15, 0.35)
	eye.position = Vector3(0, 0.03, -0.44)
	root.add_child(eye)

	# Center pupil - explicitly positioned in front of sclera!
	var pupil = _make_sphere_mesh(0.13, 0.26, pupil_mat)
	pupil.scale = Vector3(1.0, 1.05, 0.30)
	pupil.position = Vector3(0, 0.02, -0.525)
	root.add_child(pupil)

	# Double glossy shines
	var shine1 = _make_sphere_mesh(0.045, 0.09, shine_mat)
	shine1.position = Vector3(-0.045, 0.075, -0.555)
	root.add_child(shine1)

	var shine2 = _make_sphere_mesh(0.025, 0.05, shine_mat)
	shine2.position = Vector3(0.04, -0.035, -0.555)
	root.add_child(shine2)

# Style 6: Shocked / Wide Open Eyes (2x large with open mouth)
func _build_style_shocked() -> void:
	var root = Node3D.new()
	root.name = "Style_Shocked"
	eyes_root.add_child(root)
	eye_nodes[6] = root

	var sclera_mat = _make_mat(Color.WHITE, 0.2)
	var pupil_mat = _make_mat(Color("111111"), 0.1)

	for side in [-1.0, 1.0]:
		var x = side * 0.19
		# Giant wide circle eyes
		var sclera = _make_sphere_mesh(0.17, 0.34, sclera_mat)
		sclera.scale = Vector3(1.05, 1.05, 0.45)
		sclera.position = Vector3(x, 0.02, -0.45)
		root.add_child(sclera)

		# Small shocked pinpoint pupil
		var pupil = _make_sphere_mesh(0.045, 0.09, pupil_mat)
		pupil.position = Vector3(x, 0.02, -0.52)
		root.add_child(pupil)

	# Shocked 'O' mouth
	var mouth = _make_sphere_mesh(0.06, 0.12, pupil_mat)
	mouth.scale = Vector3(0.8, 1.25, 0.35)
	mouth.position = Vector3(0, -0.16, -0.495)
	root.add_child(mouth)

# Style 7: Sleepy / Chill Half-lids (2x large droopy eyes)
func _build_style_sleepy() -> void:
	var root = Node3D.new()
	root.name = "Style_Sleepy"
	eyes_root.add_child(root)
	eye_nodes[7] = root

	var sclera_mat = _make_mat(Color.WHITE, 0.25)
	var pupil_mat = _make_mat(Color("151515"), 0.1)

	for side in [-1.0, 1.0]:
		var x = side * 0.18
		var sclera = _make_sphere_mesh(0.15, 0.30, sclera_mat)
		sclera.scale = Vector3(1.0, 1.0, 0.45)
		sclera.position = Vector3(x, 0.0, -0.45)
		root.add_child(sclera)

		# Lazy pupil looking down
		var pupil = _make_sphere_mesh(0.08, 0.16, pupil_mat)
		pupil.position = Vector3(x, -0.04, -0.505)
		root.add_child(pupil)

		# Drooping eyelid covering top half
		var lid_mat = _make_mat(current_color, 0.3)
		var lid = _make_box_mesh(Vector3(0.28, 0.12, 0.08), lid_mat)
		lid.position = Vector3(x, 0.055, -0.495)
		lid.add_to_group("eyelid")
		root.add_child(lid)

# Style 8: Inferno / Fiery Magma Eyes (2x large demon eyes)
func _build_style_inferno() -> void:
	var root = Node3D.new()
	root.name = "Style_Inferno"
	eyes_root.add_child(root)
	eye_nodes[8] = root

	var flame_mat = _make_mat(Color("ffd700"), 0.2, Color("ff4500"), 3.5)
	var slit_mat = _make_mat(Color("220000"), 0.1)

	for side in [-1.0, 1.0]:
		var x = side * 0.18
		var flame_eye = _make_sphere_mesh(0.16, 0.32, flame_mat)
		flame_eye.scale = Vector3(1.25, 0.85, 0.45)
		flame_eye.position = Vector3(x, 0.01, -0.45)
		flame_eye.rotation_degrees = Vector3(0, 0, side * 15.0)
		root.add_child(flame_eye)

		# Dragon/Demon slit pupil
		var slit = _make_box_mesh(Vector3(0.035, 0.18, 0.05), slit_mat)
		slit.position = Vector3(x, 0.01, -0.515)
		slit.rotation_degrees = Vector3(0, 0, side * 5.0)
		root.add_child(slit)

# Style 9: Dizzy / Knockout X Eyes (2x large cartoon crosses)
func _build_style_dizzy() -> void:
	var root = Node3D.new()
	root.name = "Style_Dizzy"
	eyes_root.add_child(root)
	eye_nodes[9] = root

	var line_mat = _make_mat(Color("111111"), 0.3)

	for side in [-1.0, 1.0]:
		var x = side * 0.18
		# Big X shaped cross
		var stroke1 = _make_box_mesh(Vector3(0.18, 0.045, 0.04), line_mat)
		stroke1.position = Vector3(x, 0.01, -0.49)
		stroke1.rotation_degrees = Vector3(0, 0, 45.0)
		root.add_child(stroke1)

		var stroke2 = _make_box_mesh(Vector3(0.18, 0.045, 0.04), line_mat)
		stroke2.position = Vector3(x, 0.01, -0.49)
		stroke2.rotation_degrees = Vector3(0, 0, -45.0)
		root.add_child(stroke2)

	# Wobbly wavy mouth
	var mouth = _make_box_mesh(Vector3(0.16, 0.04, 0.04), line_mat)
	mouth.position = Vector3(0, -0.15, -0.49)
	mouth.rotation_degrees = Vector3(0, 0, 10.0)
	root.add_child(mouth)
