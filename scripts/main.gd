extends Node3D

@onready var multiplayer_manager: MultiplayerManager = get_node_or_null("MultiplayerManager")
@onready var lava: Node3D = get_node_or_null("Lava")

var spinning_block = preload("res://scenes/spinning_block.tscn")
var moving_spinning_block = preload("res://scenes/moving_spinning_block.tscn")
var moving_block = preload("res://scenes/moving_block.tscn")
var large_moving_block = preload("res://scenes/large_moving_block.tscn")
var fast_spinning_block = preload("res://scenes/fast_spinning_block.tscn")
var vertical_moving_block = preload("res://scenes/vertical_moving_block.tscn")

@export var number_of_plattforms_in_the_script = 6
@onready var plattform_spawner_manager: Node = get_node_or_null("PlattformSpawnerManager")
var plattform

@export var plattform_amount: int = 50
@export var max_x = 50
@export var max_y = 50
@export var max_z = 50
@export var min_z = 0

## Schaltet die prozeduralen Zufallsblöcke ein/aus (in Level 1 deaktiviert für handgebautes Level)
@export var enable_procedural_platforms: bool = false

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

## Lava-Hilfsfunktionen (delegieren an MultiplayerManager oder direkt an Lava)
func start_lava() -> void:
	if multiplayer_manager:
		multiplayer_manager.start_lava()
	elif lava and lava.has_method("start_rising"):
		lava.start_rising()

func stop_lava() -> void:
	if multiplayer_manager:
		multiplayer_manager.stop_lava()
	elif lava and lava.has_method("stop_rising"):
		lava.stop_rising()

func reset_lava() -> void:
	if multiplayer_manager:
		multiplayer_manager.reset_lava()
	elif lava and lava.has_method("reset_lava"):
		lava.reset_lava()
