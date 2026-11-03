extends Node3D
class_name LavaFloor

## Die Geschwindigkeit, mit der die Lava nach oben steigt (in Metern pro Sekunde).
@export var rise_speed: float = 0.35

## Ob die Lava aktuell steigt oder pausiert ist.
@export var is_rising: bool = false

## Maximale Höhe, bis zu der die Lava steigen soll.
@export var max_height: float = 120.0

## Start-Y-Höhe zum Zurücksetzen
@export var start_height: float = -3.5

## Verzögerung in Sekunden, bevor die Lava anfängt zu steigen (Spawn-Schutz).
@export var start_delay: float = 5.0
var delay_timer: float = 0.0
var initial_rise_speed: float = 0.35

@onready var kill_area: Area3D = $KillArea

func _ready() -> void:
	initial_rise_speed = rise_speed
	reset_lava()
	if kill_area:
		kill_area.body_entered.connect(_on_kill_area_body_entered)

func _physics_process(delta: float) -> void:
	if not is_rising:
		return

	if delay_timer > 0.0:
		delay_timer -= delta
		return
	
	if global_position.y < max_height:
		global_position.y += rise_speed * delta
	rise_speed += 0.0002

func _on_kill_area_body_entered(body: Node3D) -> void:
	# Nur die lokale Instanz (Authority) soll ihren eigenen Tod triggern,
	# damit das Event nicht auf mehreren Rechnern parallel doppelt ausgelöst wird.
	if body.has_method("is_multiplayer_authority") and not body.is_multiplayer_authority():
		return
	if body.has_method("die"):
		body.die()

func start_rising(reset_delay: bool = true) -> void:
	if reset_delay or delay_timer <= 0.0:
		delay_timer = start_delay
	is_rising = true

func stop_rising() -> void:
	is_rising = false

func reset_lava() -> void:
	global_position.y = start_height
	delay_timer = start_delay
	rise_speed = initial_rise_speed
	is_rising = false
