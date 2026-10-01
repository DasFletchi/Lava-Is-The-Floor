extends Node3D

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

@onready var plattform_spawner_manager: Node = $PlattformSpawnerManager


var plattform


@export var plattform_amount: int  = 50

@export var max_x = 50
@export var max_y = 50
@export var max_z = 50

@export var min_x = 0
@export var min_y = -5
@export var min_z = 0


func _ready() -> void:
	await Noray.connect_to_host(NORAY_HOST, NORAY_PORT) # await heist "warte hier und geh erst weider wenn das nach dir fertig ist"
	print ("connected to relay")




func _unhandled_input(event: InputEvent) -> void:
	if Input.is_action_just_pressed("quit"):
		get_tree().quit()
		add_player(multiplayer.get_unique_id()) #das unique id ding generiert dann eben diese peeer id und packt sie dann direkt mit rein, weil wir ja unten gesgat haben wir wollen die peer id haben könnte man das glaube ich nicht einfach so dahinschreiben


func _on_host_pressed() -> void:
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

	makes_random_number_and_sends()

	print("My seed is (host): ", rng.seed)

	spawn_plattforms()
	print("spawn_plattforms() is called")

func _on_join_pressed() -> void:
	var host_oid = adress_entry.text.strip_edges() # Holt die eingegebene Host-OID und entfernt versehentliche Leerzeichen vorne/hinten.
	if host_oid.is_empty(): # Wenn gar nichts eingegeben wurde, soll Join nicht starten.
		push_error("Please first insert ur OID") # Zeigt im Debugger eine klare Fehlermeldung statt später komisch zu crashen.
		return # Bricht Join hier ab, weil ohne OID kein Host gefunden werden kann.

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
	add_child(player) #verwirrend weil der var name hier temp player ist aber mit dem instanciaten laden wir das rein und die player node heist ja an sich player und das ist das was wir dareinpassenmüssen


func remove_player(peer_id):
	var player = get_node_or_null(str(peer_id))
	if player:
		player.queue_free() #NICHT VERGESSEN



func makes_random_number_and_sends():
	if multiplayer.is_server():
		rng.seed = randi() % 100 #makes a random number between 0-100
		seed_value = rng.seed #nur für uns lopkal da wir ja beim @rpc darunter gesagt haben wir schicken uns nicht selber
		receive_seed.rpc(seed_value) #SO, SCHNUCKIS/ALLE ANDEREN PEERS: IHR FÜHRT JETZT receive_seed(seed_value) AUS.


@rpc("authority", "call_remote", "reliable") #authority = who may send this rpc, call_remote means im not sending that shi to myself if im the host and reliable means we using TCP so we dont get packet loss and the seed arrives with a 100% chance
func receive_seed(seed_value):
	rng.seed = seed_value
	print("My seed is (joiner): ", rng.seed)

func _on_peer_connected(peer_id: int):
	if multiplayer.is_server(): 
		receive_seed.rpc_id(peer_id, seed_value) #same as at the top just witht he rpc id between that so we only send it TO THAT RPC ID


# == HILL GENERATING ==
func generate_plattform():
	var x = rng.randi_range(min_x, max_x)
	var y = rng.randi_range(min_y, max_y)
	var z = rng.randi_range(min_z, max_z)

	var chosen_plattform = rng.randi_range(1, number_of_plattforms_in_the_script)

	var plattform_scene
	
	if chosen_plattform == 1:
		plattform_scene = spinning_block.instantiate()
	elif chosen_plattform == 2:
		plattform_scene = moving_block.instantiate()
	elif chosen_plattform == 3:
		plattform_scene = moving_spinning_block.instantiate()
	elif chosen_plattform == 4:
		plattform_scene = large_moving_block.instantiate()
	elif chosen_plattform == 5:
		plattform_scene = fast_spinning_block.instantiate()
	elif chosen_plattform == 6:
		plattform_scene = vertical_moving_block.instantiate()

	plattform_scene.position = Vector3(x, y, z)
	plattform_scene.name = "Platform_" + str(plattform_amount)
	plattform_spawner_manager.add_child(plattform_scene)



func spawn_plattforms():
	if plattform_amount > 0:
		generate_plattform()
		plattform_amount -= 1
		print("generate_plattform() called plattform_amount -1. Left: ", plattform_amount)
		spawn_plattforms()
