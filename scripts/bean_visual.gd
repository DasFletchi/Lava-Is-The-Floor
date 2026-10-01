extends Node3D
class_name BeanVisual

const EYE_SCENES: Dictionary = {
	0: preload("res://scenes/eyes/style_classic.tscn"),
	1: preload("res://scenes/eyes/style_derp.tscn"),
	2: preload("res://scenes/eyes/style_angry.tscn"),
	3: preload("res://scenes/eyes/style_happy.tscn"),
	4: preload("res://scenes/eyes/style_henrik.tscn"),
	5: preload("res://scenes/eyes/style_cyclops.tscn"),
	6: preload("res://scenes/eyes/style_shocked.tscn"),
	7: preload("res://scenes/eyes/style_sleepy.tscn"),
	8: preload("res://scenes/eyes/style_inferno.tscn"),
	9: preload("res://scenes/eyes/style_dizzy.tscn"),
}

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

	# Load each eye style from its .tscn scene file
	for id in EYE_SCENES:
		var scn: PackedScene = EYE_SCENES[id]
		if scn:
			var inst = scn.instantiate()
			inst.name = "Style_%d" % id
			eyes_root.add_child(inst)
			eye_nodes[id] = inst

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
			if child.is_in_group("eyelid") or "Eyelid" in child.name:
				var mat = child.material_override as StandardMaterial3D
				if mat:
					mat.albedo_color = new_color

func set_eye_style(eye_id: int) -> void:
	current_eye_style = posmod(eye_id, eye_nodes.size())
	for id in eye_nodes:
		var node = eye_nodes[id] as Node3D
		if node:
			node.visible = (id == current_eye_style)
