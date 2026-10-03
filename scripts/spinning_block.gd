extends Node3D

@onready var animation_player: AnimationPlayer = get_node_or_null("AnimationPlayer")
@onready var body: AnimatableBody3D = get_node_or_null("AnimatableBody3D")
@onready var synchronizer: MultiplayerSynchronizer = get_node_or_null("MultiplayerSynchronizer")

func _ready() -> void:
	_setup_synchronizer()
	
	if multiplayer:
		multiplayer.connected_to_server.connect(_on_connected_to_server)
		multiplayer.server_disconnected.connect(_on_server_disconnected)
	
	_update_role()

func _setup_synchronizer() -> void:
	if not synchronizer or not body:
		return
	synchronizer.root_path = synchronizer.get_path_to(body)
	var config := SceneReplicationConfig.new()
	config.add_property(NodePath(".:position"))
	config.property_set_replication_mode(NodePath(".:position"), SceneReplicationConfig.REPLICATION_MODE_ALWAYS)
	config.add_property(NodePath(".:rotation"))
	config.property_set_replication_mode(NodePath(".:rotation"), SceneReplicationConfig.REPLICATION_MODE_ALWAYS)
	synchronizer.replication_config = config

func _update_role() -> void:
	var is_server := not multiplayer.has_multiplayer_peer() or multiplayer.is_server()
	if is_server:
		if body:
			body.sync_to_physics = true
		if animation_player and not animation_player.is_playing():
			animation_player.play("spin")
	else:
		if body:
			body.sync_to_physics = false
		if animation_player:
			animation_player.stop()

func _on_connected_to_server() -> void:
	_update_role()

func _on_server_disconnected() -> void:
	_update_role()

