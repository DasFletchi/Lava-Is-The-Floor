extends Control

# Menu buttons
@onready var play_button: Button = %PlayButton
@onready var quit_button: Button = %QuitButton

@onready var level_1_button: Button = $"UIOverlay/HBox/LeftColumn/LevelSelect Button/Level1Button"
@onready var back_button: Button = $"UIOverlay/HBox/LeftColumn/LevelSelect Button/BackButton"


# Customizer controls (Grapples Galore carousel style)
@onready var prev_color_button: Button = %PrevColorButton
@onready var next_color_button: Button = %NextColorButton
@onready var color_label: Label = %ColorLabel

@onready var prev_eye_button: Button = %PrevEyeButton
@onready var next_eye_button: Button = %NextEyeButton
@onready var eye_label: Label = %EyeLabel

# 3D Preview
@onready var viewport_container: SubViewportContainer = %ViewportContainer
@onready var bean_root: Node3D = %BeanRoot
@onready var preview_bean: BeanVisual = %PreviewBean
@onready var preview_camera: Camera3D = %PreviewCamera

# Line Edit
@onready var gamertag: LineEdit = $UIOverlay/HBox/RightColumn/Gamertag

# Music Players
@onready var title_track_1: AudioStreamPlayer2D = $TitleTrack1
@onready var title_track_2: AudioStreamPlayer2D = $TitleTrack2

# VBoxContainers
@onready var menu_buttons: VBoxContainer = $UIOverlay/HBox/LeftColumn/MenuButtons
@onready var level_select_buttons: VBoxContainer = $"UIOverlay/HBox/LeftColumn/LevelSelect Button"


var customizer: Node = null
var is_dragging: bool = false
var last_mouse_x: float = 0.0
var current_yaw: float = PI
var idle_time: float = 0.0

func _get_customizer() -> Node:
	if customizer != null:
		return customizer
	if has_node("/root/PlayerCustomization"):
		customizer = get_node("/root/PlayerCustomization")
	if customizer == null:
		var cls = load("res://globals/player_customization.gd")
		if cls:
			customizer = cls.new()
			add_child(customizer)
	return customizer

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

	# Ensure Camera3D is active
	if preview_camera:
		preview_camera.current = true

	if bean_root:
		bean_root.rotation.y = current_yaw

	# Button signals
	play_button.pressed.connect(_on_play_pressed)
	quit_button.pressed.connect(_on_quit_pressed)

	prev_color_button.pressed.connect(_on_prev_color_pressed)
	next_color_button.pressed.connect(_on_next_color_pressed)
	prev_eye_button.pressed.connect(_on_prev_eye_pressed)
	next_eye_button.pressed.connect(_on_next_eye_pressed)

	# Interactive drag to rotate 3D bean
	viewport_container.gui_input.connect(_on_viewport_gui_input)

	# Hook into customization
	var cust = _get_customizer()
	if cust != null:
		cust.customization_changed.connect(_on_customization_changed)
		_update_ui()
		_apply_to_preview(cust.selected_color, cust.selected_eye_style, false)
	
	
	if gamertag != null:
		gamertag.text = PlayerCustomization.player_name
		gamertag.text_changed.connect(_on_gamertag_changed)



	var music_player_title = randi() % 2
	print("used title track:", music_player_title)
	if music_player_title == 1:
		title_track_1.play()
	else:
		title_track_2.play()



func _on_gamertag_changed(new_text: String) -> void:
	if not new_text.strip_edges().is_empty():
		PlayerCustomization.player_name = new_text.strip_edges()
		PlayerCustomization.save_data()



func _process(delta: float) -> void:
	if bean_root == null: return
	idle_time += delta
	if is_dragging:
		bean_root.rotation.y = current_yaw
	else:
		# Subtle lively idle breathing / gentle sway around facing angle
		bean_root.rotation.y = current_yaw + sin(idle_time * 1.8) * 0.08

func _on_viewport_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			is_dragging = event.pressed
			last_mouse_x = event.position.x
	elif event is InputEventMouseMotion and is_dragging:
		var dx = event.position.x - last_mouse_x
		last_mouse_x = event.position.x
		current_yaw += dx * 0.015

func _on_play_pressed() -> void:
	menu_buttons.hide()
	level_select_buttons.show()

func _on_quit_pressed() -> void:
	get_tree().quit()

func _on_prev_color_pressed() -> void:
	var cust = _get_customizer()
	if cust: cust.prev_color()

func _on_next_color_pressed() -> void:
	var cust = _get_customizer()
	if cust: cust.next_color()

func _on_prev_eye_pressed() -> void:
	var cust = _get_customizer()
	if cust: cust.prev_eye()

func _on_next_eye_pressed() -> void:
	var cust = _get_customizer()
	if cust: cust.next_eye()

func _on_customization_changed(col: Color, eye_id: int) -> void:
	_update_ui()
	_apply_to_preview(col, eye_id, true)

func _update_ui() -> void:
	var cust = _get_customizer()
	if cust == null: return
	color_label.text = "Color: %s" % cust.get_current_color_name()
	eye_label.text = "Eyes: %s" % cust.get_current_eye_name()

func _apply_to_preview(col: Color, eye_id: int, bounce: bool = true) -> void:
	if preview_bean != null:
		preview_bean.apply_customization(col, eye_id)

	if bounce and bean_root != null:
		var tween = create_tween()
		tween.tween_property(bean_root, "scale", Vector3(1.1, 0.9, 1.1), 0.08)
		tween.tween_property(bean_root, "scale", Vector3(0.95, 1.05, 0.95), 0.10)
		tween.tween_property(bean_root, "scale", Vector3(1.0, 1.0, 1.0), 0.08)


func _on_level_1_button_pressed() -> void:
	if gamertag != null and not gamertag.text.strip_edges().is_empty():
		PlayerCustomization.player_name = gamertag.text.strip_edges()
		PlayerCustomization.save_data()
		get_tree().change_scene_to_file("res://scenes/Level1.tscn")

func _on_back_button_pressed() -> void:
	level_select_buttons.hide()
	menu_buttons.show()
