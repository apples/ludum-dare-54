extends Node2D

@onready var players_label = $Label
@onready var public_switch = $CheckButton
@onready var start_button = $StartButton

var mult_select_scene = "res://scenes/mult_select/mult_select.tscn"
var coop_gameplay_scene = "res://scenes/mult_coop/coop_gameplay.tscn"

var player_names = []

func _ready() -> void:
	multiplayer.peer_connected.connect(on_connection)
	multiplayer.peer_disconnected.connect(on_disconnect)
	multiplayer.server_disconnected.connect(on_leave_server)
	multiplayer.connection_failed.connect(on_leave_server)
	
	public_switch.disabled = !MULT_UTILS.is_hosting #should mult sync this for info
	start_button.disabled = !MULT_UTILS.is_hosting
	
	var peer = ENetMultiplayerPeer.new()
	var error = null
	
	if MULT_UTILS.is_hosting:
		error = peer.create_server(MULT_UTILS.port, MULT_UTILS.max_connections)
		if !error:
			update_players_list()
	else:
		error = peer.create_client(MULT_UTILS.ip_target, MULT_UTILS.port)
	
	if error:
		UTILS.change_to_scene(mult_select_scene)
	multiplayer.multiplayer_peer = peer


func on_connection(id):
	update_players_list()
	SyncManager.add_peer(id)

func on_disconnect(id):
	update_players_list()
	SyncManager.remove_peer(id)

func on_leave_server():
	UTILS.change_to_scene(mult_select_scene)
	multiplayer.multiplayer_peer.close()

func update_players_list():
	player_names = []
	player_names.append("SELF")
	player_names.append_array(multiplayer.get_peers())
	var players_string = ""
	for player in player_names:
		if str(player) == "1":
			players_string += "\nHOST"
		elif str(player) == "SELF":
			players_string += "\nSELF"
		else:
			players_string += "\nPLAYER " + str(player)
	players_label.text = "Players:" + players_string
	

func _on_button_pressed() -> void:
	on_leave_server()

func _on_check_button_toggled(toggled_on: bool) -> void:
	MULT_UTILS.is_public = toggled_on

func _on_start_button_pressed() -> void:
	start_game.rpc()

@rpc("authority", "call_local")
func start_game():
	UTILS.change_to_scene(coop_gameplay_scene)
