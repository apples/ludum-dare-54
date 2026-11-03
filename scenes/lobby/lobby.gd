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
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	MULT_UTILS.lobby_peer_ready.connect(_on_lobby_peer_ready)
	
	if MULT_UTILS.is_hosting:
		MULT_UTILS.clear_lobby_ready()
	
	public_switch.disabled = !MULT_UTILS.is_hosting #should mult sync this for info
	start_button.disabled = true
	
	var peer = ENetMultiplayerPeer.new()
	var error = null
	
	if MULT_UTILS.is_hosting:
		error = peer.create_server(MULT_UTILS.port, MULT_UTILS.max_connections)
	else:
		error = peer.create_client(MULT_UTILS.ip_target, MULT_UTILS.port)
	
	if error:
		UTILS.change_to_scene(mult_select_scene)
		return
	
	multiplayer.multiplayer_peer = peer
	
	if MULT_UTILS.is_hosting:
		update_players_list()
		_update_start_button()


func _on_connected_to_server() -> void:
	MULT_UTILS.notify_lobby_ready()

func _on_lobby_peer_ready(_peer_id: int) -> void:
	_update_start_button()


func on_connection(id):
	update_players_list()
	SyncManager.add_peer(id)
	_update_start_button()

func on_disconnect(id):
	update_players_list()
	SyncManager.remove_peer(id)
	MULT_UTILS.lobby_ready_peers.erase(id)
	_update_start_button()


func _all_peers_lobby_ready() -> bool:
	for peer_id in multiplayer.get_peers():
		if not MULT_UTILS.lobby_ready_peers.has(peer_id):
			return false
	return true


func _update_start_button() -> void:
	start_button.disabled = not MULT_UTILS.is_hosting or not _all_peers_lobby_ready()

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
	if not MULT_UTILS.is_hosting or not _all_peers_lobby_ready():
		return
	MULT_UTILS.clear_gameplay_ready()
	start_game.rpc()

@rpc("authority", "call_local", "reliable")
func start_game():
	UTILS.change_to_scene(coop_gameplay_scene)
