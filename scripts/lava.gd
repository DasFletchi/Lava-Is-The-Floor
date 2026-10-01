extends Node3D
class_name LavaFloor

## Die Geschwindigkeit, mit der die Lava nach oben steigt (in Metern pro Sekunde).
@export var rise_speed: float = 0.35

## Ob die Lava aktuell steigt oder pausiert ist.
@export var is_rising: bool = true

## Maximale Höhe, bis zu der die Lava steigen soll.
@export var max_height: float = 65.0

## Start-Y-Höhe zum Zurücksetzen
@export var start_height: float = -2.0

@onready var kill_area: Area3D = $KillArea

func _ready() -> void:
	global_position.y = start_height
	if kill_area:
		kill_area.body_entered.connect(_on_kill_area_body_entered)

func _physics_process(delta: float) -> void:
	if not is_rising:
		return
	
	if global_position.y < max_height:
		global_position.y += rise_speed * delta

func _on_kill_area_body_entered(body: Node3D) -> void:
	# Prüft, ob der Körper der Spieler ist (oder die die()-Methode hat)
	if body.has_method("die"):
		body.die()
	elif body.is_in_group("player"):
		if body.has_method("die"):
			body.die()

func reset_lava() -> void:
	global_position.y = start_height
