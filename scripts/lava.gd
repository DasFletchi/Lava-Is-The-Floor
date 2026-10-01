extends MeshInstance3D

## A small independent motion layer makes the surface feel alive even when the
## material is viewed on hardware without the optional ocean add-on.
@export var wave_height := 0.16
@export var wave_speed := 1.8

var _time := 0.0
var _start_y := 0.0

func _ready() -> void:
	_start_y = position.y

func _process(delta: float) -> void:
	_time += delta * wave_speed
	position.y = _start_y + sin(_time) * wave_height
