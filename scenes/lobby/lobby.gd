extends Node2D

@onready var public_switch = $CheckButton
@onready var start_button = $StartButton
@onready var team1_container = $HBoxContainer/Team1
@onready var team2_container = $HBoxContainer/Team2
@onready var team1_button = $Header/Team1Button
@onready var team2_button = $Header/Team2Button
@onready var team1_label = $Header/Label
@onready var team2_label = $Header/Label2

var mult_select_scene = "res://scenes/mult_select/mult_select.tscn"
var coop_gameplay_scene = "res://scenes/mult_coop/coop_gameplay.tscn"
var versus_gameplay_scene = "res://scenes/mult_versus/versus_gameplay.tscn"

var lobby_player_scene = preload("res://misc_objects/lobby_player/lobby_player.tscn")

var team1_players = []
var team2_players = []


func _ready() -> void:
	multiplayer.peer_connected.connect(on_connection)
	multiplayer.peer_disconnected.connect(on_disconnect)
	multiplayer.server_disconnected.connect(on_leave_server)
	multiplayer.connection_failed.connect(on_leave_server)
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	MULT_UTILS.lobby_peer_ready.connect(_on_lobby_peer_ready)

	if MULT_UTILS.is_hosting:
		MULT_UTILS.clear_lobby_ready()
		MULT_UTILS.clear_teams()

	public_switch.disabled = !MULT_UTILS.is_hosting #should mult sync this for info
	start_button.disabled = true
	_update_team_ui_visibility()

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
		team1_players.append(multiplayer.get_unique_id())
		sync_teams.rpc(team1_players, team2_players)
		_update_start_button()


func _on_connected_to_server() -> void:
	MULT_UTILS.notify_lobby_ready()

func _on_lobby_peer_ready(_peer_id: int) -> void:
	_update_start_button()


func on_connection(id):
	SyncManager.add_peer(id)
	_update_start_button()
	if MULT_UTILS.is_hosting:
		if MULT_UTILS.is_coop or team1_players.size() <= team2_players.size():
			team1_players.append(id)
		else:
			team2_players.append(id)
		sync_teams.rpc(team1_players, team2_players)

func on_disconnect(id):
	SyncManager.remove_peer(id)
	MULT_UTILS.lobby_ready_peers.erase(id)
	_update_start_button()
	if MULT_UTILS.is_hosting:
		team1_players.erase(id)
		team2_players.erase(id)
		sync_teams.rpc(team1_players, team2_players)


func _all_peers_lobby_ready() -> bool:
	for peer_id in multiplayer.get_peers():
		if not MULT_UTILS.lobby_ready_peers.has(peer_id):
			return false
	return true


func _update_start_button() -> void:
	start_button.disabled = not MULT_UTILS.is_hosting or not _all_peers_lobby_ready()

func on_leave_server():
	multiplayer.multiplayer_peer.close()
	MULT_UTILS.clear_teams()
	UTILS.change_to_scene(mult_select_scene)

func _update_team_ui_visibility() -> void:
	if MULT_UTILS.is_coop:
		team1_button.hide()
		team2_button.hide()
		team2_label.hide()
		team2_container.hide()
		team1_label.text = "Players:"


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
	if MULT_UTILS.is_coop:
		UTILS.change_to_scene(coop_gameplay_scene)
	else:
		UTILS.change_to_scene(versus_gameplay_scene)

func _on_team_1_button_pressed() -> void:
	_request_join_team(0)

func _on_team_2_button_pressed() -> void:
	_request_join_team(1)

func _request_join_team(team: int) -> void:
	if MULT_UTILS.is_hosting:
		_move_peer_to_team(multiplayer.get_unique_id(), team)
	else:
		server_request_join_team.rpc_id(1, team)


@rpc("any_peer", "call_remote", "reliable")
func server_request_join_team(team: int) -> void:
	if not multiplayer.is_server():
		return
	_move_peer_to_team(multiplayer.get_remote_sender_id(), team)


func _move_peer_to_team(peer_id: int, team: int) -> void:
	if not team1_players.has(peer_id) and not team2_players.has(peer_id):
		return # not in the lobby
	team1_players.erase(peer_id)
	team2_players.erase(peer_id)
	if team == 0:
		team1_players.append(peer_id)
	else:
		team2_players.append(peer_id)
	sync_teams.rpc(team1_players, team2_players)


func _on_lobby_player_kick_requested(peer_id: int) -> void:
	if peer_id == multiplayer.get_unique_id():
		return
	if MULT_UTILS.is_hosting:
		_do_kick(peer_id)
	else:
		server_kick_peer.rpc_id(1, peer_id)


@rpc("any_peer", "call_remote", "reliable")
func server_kick_peer(peer_id: int) -> void:
	if not multiplayer.is_server():
		return
	if multiplayer.get_remote_sender_id() != peer_id:
		return
	_do_kick(peer_id)


func _do_kick(peer_id: int) -> void:
	if not multiplayer.is_server() or peer_id == 1:
		return
	notify_kicked.rpc_id(peer_id)
	multiplayer.multiplayer_peer.disconnect_peer(peer_id)


@rpc("authority", "call_remote", "reliable")
func notify_kicked() -> void:
	on_leave_server()


@rpc("authority", "call_local", "reliable")
func sync_teams(team1, team2):
	update_teams(team1, team2)

func update_teams(team1, team2):
	team1_players = team1
	team2_players = team2
	# keep the autoload in sync so the gameplay scenes can read the teams
	MULT_UTILS.team1_players = team1
	MULT_UTILS.team2_players = team2

	var team1_children := team1_container.get_children()
	var team2_children := team2_container.get_children()
	for p in team1_players:
		if not team1_children.any(func(node): return not node.is_queued_for_deletion() and node.peer_id == p):
			var player_node = lobby_player_scene.instantiate()
			player_node.peer_id = p
			player_node.kick_requested.connect(_on_lobby_player_kick_requested)
			team1_container.add_child(player_node)
			player_node.update_info()
	for p in team2_players:
		if not team2_children.any(func(node): return not node.is_queued_for_deletion() and node.peer_id == p):
			var player_node = lobby_player_scene.instantiate()
			player_node.peer_id = p
			player_node.kick_requested.connect(_on_lobby_player_kick_requested)
			team2_container.add_child(player_node)
			player_node.update_info()

	team1_children = team1_container.get_children()
	team2_children = team2_container.get_children()
	for p in team1_children:
		if not team1_players.any(func(id): return p.peer_id == id):
			p.queue_free()
	for p in team2_children:
		if not team2_players.any(func(id): return p.peer_id == id):
			p.queue_free()
