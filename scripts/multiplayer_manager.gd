extends Node3D
class_name MultiplayerManager

signal round_started
signal round_ended
signal peer_joined(peer_id: int)
signal peer_left(peer_id: int)

@export var default_spawn_position: Vector3 = Vector3(0.0, 1.8, 3.0)
@export var spawn_marker: Marker3D = null
@export var auto_start_lava: bool = true

@onready var players_container: Node3D = $Players
@onready var lobby_ui: CanvasLayer = $LobbyUI
@onready var temp_mp_menu: PanelContainer = $LobbyUI/tempMPMenu
@onready var main_box: VBoxContainer = $LobbyUI/tempMPMenu/VBoxContainer
@onready var adress_entry: LineEdit = $LobbyUI/tempMPMenu/VBoxContainer/AdressEntry

@onready var lobby_box: VBoxContainer = $LobbyUI/tempMPMenu/LobbyBox
@onready var lobby_code_label: Label = $LobbyUI/tempMPMenu/LobbyBox/CodeContainer/CodeLabel
@onready var lobby_copy_btn: Button = $LobbyUI/tempMPMenu/LobbyBox/CodeContainer/CopyButton
@onready var lobby_status_label: Label = $LobbyUI/tempMPMenu/LobbyBox/StatusLabel
@onready var lobby_players_label: Label = $LobbyUI/tempMPMenu/LobbyBox/PlayerCountLabel
@onready var lobby_start_button: Button = $LobbyUI/tempMPMenu/LobbyBox/StartButton
@onready var lobby_wait_label: Label = $LobbyUI/tempMPMenu/LobbyBox/ClientWaitLabel
@onready var tube_client: TubeClient = $TubeClient

# GameOver-UI (CanvasLayer mit Countdown-Label)
@onready var game_over_ui: CanvasLayer = get_node_or_null("GameOverUI")
@onready var game_over_label: Label = get_node_or_null("GameOverUI/GameOverLabel")

const tempPlayerScene = preload("res://scenes/player.tscn")
const NORAY_HOST = "tomfol.io"
const NORAY_PORT = 8890

var enet_peer = ENetMultiplayerPeer.new()
var is_round_started: bool = false
var is_host: bool = false
var current_room_code: String = ""
var is_game_over: bool = false

 
func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	reset_lava()
	tube_client.create_session()
	print("[MultiplayerManager] Connected to tube")
	if not multiplayer.server_disconnected.is_connected(_server_disconnected):
		multiplayer.server_disconnected.connect(_server_disconnected)

func _show_lobby_view(as_host: bool) -> void:
	if lobby_ui:
		lobby_ui.show()
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
		lobby_players_label.text = "Connected Players: " + str(count)

func _on_host_pressed() -> void:
	is_host = true
	is_round_started = false
	is_game_over = false
	stop_lava()
	reset_lava()
	enet_peer = ENetMultiplayerPeer.new()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

	_show_lobby_view(true)
	if lobby_status_label:
		lobby_status_label.text = "Creating Noray session..."
	if lobby_start_button:
		lobby_start_button.disabled = true

	print("[MultiplayerManager] MY SESSION ID:: ", tube_client.session_id)
	current_room_code = tube_client.session_id

	DisplayServer.clipboard_set(tube_client.session_id)
	if lobby_code_label:
		lobby_code_label.text = current_room_code


	add_player(multiplayer.get_unique_id())
	if not multiplayer.peer_connected.is_connected(_on_peer_connected):
		multiplayer.peer_connected.connect(_on_peer_connected)
	if not multiplayer.peer_disconnected.is_connected(_on_peer_disconnected):
		multiplayer.peer_disconnected.connect(_on_peer_disconnected)

	if lobby_status_label:
		lobby_status_label.text = "Lobby active! Code copied to clipboard."
	if lobby_start_button:
		lobby_start_button.disabled = false
	_update_lobby_player_count()

func _on_join_pressed() -> void:
	var host_oid = adress_entry.text.strip_edges()
	if host_oid.is_empty():
		push_error("Please first insert your OID")
		return

	is_host = false
	is_round_started = false
	is_game_over = false
	stop_lava()
	reset_lava()
	enet_peer = ENetMultiplayerPeer.new()
	current_room_code = host_oid
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

	_show_lobby_view(false)
	if lobby_status_label:
		lobby_status_label.text = "Connecting to host..."
	if lobby_code_label:
		lobby_code_label.text = host_oid
	tube_client.join_session(adress_entry.text)


func _on_copy_code_pressed() -> void:
	if not current_room_code.is_empty():
		DisplayServer.clipboard_set(current_room_code)
	if lobby_copy_btn:
		lobby_copy_btn.text = "Copied!"
		var timer = get_tree().create_timer(2.0)
		timer.timeout.connect(func():
			if is_instance_valid(lobby_copy_btn):
				lobby_copy_btn.text = "COPY"
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
	enet_peer = ENetMultiplayerPeer.new()
	is_round_started = false
	is_game_over = false
	is_host = false
	current_room_code = ""

	stop_lava()
	reset_lava()

	for p in get_tree().get_nodes_in_group("player"):
		p.queue_free()

	if game_over_ui:
		game_over_ui.hide()
	if lobby_box:
		lobby_box.hide()
	if main_box:
		main_box.show()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _on_back_pressed() -> void:
	stop_lava()
	reset_lava()
	if multiplayer.has_multiplayer_peer():
		multiplayer.multiplayer_peer.close()
		multiplayer.multiplayer_peer = null
	enet_peer = ENetMultiplayerPeer.new()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	get_tree().change_scene_to_file("res://scenes/title_screen.tscn")

func _on_peer_connected(peer_id: int) -> void:
	print("[MultiplayerManager] Peer connected: ", peer_id)
	if multiplayer.is_server():
		add_player(peer_id)
	_update_lobby_player_count()
	peer_joined.emit(peer_id)

func _on_peer_disconnected(peer_id: int) -> void:
	print("[MultiplayerManager] Peer disconnected: ", peer_id)
	if multiplayer.is_server():
		remove_player(peer_id)
	_update_lobby_player_count()
	peer_left.emit(peer_id)

func get_spawn_pos() -> Vector3:
	if spawn_marker and is_instance_valid(spawn_marker):
		return spawn_marker.global_position
	return default_spawn_position

func add_player(peer_id: int) -> void:
	var player = tempPlayerScene.instantiate()
	player.name = str(peer_id)
	player.can_move = is_round_started
	if players_container:
		players_container.add_child(player)
	else:
		add_child(player)
	player.global_position = get_spawn_pos()
	
	# Win-Condition Hook
	if player.has_signal("player_eliminated"):
		player.player_eliminated.connect(func(_pid): check_win_condition())

	_update_lobby_player_count()

func remove_player(peer_id: int) -> void:
	var target = players_container if players_container else self
	var player = target.get_node_or_null(str(peer_id))
	if player:
		player.queue_free()
	_update_lobby_player_count()
	check_win_condition()

## Prüft die Runden-Endbedingungen (entweder alle tot oder letzter Überlebender)
func check_win_condition() -> void:
	# Wenn die Runde gar nicht aktiv ist oder das Spiel schon beendet wird: nichts tun
	if not is_round_started or is_game_over:
		return

	# Im Multiplayer entscheidet nur der Host/Server, um Konflikte zu vermeiden
	if multiplayer.has_multiplayer_peer() and not multiplayer.is_server():
		return

	var alive = get_tree().get_nodes_in_group("alive_players")
	var all_players = get_tree().get_nodes_in_group("player")

	# Fall 1: Alle Spieler sind tot (z. B. alle in die Lava gefallen)
	if alive.is_empty():
		trigger_round_over()

	# Fall 2: Battle Royale - Mehrere Spieler waren dabei und genau 1 lebt noch!
	elif all_players.size() > 1 and alive.size() == 1:
		_declare_winner(alive[0])
		trigger_round_over()

func _declare_winner(winner: Node) -> void:
	print("[MultiplayerManager] Winner: ", winner.name)
	# Löst Sieges-Effekte (Partikel & Sound) auf dem Sieger aus
	if winner.has_method("win"):
		if multiplayer.has_multiplayer_peer():
			winner.win_rpc.rpc()
		else:
			winner.win()
	stop_lava()
	round_ended.emit()

## Manuelles Triggern des Sieges (z. B. für Solo-Tests oder Ziel-Erreichung)
func trigger_win(target_player: Node = null) -> void:
	if is_game_over:
		return
	if target_player == null:
		var alive = get_tree().get_nodes_in_group("alive_players")
		if alive.size() > 0:
			target_player = alive[0]
	if target_player:
		_declare_winner(target_player)
		trigger_round_over()

## Leitet das Rundenende ein – synchronisiert mit allen Spielern
func trigger_round_over() -> void:
	if is_game_over:
		return
	is_game_over = true

	# Wenn Multiplayer aktiv ist: Befehl an alle Spieler senden. Sonst lokal ausführen.
	if multiplayer.has_multiplayer_peer():
		start_round_over_countdown.rpc()
	else:
		start_round_over_countdown()


@rpc("authority", "call_local", "reliable")
func start_game_round() -> void:
	is_round_started = true
	is_game_over = false

	if lobby_ui:
		lobby_ui.hide()
	if game_over_ui:
		game_over_ui.hide()

	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

	reset_lava()
	if auto_start_lava:
		start_lava()

	var spawn_pos = get_spawn_pos()
	for p in get_tree().get_nodes_in_group("player"):
		p.respawn(spawn_pos)
		p.can_move = true

	round_started.emit()
	print("[MultiplayerManager] Round started! All players unlocked and respawned.")

func start_lava() -> void:
	_execute_start_lava()
	if multiplayer.has_multiplayer_peer() and multiplayer.is_server():
		_sync_start_lava.rpc()

@rpc("authority", "call_remote", "reliable")
func _sync_start_lava() -> void:
	_execute_start_lava()

func _execute_start_lava() -> void:
	var lava = _find_lava()
	if lava and lava.has_method("start_rising"):
		lava.start_rising()

func stop_lava() -> void:
	_execute_stop_lava()
	if multiplayer.has_multiplayer_peer() and multiplayer.is_server():
		_sync_stop_lava.rpc()

@rpc("authority", "call_remote", "reliable")
func _sync_stop_lava() -> void:
	_execute_stop_lava()

func _execute_stop_lava() -> void:
	var lava = _find_lava()
	if lava and lava.has_method("stop_rising"):
		lava.stop_rising()

func reset_lava() -> void:
	_execute_reset_lava()
	if multiplayer.has_multiplayer_peer() and multiplayer.is_server():
		_sync_reset_lava.rpc()

@rpc("authority", "call_remote", "reliable")
func _sync_reset_lava() -> void:
	_execute_reset_lava()

func _execute_reset_lava() -> void:
	var lava = _find_lava()
	if lava and lava.has_method("reset_lava"):
		lava.reset_lava()

func _find_lava() -> Node:
	# 1. Direct sibling in level
	if get_parent():
		var lava = get_parent().get_node_or_null("Lava")
		if lava: return lava
	# 2. Scene root child named Lava
	if get_tree().current_scene:
		var lava = get_tree().current_scene.get_node_or_null("Lava")
		if lava: return lava
	# 3. Group lava
	var lavas = get_tree().get_nodes_in_group("lava")
	if lavas.size() > 0: return lavas[0]
	return null


## Zeigt das GameOver-UI an, zählt 5 Sekunden herunter und wechselt ins Hauptmenü
@rpc("authority", "call_local", "reliable")
func start_round_over_countdown() -> void:
	is_game_over = true
	stop_lava()
	round_ended.emit()

	# GameOver-UI einblenden
	if game_over_ui:
		game_over_ui.show()

	# 5 Sekunden Countdown auf dem Bildschirm (nur Timer auf Englisch)
	for i in range(5, 0, -1):
		if not is_game_over or not is_inside_tree():
			return
		if game_over_label and is_instance_valid(game_over_label):
			game_over_label.text = "Returning to lobby in %d..." % i
		await get_tree().create_timer(1.0).timeout

	if not is_game_over or not is_inside_tree():
		return

	# Nach Ablauf der 5 Sekunden: Hauptmenü aufrufen
	_return_to_main_menu()

func _return_to_main_menu() -> void:
	is_round_started = false
	is_game_over = false
	stop_lava()
	reset_lava()
	if game_over_ui:
		game_over_ui.hide()
	_show_lobby_view(is_host)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	var spawn_pos = get_spawn_pos()
	for player in get_tree().get_nodes_in_group("player"):
		player.respawn(spawn_pos)
		player.can_move = false

func _server_disconnected():
	if multiplayer.server_disconnected:
		get_tree().change_scene_to_file("res://scenes/title_screen.tscn")
