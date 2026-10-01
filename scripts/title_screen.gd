extends Control

@onready var color_row: HBoxContainer = %ColorRow
@onready var eye_option: OptionButton = %EyeOption
@onready var join_panel: VBoxContainer = %JoinPanel
@onready var join_code: LineEdit = %JoinCode
@onready var preview: Panel = %BeanPreview
@onready var status: Label = %Status

func _ready() -> void:
	for index in range(GameSettings.BEAN_COLORS.size()):
		var button := Button.new()
		button.custom_minimum_size = Vector2(42, 42)
		button.tooltip_text = "Bean colour %d" % (index + 1)
		button.modulate = GameSettings.BEAN_COLORS[index]
		button.text = "●"
		button.add_theme_font_size_override("font_size", 30)
		button.pressed.connect(_select_color.bind(index))
		color_row.add_child(button)
	for style in GameSettings.EYE_STYLES:
		eye_option.add_item(style)
	eye_option.selected = GameSettings.eye_style
	join_panel.hide()
	_update_preview()

func _select_color(index: int) -> void:
	GameSettings.bean_color = GameSettings.BEAN_COLORS[index]
	_update_preview()

func _on_eye_option_item_selected(index: int) -> void:
	GameSettings.eye_style = index
	_update_preview()

func _update_preview() -> void:
	preview.modulate = GameSettings.bean_color

func _on_host_pressed() -> void:
	GameSettings.launch_mode = "host"
	GameSettings.join_code = ""
	get_tree().change_scene_to_file("res://scenes/testMain.tscn")

func _on_join_pressed() -> void:
	join_panel.show()
	join_code.grab_focus()
	status.text = "Paste the host's Peak Code, then dive in."

func _on_start_join_pressed() -> void:
	if join_code.text.strip_edges().is_empty():
		status.text = "A Peak Code is needed to join a lava run."
		return
	GameSettings.launch_mode = "join"
	GameSettings.join_code = join_code.text.strip_edges()
	get_tree().change_scene_to_file("res://scenes/testMain.tscn")
