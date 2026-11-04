extends Node3D

func _ready() -> void:
	setup_level_collisions(self)

func setup_level_collisions(node: Node) -> void:
	if node is MeshInstance3D:
		var has_col := false
		for c in node.get_children():
			if c is StaticBody3D:
				has_col = true
				break
		if not has_col and node.mesh != null:
			node.create_trimesh_collision()
	for child in node.get_children():
		if child is CharacterBody3D or child.is_in_group("player"):
			continue
		setup_level_collisions(child)
