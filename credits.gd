extends Control

@export var scroll_speed: float = 65.0
@export var main_menu_scene: String = "res://scenes/title_screen.tscn"

@onready var credits_container = $CreditsContainer

var credits_data = [
	{"role": "", "name": "LAVA IS THE FLOOR??"},
	{"role": "", "name": ""},
	{"role": "A Game by", "name": "Fletchi"},
	{"role": "", "name": ""},
	{"role": "Special Birthday Dedication", "name": "Made with ❤️ for Henrik's Birthday!"},
	{"role": "", "name": ""},
	{"role": "Happy Birthday Henrik", "name": "Have an awesome birthday! 🎉"},
	{"role": "", "name": ""},
	{"role": "---", "name": "---"},
	{"role": "", "name": ""},
	{"role": "TOOLS & TECHNOLOGIES", "name": ""},
	{"role": "", "name": ""},
	{"role": "Game Engine", "name": "Godot Engine 4.7"},
	{"role": "Engine Creators", "name": "Juan Linietsky, Ariel Manzur & Community"},
	{"role": "", "name": ""},
	{"role": "Multiplayer State & Synchronization", "name": "Netfox by Foxssake"},
	{"role": "Relay Server & NAT Traversal", "name": "Noray by Foxssake"},
	{"role": "", "name": ""},
	{"role": "In-Editor 3D Asset Placement", "name": "Go Placer by bramreth"},
	{"role": "", "name": ""},
	{"role": "---", "name": "---"},
	{"role": "", "name": ""},
	{"role": "MUSIC & AUDIO", "name": ""},
	{"role": "", "name": ""},
	{"role": "Title & Lobby Music", "name": "Rafael Archangel (\"Machine\", \"Two Heads\")"},
	{"role": "Parkour Level Music", "name": "Loyalty Freak Music (\"Can't Stop My Feet\")"},
	{"role": "Music Platform", "name": "Chosic (chosic.com)"},
	{"role": "", "name": ""},
	{"role": "Interface & UI Sounds", "name": "eternitys (interface1.wav via Freesound)"},
	{"role": "Buzzer & Fanfares", "name": "Elimination Buzzer & Victory Sound"},
	{"role": "", "name": ""},
	{"role": "---", "name": "---"},
	{"role": "", "name": ""},
	{"role": "3D MODELS & ASSETS", "name": ""},
	{"role": "", "name": ""},
	{"role": "Asset Kits (CC0 1.0 Universal)", "name": "Kenney (kenney.nl)"},
	{"role": "Kenney Furniture Kit", "name": "140 Living Room & Bedroom Meshes"},
	{"role": "Kenney Retro Urban Kit", "name": "124 Urban Props & Fire Escape Stairs"},
	{"role": "Kenney Factory Kit", "name": "143 Industrial Pipes & Warehouse Props"},
	{"role": "Kenney Mini Skate Kit", "name": "20 Skatepark & Ramp Meshes"},
	{"role": "Kenney Mini Arcade Kit", "name": "20 Arcade Cabinets & Games"},
	{"role": "", "name": ""},
	{"role": "Playground & Classroom Props (CC-BY 3.0)", "name": "Google Poly Archive (Poly Pizza)"},
	{"role": "Gym, Slide, Trampoline & More", "name": "Poly by Google"},
	{"role": "", "name": ""},
	{"role": "Modular Blueprint Kit", "name": "tuily (tuily.itch.io)"},
	{"role": "Hand Base Meshes", "name": "FloofyBoof (Sketchfab)"},
	{"role": "", "name": ""},
	{"role": "---", "name": "---"},
	{"role": "", "name": ""},
	{"role": "SPECIAL THANKS", "name": ""},
	{"role": "", "name": ""},
	{"role": "Birthday Legend", "name": "Henrik"},
	{"role": "Playtesters & Friends", "name": ""},
	{"role": "", "name": ""},
	{"role": "", "name": "THANK YOU FOR PLAYING!"},
	{"role": "", "name": "Some features of the Game were programmed by Google Antigravity. However I understand everything in this code."},
	{"role": "", "name": "- End -"}
]

func _ready() -> void:
	# Automatically create labels from credits data
	for entry in credits_data:
		if entry["role"] == "---" and entry["name"] == "---":
			var sep = HSeparator.new()
			sep.custom_minimum_size.x = 420
			sep.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
			credits_container.add_child(sep)
			var spacer = Control.new()
			spacer.custom_minimum_size.y = 15
			credits_container.add_child(spacer)
			continue

		if entry["role"] != "":
			var role_label = Label.new()
			role_label.text = entry["role"]
			role_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			role_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			if entry["role"].begins_with("Special") or entry["role"].begins_with("Happy") or entry["role"] == "A Game by":
				role_label.add_theme_color_override("font_color", Color(1.0, 0.55, 0.2))
			else:
				role_label.add_theme_color_override("font_color", Color(0.65, 0.65, 0.65))
			credits_container.add_child(role_label)

		if entry["name"] != "":
			var name_label = Label.new()
			name_label.text = entry["name"]
			name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			if entry["name"].begins_with("LAVA IS") or entry["name"].begins_with("THANK YOU"):
				name_label.add_theme_color_override("font_color", Color(1.0, 0.72, 0.2))
				name_label.add_theme_font_size_override("font_size", 36)
			elif entry["role"] == "" and (entry["name"].ends_with("TECHNOLOGIES") or entry["name"].ends_with("AUDIO") or entry["name"].ends_with("ASSETS") or entry["name"].ends_with("THANKS")):
				name_label.add_theme_color_override("font_color", Color(1.0, 0.55, 0.25))
				name_label.add_theme_font_size_override("font_size", 26)
			else:
				name_label.add_theme_font_size_override("font_size", 28)
			credits_container.add_child(name_label)

		# Small spacer
		var spacer = Control.new()
		spacer.custom_minimum_size.y = 20
		credits_container.add_child(spacer)

	credits_container.reset_size()

	# Center horizontally and position below the screen
	get_viewport().size_changed.connect(_update_container_x)
	_update_container_x()
	credits_container.position.y = get_viewport_rect().size.y

func _update_container_x() -> void:
	var vp_width = get_viewport_rect().size.x
	var target_width = minf(860.0, vp_width - 80.0)
	credits_container.custom_minimum_size.x = target_width
	credits_container.size.x = target_width
	credits_container.position.x = (vp_width - target_width) / 2.0

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") or (event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE):
		return_to_main_menu()

func _process(delta: float) -> void:
	var multiplier: float = 1.0
	if Input.is_key_pressed(KEY_SPACE) or Input.is_key_pressed(KEY_DOWN) or Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		multiplier = 3.5

	# Ensure container stays perfectly centered horizontally
	_update_container_x()

	# Move container upwards
	credits_container.position.y -= scroll_speed * multiplier * delta

	# When credits have scrolled off-screen (or ESC is pressed), return to main menu
	if credits_container.position.y + credits_container.size.y < 0 or Input.is_action_just_pressed("ui_cancel"):
		return_to_main_menu()

func return_to_main_menu() -> void:
	get_tree().change_scene_to_file(main_menu_scene)
