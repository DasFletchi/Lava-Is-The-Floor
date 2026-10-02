extends Node

var player = AudioStreamPlayer.new()

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	print("DEBUG WINDOW: ", get_tree().root.size, " content_scale_size: ", get_tree().root.content_scale_size, " mode: ", get_tree().root.content_scale_mode, " aspect: ", get_tree().root.content_scale_aspect)
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

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_F11 or (event.keycode == KEY_ENTER and event.alt_pressed):
			var is_full = DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN
			DisplayServer.window_set_mode(
				DisplayServer.WINDOW_MODE_WINDOWED if is_full else DisplayServer.WINDOW_MODE_FULLSCREEN
			)
