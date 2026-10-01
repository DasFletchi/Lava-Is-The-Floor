extends Node3D

const PLAYER_SCENE := preload("res://scenes/player.tscn")
const PORT := 9999
const NORAY_HOST := "tomfol.io"
const NORAY_PORT := 8890
const LAVA_Y := -2.0

@onready var hud: Label = %Hud
@onready var announcement: Label = %Announcement

var peer := ENetMultiplayerPeer.new()
var eliminated: Dictionary = {}
var round_finished := false

func _ready() -> void:
	_build_hot_lava_course()
	await Noray.connect_to_host(NORAY_HOST, NORAY_PORT)
	if GameSettings.launch_mode == "join":
		_start_join()
	else:
		_start_host()

func _start_host() -> void:
	announcement.text = "Opening lava run…"
	Noray.register_host()
	await Noray.on_pid
	await Noray.register_remote()
	peer.create_server(Noray.local_port)
	multiplayer.multiplayer_peer = peer
	Noray.on_connect_nat.connect(_handshake)
	Noray.on_connect_relay.connect(_handshake)
	multiplayer.peer_connected.connect(_add_player)
	multiplayer.peer_disconnected.connect(_remove_player)
	_add_player(multiplayer.get_unique_id())
	announcement.text = "HOSTING  •  PEAK CODE: %s" % Noray.oid

func _start_join() -> void:
	announcement.text = "Joining lava run…"
	Noray.register_host()
	await Noray.on_pid
	await Noray.register_remote()
	Noray.on_connect_nat.connect(_join)
	Noray.on_connect_relay.connect(_join)
	Noray.connect_nat(GameSettings.join_code)

func _handshake(address: String, port: int) -> void:
	await PacketHandshake.over_enet_peer(peer, address, port)

func _join(address: String, port: int) -> void:
	peer.create_client(address, port, 0, 0, 0, Noray.local_port)
	multiplayer.multiplayer_peer = peer
	announcement.text = "CONNECTED • CLIMB BEFORE THE LAVA GETS YOU"

func _add_player(peer_id: int) -> void:
	if has_node(str(peer_id)):
		return
	var player := PLAYER_SCENE.instantiate()
	player.name = str(peer_id)
	player.position = Vector3(-18 + (get_child_count() % 4) * 4, 4.0, -14)
	add_child(player)

func _remove_player(peer_id: int) -> void:
	var player := get_node_or_null(str(peer_id))
	if player:
		player.queue_free()

func _physics_process(_delta: float) -> void:
	if round_finished:
		return
	for child in get_children():
		if child is CharacterBody3D and not child.eliminated and child.global_position.y < LAVA_Y + 0.65:
			_eliminate_player(child.name.to_int())
	_update_hud()
	_check_winner()

func _eliminate_player(peer_id: int) -> void:
	if eliminated.has(peer_id):
		return
	eliminated[peer_id] = true
	var player := get_node_or_null(str(peer_id))
	if player:
		player.eliminate()
	announcement.text = "A BEAN GOT TOASTED!"

func _check_winner() -> void:
	var alive: Array[CharacterBody3D] = []
	for child in get_children():
		if child is CharacterBody3D and not child.eliminated:
			alive.append(child)
	if alive.size() == 1 and not eliminated.is_empty():
		round_finished = true
		announcement.text = "%s IS THE LAST BEAN STANDING!" % alive[0].name

func _update_hud() -> void:
	var alive := 0
	for child in get_children():
		if child is CharacterBody3D and not child.eliminated:
			alive += 1
	hud.text = "BEANS STILL COOL: %d" % alive

func _build_hot_lava_course() -> void:
	# Dense room-scale route: ledges, ramps and islands—not a skybox of floating blocks.
	_add_lava()
	var pieces := [
		[Vector3(8, 1, 7), Vector3(-17, 1.0, -14)], [Vector3(5, 1, 6), Vector3(-9, 3, -10)],
		[Vector3(4, 1, 8), Vector3(-1, 5, -5)], [Vector3(9, 1, 4), Vector3(9, 7, -4)],
		[Vector3(5, 1, 8), Vector3(15, 9, 3)], [Vector3(11, 1, 5), Vector3(7, 11, 11)],
		[Vector3(7, 1, 7), Vector3(-5, 13, 10)], [Vector3(8, 1, 5), Vector3(-14, 15, 5)],
		[Vector3(6, 1, 8), Vector3(-14, 17, -6)], [Vector3(10, 1, 6), Vector3(-2, 19, -13)]
	]
	for data in pieces:
		_add_platform(data[0], data[1])
	_add_platform(Vector3(48, 1, 3), Vector3(0, 8, 16))
	_add_platform(Vector3(3, 1, 48), Vector3(20, 10, 0))

func _add_platform(size: Vector3, location: Vector3) -> void:
	var platform := CSGBox3D.new()
	platform.size = size
	platform.position = location
	platform.use_collision = true
	var material := StandardMaterial3D.new()
	material.albedo_color = Color("26364c")
	material.metallic = 0.25
	material.roughness = 0.55
	platform.material = material
	add_child(platform)

func _add_lava() -> void:
	var lava := MeshInstance3D.new()
	lava.name = "AnimatedLava"
	lava.set_script(preload("res://scripts/lava.gd"))
	var plane := PlaneMesh.new()
	plane.size = Vector2(70, 70)
	plane.subdivide_width = 32
	plane.subdivide_depth = 32
	lava.mesh = plane
	lava.position.y = LAVA_Y
	var material := ShaderMaterial.new()
	material.shader = preload("res://shaders/lava.gdshader")
	lava.material_override = material
	add_child(lava)
