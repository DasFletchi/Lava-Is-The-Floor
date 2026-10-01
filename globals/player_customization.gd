extends Node
class_name PlayerCustomizer

signal customization_changed(color: Color, eye_style: int)

const SAVE_PATH = "user://bean_customization.cfg"

var player_name: String = "Player"

const EYE_STYLES: Array[Dictionary] = [
	{"id": 0, "name": "Classic", "icon": "👀"},
	{"id": 1, "name": "Derp", "icon": "🤪"},
	{"id": 2, "name": "Angry", "icon": "😠"},
	{"id": 3, "name": "Happy", "icon": "^^"},
	{"id": 4, "name": "Henrik", "icon": "🕶️"},
	{"id": 5, "name": "Cyclops", "icon": "👁️"},
	{"id": 6, "name": "Shocked", "icon": "😲"},
	{"id": 7, "name": "Sleepy", "icon": "😴"},
	{"id": 8, "name": "Inferno", "icon": "🔥"},
	{"id": 9, "name": "Dizzy", "icon": "😵"},
]

const COLOR_PALETTE: Array[Dictionary] = [
	{"name": "Magma Orange", "color": Color("ff4500")},
	{"name": "Lava Red", "color": Color("e63946")},
	{"name": "Ember Gold", "color": Color("ffb703")},
	{"name": "Flame Orange", "color": Color("fb8500")},
	{"name": "Toxic Lime", "color": Color("38b000")},
	{"name": "Mint Green", "color": Color("52b788")},
	{"name": "Electric Cyan", "color": Color("00b4d8")},
	{"name": "Cobalt Blue", "color": Color("4361ee")},
	{"name": "Mystic Violet", "color": Color("7209b7")},
	{"name": "Hot Pink", "color": Color("f72585")},
	{"name": "White", "color": Color("f8f9fa")},
	{"name": "Obsidian Black", "color": Color("181818")},
]

var selected_color: Color = Color("ff4500")
var selected_color_index: int = 0
var selected_eye_style: int = 0

func _ready() -> void:
	load_data()

func next_color() -> void:
	selected_color_index = posmod(selected_color_index + 1, COLOR_PALETTE.size())
	selected_color = COLOR_PALETTE[selected_color_index]["color"]
	customization_changed.emit(selected_color, selected_eye_style)
	save_data()

func prev_color() -> void:
	selected_color_index = posmod(selected_color_index - 1, COLOR_PALETTE.size())
	selected_color = COLOR_PALETTE[selected_color_index]["color"]
	customization_changed.emit(selected_color, selected_eye_style)
	save_data()

func get_current_color_name() -> String:
	return COLOR_PALETTE[selected_color_index]["name"]

func next_eye() -> void:
	selected_eye_style = posmod(selected_eye_style + 1, EYE_STYLES.size())
	customization_changed.emit(selected_color, selected_eye_style)
	save_data()

func prev_eye() -> void:
	selected_eye_style = posmod(selected_eye_style - 1, EYE_STYLES.size())
	customization_changed.emit(selected_color, selected_eye_style)
	save_data()

func get_current_eye_name() -> String:
	return EYE_STYLES[selected_eye_style]["name"]

func set_color(c: Color) -> void:
	selected_color = c
	# Find matching palette index if exists
	for i in range(COLOR_PALETTE.size()):
		if COLOR_PALETTE[i]["color"].is_equal_approx(c):
			selected_color_index = i
			break
	customization_changed.emit(selected_color, selected_eye_style)
	save_data()

func set_eye_style(idx: int) -> void:
	selected_eye_style = posmod(idx, EYE_STYLES.size())
	customization_changed.emit(selected_color, selected_eye_style)
	save_data()

func save_data() -> void:
	var config = ConfigFile.new()
	config.set_value("bean", "color", selected_color)
	config.set_value("bean", "color_index", selected_color_index)
	config.set_value("bean", "eye_style", selected_eye_style)
	config.save(SAVE_PATH)

func load_data() -> void:
	var config = ConfigFile.new()
	var err = config.load(SAVE_PATH)
	if err == OK:
		selected_color = config.get_value("bean", "color", Color("ff4500"))
		selected_color_index = config.get_value("bean", "color_index", 0)
		selected_eye_style = config.get_value("bean", "eye_style", 0)
		# Safety check index bounds
		selected_color_index = clamp(selected_color_index, 0, COLOR_PALETTE.size() - 1)
		selected_eye_style = clamp(selected_eye_style, 0, EYE_STYLES.size() - 1)
