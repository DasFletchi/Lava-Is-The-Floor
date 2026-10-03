extends CharacterBody3D
@export var mouse_sensitivity: float = 0.005
@export var anim_transition_time: float = 0.5
@onready var camera: Camera3D = $Camera3D
@onready var mesh_instance_3d: MeshInstance3D = $MeshInstance3D
@onready var ray_cast_3d: RayCast3D = $RayCast3D
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var temp_player: CharacterBody3D = $"."
@onready var gamertag: Label3D = $Gamertag
@onready var dead_pop_up: RichTextLabel = $DeadPopUp
@onready var won_pop_up: RichTextLabel = $WONPopUP

const ragdoll_scene = preload("res://scenes/bean_ragdoll.tscn")
const buzzer_sound = preload("res://sfx/elimination_buzzer.wav")
const victory_sound = preload("res://sfx/victory_sound.wav")

@onready var win_particles_green: GPUParticles3D = get_node_or_null("WinParticlesGreen") as GPUParticles3D
@onready var win_particles_blue: GPUParticles3D = get_node_or_null("WinParticlesBlue") as GPUParticles3D

signal player_eliminated(peer_id: int)
signal player_won(peer_id: int)

var is_dead: bool = false
var has_won: bool = false
@export var is_spectator: bool = false
@export var spectator_speed: float = 14.0

@onready var collision_shape_3d: CollisionShape3D = $CollisionShape3D
@onready var hands: Node3D = $hands
@onready var spectator_hud: CanvasLayer = get_node_or_null("SpectatorHUD") as CanvasLayer

@onready var bean_visual: BeanVisual = get_node_or_null("BeanVisual") as BeanVisual

@export var player_color: Color = Color("ff4500"):
	set(val):
		player_color = val
		_apply_visuals()

@export var eye_style: int = 0:
	set(val):
		eye_style = val
		_apply_visuals()


@export var SPEED = 5.0
const JUMP_VELOCITY = 4.8

# --- Brutal-but-fair gravity (tweak these to taste!) ---
const GRAVITY_MULT = 1.5          # base gravity multiplier: 9.8 * 1.5 ≈ 14.7 m/s²
const GRAVITY_ASCEND = 0.8        # while rising -> jump stays fair and tight
const GRAVITY_DESCEND = 1.6       # while falling -> brutal, heavy falls
const MAX_FALL_SPEED = 24.0       # terminal velocity -> always fair, you can react
const COYOTE_TIME = 0.12          # grace window after walking off an edge
const JUMP_BUFFER = 0.15          # jump pressed a bit early still counts

var coyote_timer := 0.0 #das zeit dem program das es sich hier um ne float handelt mit dem =:
var jump_buffer_timer := 0.0
var ledges_left := 1
var legding_rn = false

## Steuert, ob sich der Spieler bewegen und umsehen kann (wird bei Rundenstart aktiviert)
@export var can_move: bool = false:
	set(val):
		can_move = val
		if is_inside_tree() and is_multiplayer_authority():
			if can_move:
				Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
			else:
				Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _ready() -> void:
	add_to_group("player")
	add_to_group("alive_players")
	if spectator_hud:
		spectator_hud.hide()
	if won_pop_up:
		won_pop_up.hide()
	if dead_pop_up:
		dead_pop_up.hide()

	if is_multiplayer_authority():
		bean_visual.hide()
		if has_node("/root/PlayerCustomization"):
			var cust = get_node("/root/PlayerCustomization")
			player_color = cust.selected_color
			eye_style = cust.selected_eye_style
			if gamertag:
				gamertag.text = cust.player_name
		_apply_visuals()
	else:
		_apply_visuals()

	if not is_multiplayer_authority(): return
	if can_move:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	else:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	animation_player.animation_finished.connect(_on_animation_finished)
	animation_player.play("RESET")
	camera.make_current()



func _unhandled_input(event: InputEvent) -> void:
	if not is_multiplayer_authority(): return
	if not can_move: return

	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

	if event.is_action_pressed("quit"):
		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		else:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		get_viewport().set_input_as_handled()
		return

	if event is InputEventMouseMotion:
		if DisplayServer.get_name() != "headless" and Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
			return
		rotate_y(-event.relative.x * mouse_sensitivity)
		camera.rotate_x(-event.relative.y * mouse_sensitivity)
		camera.rotation.x = clamp(camera.rotation.x, -PI/2, PI/2)
	if not is_dead and not is_spectator:
		if Input.is_action_just_pressed("left_click") and ray_cast_3d.is_colliding():
			ledge_boost()


func _physics_process(delta: float) -> void:
	if not is_multiplayer_authority(): return

	# Vor Rundenstart: Bewegung einfrieren
	if not can_move and not is_spectator:
		if not is_on_floor():
			velocity += get_gravity() * delta
			move_and_slide()
		else:
			velocity = Vector3.ZERO
		return

	# --- Spectator Mode (Minecraft Freiflug / Noclip) ---
	if is_spectator:
		var fly_dir := Vector3.ZERO
		if Input.is_action_pressed("w"):
			fly_dir -= camera.global_transform.basis.z
		if Input.is_action_pressed("s"):
			fly_dir += camera.global_transform.basis.z
		if Input.is_action_pressed("d"):
			fly_dir += camera.global_transform.basis.x
		if Input.is_action_pressed("a"):
			fly_dir -= camera.global_transform.basis.x
		if Input.is_action_pressed("space"):
			fly_dir.y += 1.0
		if Input.is_key_pressed(KEY_SHIFT):
			fly_dir.y -= 1.0

		if fly_dir != Vector3.ZERO:
			var current_speed = spectator_speed
			if Input.is_key_pressed(KEY_CTRL):
				current_speed *= 2.0
			global_position += fly_dir.normalized() * current_speed * delta
		return

	if is_dead:
		velocity = Vector3.ZERO
		return

	# Fall-Out / Lava-Tod als Absicherung
	if global_position.y < -15.0 and not is_dead and not is_spectator:
		die()
		return

	# --- Gravity: brutal while falling, fair while rising ---
	if not is_on_floor():
		var gravity: Vector3 = get_gravity() * GRAVITY_MULT
		if velocity.y > 0.0:
			gravity *= GRAVITY_ASCEND
		else:
			gravity *= GRAVITY_DESCEND
		velocity.y += gravity.y * delta
		velocity.y = maxf(velocity.y, -MAX_FALL_SPEED)

	# --- Fairness timers: coyote time + jump buffering ---
	coyote_timer = COYOTE_TIME if is_on_floor() else maxf(coyote_timer - delta, 0.0)
	# Holding space mid-air keeps the buffer alive, so the game never eats a jump on landing.
	if Input.is_action_just_pressed("space") or (Input.is_action_pressed("space") and not is_on_floor()):
		jump_buffer_timer = JUMP_BUFFER
	else:
		jump_buffer_timer = maxf(jump_buffer_timer - delta, 0.0)

	# --- Jump: buffered + coyote -> the game never eats your jump ---
	if jump_buffer_timer > 0.0 and coyote_timer > 0.0:
		velocity.y = JUMP_VELOCITY
		jump_buffer_timer = 0.0
		coyote_timer = 0.0


	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var input_dir := Input.get_vector("a", "d", "w", "s")
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)
	move_and_slide()
	
	
	
	if is_on_floor():
		ledges_left = 1


	if legding_rn:
		animation_player.play("ledge")
	elif velocity == Vector3.ZERO:
		animation_player.play("idle")
	else:
		animation_player.play("RESET")

func ledge_boost():
	if ledges_left > 0:
		ledges_left -= 1
		velocity.y = JUMP_VELOCITY * 2
		legding_rn = true


func _on_animation_finished(anim_name: StringName) -> void:
	if anim_name == "ledge":
		legding_rn = false


func _enter_tree() -> void:
	var id = str(name).to_int()
	if id != 0:
		set_multiplayer_authority(id)

func is_alive() -> bool:
	return not is_dead and not is_spectator

func die() -> void:
	if is_dead or is_spectator: return
	is_dead = true
	if multiplayer != null and multiplayer.has_multiplayer_peer() and is_multiplayer_authority():
		die_rpc.rpc()
	else:
		_handle_death()
	dead_pop_up.show()
	await get_tree().create_timer(3.0).timeout
	dead_pop_up.hide()

@rpc("any_peer", "call_local", "reliable")
func die_rpc() -> void:
	_handle_death()

func _handle_death() -> void:
	is_dead = true
	is_spectator = true
	velocity = Vector3.ZERO

	# Spieler aus den Lebenden austragen, zu Zuschauern eintragen
	remove_from_group("alive_players")
	add_to_group("spectators")

	# Kollision deaktivieren (Noclip: Fliegen durch Wände & keine neuen Lava-Treffer)
	if collision_shape_3d:
		collision_shape_3d.set_deferred("disabled", true)

	# 1. Glühende Lava-Explosions-Partikel abfeuern
	var particles = get_node_or_null("GPUParticles3D") as GPUParticles3D
	if particles:
		particles.restart()
		particles.emitting = true

	# 2. Physikalisches Bohnen-Ragdoll spawnen
	if ragdoll_scene:
		var rag = ragdoll_scene.instantiate()
		get_parent().add_child(rag)
		rag.global_position = global_position
		rag.global_rotation = global_rotation
		rag.setup(player_color, eye_style, velocity)

	# 3. Visuelle Bohne, Gamertag und Hände ausblenden
	if bean_visual:
		bean_visual.hide()
	if gamertag:
		gamertag.hide()
	if is_multiplayer_authority():
		if hands:
			hands.hide()
		if spectator_hud:
			spectator_hud.show()

	# 4. Buzzer-Sound abspielen (The Finals Elimination Buzzer)
	var sfx = AudioStreamPlayer.new()
	sfx.stream = buzzer_sound
	sfx.volume_db = 0.0 if is_multiplayer_authority() else -6.0
	get_tree().root.add_child(sfx)
	sfx.play()
	sfx.finished.connect(sfx.queue_free)

	# 5. Eliminierungs-Signal feuern (Hook für Win-Condition / Runden-Logik)
	var peer_id = 1
	if multiplayer != null and multiplayer.has_multiplayer_peer():
		peer_id = multiplayer.get_unique_id()
	player_eliminated.emit(peer_id)

func respawn() -> void:
	is_dead = false
	is_spectator = false
	global_position = Vector3(0, 5.0, 0)
	velocity = Vector3.ZERO
	if collision_shape_3d:
		collision_shape_3d.set_deferred("disabled", false)
	if is_multiplayer_authority():
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		if hands:
			hands.show()
		if spectator_hud:
			spectator_hud.hide()
	else:
		if bean_visual:
			bean_visual.show()
	if gamertag:
		gamertag.show()
	remove_from_group("spectators")
	add_to_group("alive_players")
	var particles = get_node_or_null("GPUParticles3D") as GPUParticles3D
	if particles:
		particles.emitting = false
		can_move = false

func _apply_visuals() -> void:
	if bean_visual == null:
		bean_visual = get_node_or_null("BeanVisual") as BeanVisual
	if is_instance_valid(bean_visual):
		bean_visual.apply_customization(player_color, eye_style)

## Gewonnen! Löst Partikel, Sieg-Jingle und Popup aus
func win() -> void:
	if has_won or is_dead: return
	has_won = true
	if multiplayer != null and multiplayer.has_multiplayer_peer() and is_multiplayer_authority():
		win_rpc.rpc()
	else:
		_handle_win()

@rpc("any_peer", "call_local", "reliable")
func win_rpc() -> void:
	_handle_win()

func _handle_win() -> void:
	has_won = true

	# 1. Grüne und blaue Partikel abfeuern (Sieg-Feuerwerk)
	if win_particles_green:
		win_particles_green.restart()
		win_particles_green.emitting = true
	if win_particles_blue:
		win_particles_blue.restart()
		win_particles_blue.emitting = true

	# 2. Sieg-Sound abspielen (triumphale Fanfare)
	var sfx = AudioStreamPlayer.new()
	sfx.stream = victory_sound
	sfx.volume_db = 2.0 if is_multiplayer_authority() else -3.0
	get_tree().root.add_child(sfx)
	sfx.play()
	sfx.finished.connect(sfx.queue_free)

	# 3. WON Popup anzeigen
	if is_multiplayer_authority() and won_pop_up:
		won_pop_up.show()

	var peer_id = 1
	if multiplayer != null and multiplayer.has_multiplayer_peer():
		peer_id = multiplayer.get_unique_id()
	player_won.emit(peer_id)
