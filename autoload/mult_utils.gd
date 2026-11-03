extends Node

@onready var mult_rng : NetworkRandomNumberGenerator = $NetworkRandomNumberGenerator

var is_hosting := false
var is_coop := true

var is_public := false

var mult_name := ""

var ip_target := "127.0.0.1"
const port := 12702
const max_connections = 8


signal lobby_peer_ready (peer_id)
signal gameplay_peer_ready (peer_id)

var lobby_ready_peers := {}
var gameplay_ready_peers := {}

func clear_lobby_ready() -> void:
	lobby_ready_peers.clear()

func clear_gameplay_ready() -> void:
	gameplay_ready_peers.clear()

func notify_lobby_ready() -> void:
	_client_lobby_ready.rpc_id(1)

func notify_gameplay_ready() -> void:
	_client_gameplay_ready.rpc_id(1)

@rpc("any_peer", "call_remote", "reliable")
func _client_lobby_ready() -> void:
	if not multiplayer.is_server():
		return
	var peer_id = multiplayer.get_remote_sender_id()
	lobby_ready_peers[peer_id] = true
	lobby_peer_ready.emit(peer_id)

@rpc("any_peer", "call_remote", "reliable")
func _client_gameplay_ready() -> void:
	if not multiplayer.is_server():
		return
	var peer_id = multiplayer.get_remote_sender_id()
	gameplay_ready_peers[peer_id] = true
	gameplay_peer_ready.emit(peer_id)


@rpc("authority", "call_remote", "reliable")
func sync_rng(new_seed):
	mult_rng.set_seed(new_seed)
