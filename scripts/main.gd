extends Node3D

@onready var multiplayer_menu: Node = get_node_or_null("Mutliplayer temp menu")
@onready var temp_mp_menu: PanelContainer = get_node_or_null("Mutliplayer temp menu/tempMPMenu")
@onready var main_box: VBoxContainer = get_node_or_null("Mutliplayer temp menu/tempMPMenu/VBoxContainer")
@onready var adress_entry: LineEdit = get_node_or_null("Mutliplayer temp menu/tempMPMenu/VBoxContainer/AdressEntry")

@onready var lobby_box: VBoxContainer = get_node_or_null("Mutliplayer temp menu/tempMPMenu/LobbyBox")
@onready var lobby_code_label: Label = get_node_or_null("Mutliplayer temp menu/tempMPMenu/LobbyBox/CodeContainer/CodeLabel")
@onready var lobby_copy_btn: Button = get_node_or_null("Mutliplayer temp menu/tempMPMenu/LobbyBox/CodeContainer/CopyButton")
@onready var lobby_status_label: Label = get_node_or_null("Mutliplayer temp menu/tempMPMenu/LobbyBox/StatusLabel")
@onready var lobby_players_label: Label = get_node_or_null("Mutliplayer temp menu/tempMPMenu/LobbyBox/PlayerCountLabel")
@onready var lobby_start_button: Button = get_node_or_null("Mutliplayer temp menu/tempMPMenu/LobbyBox/StartButton")
@onready var lobby_wait_label: Label = get_node_or_null("Mutliplayer temp menu/tempMPMenu/LobbyBox/ClientWaitLabel")

const tempPlayerScene = preload("res://scenes/player.tscn")
const PORT = 9999
var enet_peer = ENetMultiplayerPeer.new()

const NORAY_HOST = "tomfol.io"
const NORAY_PORT = 8890

var rng = RandomNumberGenerator.new()
var seed_value := 0

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

## Spiel- & Rundenstatus
var is_round_started: bool = false
var is_host: bool = false
var current_room_code: String = ""

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	setup_level_collisions(self)
	await Noray.connect_to_host(NORAY_HOST, NORAY_PORT)
	print("connected to relay")

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

func _show_lobby_view(as_host: bool) -> void:
	if main_box:
		main_box.hide()
	if lobby_box:
		lobby_box.show()
	if lobby_start_button:
		lobby_start_button.visible = as_host
	if lobby_wait_label:
		lobby_wait_label.visible = not as_host
	_update_lobby_player_count()

func _update_lobby_player_count() -> void:
	var count = 1
	if multiplayer.has_multiplayer_peer():
		count = multiplayer.get_peers().size() + 1
	else:
		var players = get_tree().get_nodes_in_group("player")
		if players.size() > 0:
			count = players.size()
	if lobby_players_label:
		lobby_players_label.text = "👥 Verbundene Spieler: " + str(count)

func _on_host_pressed() -> void:
	is_host = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	
	# Lobby-Ansicht einblenden (UI bleibt offen!)
	_show_lobby_view(true)
	if lobby_status_label:
		lobby_status_label.text = "Erstelle Noray-Sitzung..."
	if lobby_start_button:
		lobby_start_button.disabled = true

	Noray.register_host()
	await Noray.on_pid
	print("MY OID: ", Noray.oid)
	current_room_code = Noray.oid

	# Gamercode direkt in die Zwischenablage kopieren
	DisplayServer.clipboard_set(Noray.oid)
	if lobby_code_label:
		lobby_code_label.text = current_room_code

	await Noray.register_remote()
	print("MY OWN PORT: ", Noray.local_port)

	enet_peer.create_server(Noray.local_port)
	multiplayer.multiplayer_peer = enet_peer

	Noray.on_connect_nat.connect(nat_connect)
	Noray.on_connect_relay.connect(relay_connect)

	add_player(multiplayer.get_unique_id())
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)

	if lobby_status_label:
		lobby_status_label.text = "Lobby aktiv! Code in Zwischenablage kopiert."
	if lobby_start_button:
		lobby_start_button.disabled = false
	_update_lobby_player_count()

func _on_join_pressed() -> void:
	var host_oid = adress_entry.text.strip_edges()
	if host_oid.is_empty():
		push_error("Please first insert ur OID")
		return

	is_host = false
	current_room_code = host_oid
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

	_show_lobby_view(false)
	if lobby_status_label:
		lobby_status_label.text = "Verbinde mit Host..."
	if lobby_code_label:
		lobby_code_label.text = host_oid

	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)

	Noray.register_host()
	await Noray.on_pid
	await Noray.register_remote()

	Noray.on_connect_nat.connect(join)
	Noray.on_connect_relay.connect(join)
	Noray.connect_nat(host_oid)

func _on_copy_code_pressed() -> void:
	if not current_room_code.is_empty():
		DisplayServer.clipboard_set(current_room_code)
	if lobby_copy_btn:
		lobby_copy_btn.text = "✓ Kopiert!"
		var timer = get_tree().create_timer(2.0)
		timer.timeout.connect(func():
			if is_instance_valid(lobby_copy_btn):
				lobby_copy_btn.text = "📋 Kopieren"
		)

func _on_start_round_pressed() -> void:
	if not is_host and multiplayer.has_multiplayer_peer() and not multiplayer.is_server():
		return
	if multiplayer.has_multiplayer_peer():
		start_game_round.rpc()
	else:
		start_game_round()

func _on_leave_lobby_pressed() -> void:
	if multiplayer.has_multiplayer_peer():
		multiplayer.multiplayer_peer.close()
		multiplayer.multiplayer_peer = null
	is_round_started = false
	is_host = false
	current_room_code = ""

	for p in get_tree().get_nodes_in_group("player"):
		p.queue_free()

	if lobby_box:
		lobby_box.hide()
	if main_box:
		main_box.show()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _on_back_pressed() -> void:
	if multiplayer.has_multiplayer_peer():
		multiplayer.multiplayer_peer.close()
		multiplayer.multiplayer_peer = null
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	get_tree().change_scene_to_file("res://scenes/title_screen.tscn")

func join(address: String, port: int) -> void:
	enet_peer.create_client(address, port, 0, 0, 0, Noray.local_port)
	multiplayer.multiplayer_peer = enet_peer
	if lobby_status_label:
		lobby_status_label.text = "Verbunden mit Host! Warte auf Start..."
	_update_lobby_player_count()

func nat_connect(address: String, port: int) -> void:
	await PacketHandshake.over_enet_peer(enet_peer, address, port)
	print("Someone joins through NAT (direct): ", address, ":", port)

func relay_connect(address: String, port: int) -> void:
	await PacketHandshake.over_enet_peer(enet_peer, address, port)
	print("Someone joins through a relay: ", address, ":", port)

func _on_peer_connected(peer_id: int) -> void:
	print("Peer connected: ", peer_id)
	if multiplayer.is_server():
		add_player(peer_id)
	_update_lobby_player_count()

func _on_peer_disconnected(peer_id: int) -> void:
	print("Peer disconnected: ", peer_id)
	if multiplayer.is_server():
		remove_player(peer_id)
	_update_lobby_player_count()

func add_player(peer_id: int) -> void:
	var player = tempPlayerScene.instantiate()
	player.name = str(peer_id)
	player.can_move = is_round_started
	add_child(player)
	player.global_position = Vector3(0.0, 1.8, 3.0)
	_update_lobby_player_count()

func remove_player(peer_id: int) -> void:
	var player = get_node_or_null(str(peer_id))
	if player:
		player.queue_free()
	_update_lobby_player_count()

## Startet die Runde für alle Spieler synchron
@rpc("authority", "call_local", "reliable")
func start_game_round() -> void:
	is_round_started = true

	# Menü & Lobby UI komplett ausblenden
	if multiplayer_menu:
		multiplayer_menu.hide()
	if temp_mp_menu:
		temp_mp_menu.hide()

	# Maus fangen (Ego-Shooter Modus)
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

	# Alle Spieler freischalten
	for p in get_tree().get_nodes_in_group("player"):
		p.can_move = true

	# Lava starten
	start_lava()
	print("Game round started! All players unlocked, lava rising.")

## Lava-Befehle (können jederzeit aufgerufen oder per RPC synchronisiert werden)
@rpc("authority", "call_local", "reliable")
func start_lava() -> void:
	var lava = get_node_or_null("Lava")
	if lava and lava.has_method("start_rising"):
		lava.start_rising()

@rpc("authority", "call_local", "reliable")
func stop_lava() -> void:
	var lava = get_node_or_null("Lava")
	if lava and lava.has_method("stop_rising"):
		lava.stop_rising()

@rpc("authority", "call_local", "reliable")
func reset_lava() -> void:
	var lava = get_node_or_null("Lava")
	if lava and lava.has_method("reset_lava"):
		lava.reset_lava()
