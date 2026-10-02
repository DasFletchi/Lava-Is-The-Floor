extends Node3D

## Drehgeschwindigkeit des Deckenventilators in Radiant pro Sekunde
@export var spin_speed: float = 7.0

func _process(delta: float) -> void:
	rotate_y(spin_speed * delta)
