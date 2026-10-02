extends Node3D

@onready var multiplayer_menu: Node = get_node_or_null("Mutliplayer temp menu")
@onready var temp_mp_menu: PanelContainer = $"Mutliplayer temp menu/tempMPMenu"
@onready var adress_entry: LineEdit = $"Mutliplayer temp menu/tempMPMenu/VBoxContainer/AdressEntry"

const tempPlayerScene = preload("res://scenes/player.tscn")
const PORT = 9999 #lol
var enet_peer = ENetMultiplayerPeer.new() #erstellt ein multiplayer peer element und gibt einen zeiger drauf bevor es ohne die var in den abyss verschwindet

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


@export var plattform_amount: int  = 50

@export var max_x = 50
@export var max_y = 50
@export var max_z = 50

@export var min_z = 0

## Schaltet die prozeduralen Zufallsblöcke ein/aus (in Level 1 deaktiviert für handgebautes Level)
@export var enable_procedural_platforms: bool = false


func _ready() -> void:
	setup_level_collisions(self)
	await Noray.connect_to_host(NORAY_HOST, NORAY_PORT) # await heist "warte hier und geh erst weider wenn das nach dir fertig ist"
	print ("connected to relay")

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
		# Do not add mesh collisions recursively inside the player itself
		if child is CharacterBody3D or child.is_in_group("player"):
			continue
		setup_level_collisions(child)



func _on_host_pressed() -> void:
	if multiplayer_menu:
		multiplayer_menu.hide()
	temp_mp_menu.hide()
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	#OLD NETWORKING CODE
	#enet_peer.create_server(PORT) # erstellt einen ENet-Server auf diesem Port. host client modell hier
	#multiplayer.multiplayer_peer = enet_peer
	#add_player(multiplayer.get_unique_id())
	#multiplayer.peer_connected.connect(add_player) #wenn sich jemand connected soll der einen player kriegenssss
	#multiplayer.peer_disconnected.connect(remove_player) #wir connecten das zur funktion remove player
	Noray.register_host() # Sagt Noray: "Gib mir eine öffentliche ID und eine private ID."
	await Noray.on_pid # Wartet, bis Noray wirklich geantwortet hat; erst danach darf register_remote() laufen.
	print("MY OID: ", Noray.oid) #print the OID (the ID that the user can paste into the line edit to join Noray.oid contains the oid

	await Noray.register_remote() #"Und falls jemand mit meiner OID joinen will, schick ihm diesen Port"
	print("MY OWN PORT: ", Noray.local_port) #und dies in die konsole auspucken

	enet_peer.create_server(Noray.local_port) #noray will sich lieber selber einen port aussuchen wir müssen das da reinpassen, weil er brauch die information einfach er kann sie sich nicht selber holen also stecken wir sie ihm ins maul zwischen den klammern
	multiplayer.multiplayer_peer = enet_peer #"Godot, benutze dieses Telefon für alles was Multiplayer ist" (oben ja festgelegt

	Noray.on_connect_nat.connect(nat_connect) # "Noray, wenn jemand per direkter Verbindung kommt, ruf _jemand_kommt_direkt auf"
	Noray.on_connect_relay.connect(relay_connect) # "Noray, wenn jemand per Relay kommt, ruf _jemand_kommt_per_relay auf"

	add_player(multiplayer.get_unique_id())
	multiplayer.peer_connected.connect(add_player) #ich sags nochmal multiplayer.peer_connected ist nur ein signal (hier halt in code) und wenn das abefeuert connecten wir mit .connect halt 'add_player'
	multiplayer.peer_disconnected.connect(remove_player)

func _on_join_pressed() -> void:
	var host_oid = adress_entry.text.strip_edges() # Holt die eingegebene Host-OID und entfernt versehentliche Leerzeichen vorne/hinten.
	if host_oid.is_empty(): # Wenn gar nichts eingegeben wurde, soll Join nicht starten.
		push_error("Please first insert ur OID") # Zeigt im Debugger eine klare Fehlermeldung statt später komisch zu crashen.
		return # Bricht Join hier ab, weil ohne OID kein Host gefunden werden kann.

	if multiplayer_menu:
		multiplayer_menu.hide()
	temp_mp_menu.hide()
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

	Noray.register_host() # Auch der Client braucht erst eigene Noray-IDs, damit Noray seinen Port registrieren kann.
	await Noray.on_pid # Wartet auf diese IDs; ohne das wäre register_remote() zu früh.
	await Noray.register_remote() #ich sags nochmal await macht das wir so lange bei der funktion bleiben bis wir eine bestätigung haben das sie durch ist

	Noray.on_connect_nat.connect(join) #probiert zuerst nat weil wenn geht besser weil wir keinen umweg haben wenn nicht dann isses so und dann müsssen wir relay hallo sagen
	Noray.on_connect_relay.connect(join)
 
	Noray.connect_nat(host_oid) # Fragt Noray: "Verbinde mich mit dem Host, der diese OID hat."

	#enet_peer.create_client("localhost", PORT) #das ist erstmal die ip whohin wir uns verbinden sollen, wir sind hier local also ist das fine
	#multiplayer.multiplayer_peer = enet_peer

func _on_back_pressed() -> void:
	if multiplayer_menu:
		multiplayer_menu.show()
	temp_mp_menu.show()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	get_tree().change_scene_to_file("res://scenes/title_screen.tscn")

func join(address: String, port: int) -> void: #ich nehme an das wir hier weil da einfach code anfällig ist für nochmal genau spezifizieren was das überhaupt für ein filetpy eist mit dem adress und port mit string und int
	enet_peer.create_client(address, port, 0, 0, 0, Noray.local_port)
	multiplayer.multiplayer_peer = enet_peer



func nat_connect(address: String, port: int) -> void:
	await PacketHandshake.over_enet_peer(enet_peer, address, port)
	#Handshake heist das wir einfach sicher stellen das hier bei NAT punchtrhough wirklich sicherstellen das beide router offen sind indem wir uns beide diese sachen austauschen,  und das in der klammer ist die adresse wohin wir das schicken sollen. Handshae ist automatisch da muss man nichts machen.
	print("Someone joins throught NAT (direct): ", address, ":", port)


func relay_connect(address: String, port: int) -> void:
	await PacketHandshake.over_enet_peer(enet_peer, address, port)
	# Gleich wie direkt, nur läuft's durch Noray's Server (automatisch)
	print("Someones joining through a relay: ", address, ":", port)

func add_player(peer_id): #soll ne peer id mitnehmen, peer id brauch man zum einen für authority purposes
	var player = tempPlayerScene.instantiate()
	player.name = str(peer_id)
	add_child(player)
	player.global_position = Vector3(0.0, 1.8, 3.0)


func remove_player(peer_id):
	var player = get_node_or_null(str(peer_id))
	if player:
		player.queue_free() #NICHT VERGESSEN
