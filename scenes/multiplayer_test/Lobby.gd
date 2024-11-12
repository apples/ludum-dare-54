extends Node2D

# These signals can be connected to by a UI lobby scene or the game scene.
signal player_connected(peer_id, player_info)
signal player_disconnected(peer_id)
signal server_disconnected

const PORT = 12702#7000
#const DEFAULT_SERVER_IP = "127.0.0.1" # IPv4 localhost
const MAX_CONNECTIONS = 20

var players = {}

@export var player_spawner: MultiplayerSpawner
@export var gameplay: Node2D

@onready var sync_lost_label = $"../SyncLabel"
@onready var player_parent = $"../PlayerParent"
#var players_loaded = 0
const multPlayerScene = preload("res://objects/mult_character/mult_character.tscn")

func _ready():
	multiplayer.peer_connected.connect(_on_player_connected)
	multiplayer.peer_disconnected.connect(_on_player_disconnected)
	#multiplayer.connected_to_server.connect(_on_connected_ok)
	#multiplayer.connection_failed.connect(_on_connected_fail)
	multiplayer.server_disconnected.connect(_on_server_disconnected)
	
	SyncManager.sync_started.connect(_on_SyncManager_sync_started)
	
	SyncManager.sync_error.connect(_on_SyncManager_sync_error)
	SyncManager.sync_lost.connect(_on_SyncManager_sync_lost)
	SyncManager.sync_regained.connect(_on_SyncManager_sync_regained)
	SyncManager.sync_stopped.connect(_on_sync_stopped)


func join_game(address = ""):
	print("CLIENTING")
	if address.is_empty():
		address = MULT_UTILS.ip_target
	var peer = ENetMultiplayerPeer.new()
	var error = peer.create_client(address, PORT)
	if error:
		return error
	multiplayer.multiplayer_peer = peer


func create_game():
	print("HOSTING")
	var peer = ENetMultiplayerPeer.new()
	var error = peer.create_server(PORT, MAX_CONNECTIONS)
	if error:
		return error
	multiplayer.multiplayer_peer = peer
	#var player = player_spawner.spawn({ id = multiplayer.get_unique_id() }) THIS ONE IS REAL
	
	# z index?
	#player.game_world = get_parent()
	#$"../player_raft".players.append(player)
	#players[multiplayer.get_unique_id()] = player



func _on_player_connected(id):
	print("Connected!")
	print("ID: " + str(id))
	sync_lost_label.text = "Starting sync..."
	sync_lost_label.visible = true
	SyncManager.add_peer(id)
	if id != 1:
		#var player = player_spawner.spawn({ id = id }) THIS ONE IS REAL
		
		# Give a little time to get ping data.
		await get_tree().create_timer(2.0).timeout
		SyncManager.start()
	#var player = player_spawner.spawn({ id = id })
	#players[id] = player
	#player_spawned.emit(player)


func _on_player_disconnected(id):
	players[id].queue_free()
	players.erase(id)
	player_disconnected.emit(id)


func _on_server_disconnected():
	get_tree().reload_current_scene()
	server_disconnected.emit()

func _on_SyncManager_sync_started():
	
	
	sync_lost_label.visible = false
	var player1 = SyncManager.spawn("Player1", player_parent, multPlayerScene, {id = 1})
	player1.set_multiplayer_authority(1)
	$"../player_raft".players.append(player1)
	players[1] = player1
	
	if multiplayer.get_unique_id() == 1: #TODO: UPDATE FOR 3+ PLAYERS
		SyncManager.start_logging("user://detailed_logs/Horse1.log")
		var tempId = SyncManager.get_player_peer_ids()[0]
		var player2 = SyncManager.spawn("Player" + str(tempId), player_parent, multPlayerScene, {id = tempId})
		player2.set_multiplayer_authority(tempId)
		$"../player_raft".players.append(player2)
		players[tempId] = player2
	else:
		SyncManager.start_logging("user://detailed_logs/Horse2.log")
		var tempId = multiplayer.get_unique_id()
		var player2 = SyncManager.spawn("Player" + str(tempId), player_parent, multPlayerScene, {id = tempId})
		player2.set_multiplayer_authority(tempId)
		$"../player_raft".players.append(player2)
		players[tempId] = player2
	
	#gameplay.start_game()

func _on_SyncManager_sync_lost() -> void:
	sync_lost_label.text = "Regaining sync..."
	sync_lost_label.visible = true

func _on_SyncManager_sync_regained() -> void:
	sync_lost_label.visible = false

func _on_SyncManager_sync_error(msg: String) -> void:
	sync_lost_label.text = "Fatal sync error: " + msg
	sync_lost_label.visible = true

func _on_sync_stopped():
	SyncManager.stop_logging()
