extends Node

var player = AudioStreamPlayer.new()

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	player.stream = preload("res://sfx/chosic/141121__eternitys__interface1.wav")
	# Lautstärke: 0 dB (oder leicht verstärkt), damit der Sound über der Musik deutlich hörbar ist!
	player.volume_db = -4.0
	add_child(player)

	# 1. Alle Buttons verbinden, die beim Start schon da sind
	_connect_all_buttons(get_tree().root)

	# 2. Alle Buttons verbinden, die später ins Spiel geladen werden
	get_tree().node_added.connect(_on_node_added)

func _on_node_added(node: Node) -> void:
	if node is BaseButton:
		_hook_button(node)

func _connect_all_buttons(node: Node) -> void:
	if node is BaseButton:
		_hook_button(node)
	for child in node.get_children():
		_connect_all_buttons(child)

func _hook_button(btn: BaseButton) -> void:
	if not btn.pressed.is_connected(play):
		btn.pressed.connect(play)

func play() -> void:
	if player:
		player.stop()
		player.play()
