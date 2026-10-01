extends CharacterBody3D
@export var mouse_sensitivity: float = 0.005
@export var anim_transition_time: float = 0.5
@onready var camera: Camera3D = $Camera3D
@onready var mesh_instance_3d: MeshInstance3D = $MeshInstance3D
@onready var ray_cast_3d: RayCast3D = $RayCast3D
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var bean_body: MeshInstance3D = $BeanBody
@onready var left_eye: MeshInstance3D = $Eyes/LeftEye
@onready var right_eye: MeshInstance3D = $Eyes/RightEye


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
var eliminated := false
const LAVA_RAGDOLL_SCENE := preload("res://scenes/lava_ragdoll.tscn")

func _ready() -> void:
	_apply_bean_look()
	if not is_multiplayer_authority(): return
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	#animation_player.playback_default_blend_time = anim_transition_time #geiles godot feature damit man nicht so snappy von animation zu animation wechselts
	animation_player.animation_finished.connect(_on_animation_finished)
	animation_player.play("RESET")
	camera.make_current()# der code wird eh nicht ausgefüll wenn wir nicht big server authority haben



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
	if eliminated:
		return
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


func _enter_tree() -> void: #Diese Funktion wird ganz früh aufgerufen, noch bevor die Node komplett in der Szene geladen ist (also vor _ready). Das ist wichtig, damit die "Machtverhältnisse" geklärt sind, bevor das Spiel richtig losgeht.
	set_multiplayer_authority(str(name).to_int()) #grabbt sich den namen von der node die wir als peer id gesetzt haben und macht zu int damit er es essen kann und der node authority geben kann

func eliminate() -> void:
	if eliminated:
		return
	eliminated = true
	_spawn_lava_ragdoll()
	velocity = Vector3.ZERO
	visible = false
	$CollisionShape3D.set_deferred("disabled", true)

func _spawn_lava_ragdoll() -> void:
	var ragdoll := LAVA_RAGDOLL_SCENE.instantiate()
	ragdoll.global_transform = global_transform
	ragdoll.set_appearance(GameSettings.bean_color, GameSettings.eye_style)
	# The torque makes every elimination look like a dramatic, silly tumble.
	ragdoll.angular_velocity = Vector3(randf_range(-7.0, 7.0), randf_range(-7.0, 7.0), randf_range(-7.0, 7.0))
	get_parent().call_deferred("add_child", ragdoll)

func _apply_bean_look() -> void:
	var body_material := StandardMaterial3D.new()
	body_material.albedo_color = GameSettings.bean_color
	body_material.metallic = 0.08
	body_material.roughness = 0.36
	bean_body.material_override = body_material
	if GameSettings.eye_style == 1:
		left_eye.scale = Vector3(1.35, 1.35, 1.0)
		right_eye.scale = Vector3(1.35, 1.35, 1.0)
	elif GameSettings.eye_style == 2:
		left_eye.rotation.z = 0.38
		right_eye.rotation.z = -0.38
