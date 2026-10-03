extends Node3D

## Drehgeschwindigkeit des Deckenventilators in Radiant pro Sekunde
@export var spin_speed: float = 7.0

@onready var synchronizer: MultiplayerSynchronizer = get_node_or_null("MultiplayerSynchronizer")

func _ready() -> void:
	_setup_synchronizer()

func _setup_synchronizer() -> void:
	if not synchronizer:
		synchronizer = MultiplayerSynchronizer.new()
		synchronizer.name = "MultiplayerSynchronizer"
		synchronizer.root_path = NodePath("..")
		var config := SceneReplicationConfig.new()
		config.add_property(NodePath(".:rotation"))
		config.property_set_replication_mode(NodePath(".:rotation"), SceneReplicationConfig.REPLICATION_MODE_ALWAYS)
		synchronizer.replication_config = config
		add_child(synchronizer)

func _physics_process(delta: float) -> void:
	# Nur der Host/Server bzw. im Einzelspieler rotiert den Ventilator.
	# Verbundene Clients empfangen die Rotation kontinuierlich über den MultiplayerSynchronizer.
	var is_server := not multiplayer.has_multiplayer_peer() or multiplayer.is_server()
	if is_server:
		rotate_y(spin_speed * delta)

