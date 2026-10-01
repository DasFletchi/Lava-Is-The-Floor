extends CharacterBody3D
@export var mouse_sensitivity: float = 0.005
@export var anim_transition_time: float = 0.5
@onready var camera: Camera3D = $Camera3D
@onready var mesh_instance_3d: MeshInstance3D = $MeshInstance3D
@onready var ray_cast_3d: RayCast3D = $RayCast3D
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var temp_player: CharacterBody3D = $"."
@onready var gamertag: Label3D = $Gamertag


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

func _ready() -> void:
	if is_multiplayer_authority():
		bean_visual.hide()
		if has_node("/root/PlayerCustomization"):
			var cust = get_node("/root/PlayerCustomization")
			player_color = cust.selected_color
			eye_style = cust.selected_eye_style
		_apply_visuals()
		if multiplayer.has_multiplayer_peer():
			sync_customization.rpc(player_color, eye_style)
			multiplayer.peer_connected.connect(_on_peer_connected)
	else:
		_apply_visuals()

	if not is_multiplayer_authority(): return
	#Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	#animation_player.playback_default_blend_time = anim_transition_time #geiles godot feature damit man nicht so snappy von animation zu animation wechselts
	animation_player.animation_finished.connect(_on_animation_finished)
	animation_player.play("RESET")
	camera.make_current()# der code wird eh nicht ausgefüll wenn wir nicht big server authority haben


	gamertag.text = PlayerCustomization.player_name


func _unhandled_input(event: InputEvent) -> void: #unhandled inputs heist eif nur, wenn niemand anders bisher sich das hier geholt hat dann hol ich es mir halt
	if not is_multiplayer_authority(): return
	if event is InputEventMouseMotion: #ohne input map auf shit zugreifen/is dieses event eine a
		rotate_y(-event.relative.x * mouse_sensitivity) #event.relative.x ist: Wie weit die Maus seit dem letzten Frame horizontal bewegt wurde.
		camera.rotate_x(-event.relative.y * mouse_sensitivity)
		#it makes sense but it doesnt i guess please just with the rotate x and y thingies its annoying fr
		#because in this cruel world rotate y means looking left/right we dont have the camera before that bc its fine if the whole player turns that fine its even wanted for nice fps movement
		#but on the next x = y  and no we dont actually want to change the y rotation of the player then we'd fly thats not so cool
		# also warum auch immer: s
		#Maus X-Bewegung → Rotation um Y-Achse
		#Maus Y-Bewegung → Rotation um X-Achse
		camera.rotation.x = clamp(camera.rotation.x, -PI/2, PI/2)
		#PI ist anschei9nend immer 180 grad einmal die untere hälfte der blase und die obere hälfte der blase wundewrbar in der mitte auf der x der realen x achse durchgeschnitten (pi lol schneiden)
	if Input.is_action_just_pressed("left_click") and ray_cast_3d.is_colliding():
		ledge_boost()


func _physics_process(delta: float) -> void:
	if not is_multiplayer_authority(): return

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
		# Lava floor check: the floor is lava!
		if global_position.y <= 0.6:
			velocity.y = JUMP_VELOCITY * 1.8 # Big fiery lava bounce!


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

func _on_peer_connected(peer_id: int) -> void:
	if is_multiplayer_authority() and multiplayer.has_multiplayer_peer():
		sync_customization.rpc_id(peer_id, player_color, eye_style)

@rpc("any_peer", "call_local", "reliable")
func sync_customization(col: Color, eyes: int) -> void:
	player_color = col
	eye_style = eyes
	_apply_visuals()

func _apply_visuals() -> void:
	if bean_visual == null:
		bean_visual = get_node_or_null("BeanVisual") as BeanVisual
	if is_instance_valid(bean_visual):
		bean_visual.apply_customization(player_color, eye_style)
