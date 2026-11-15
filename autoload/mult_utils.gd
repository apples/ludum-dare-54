extends Node

@onready var mult_rng : NetworkRandomNumberGenerator = $NetworkRandomNumberGenerator

var is_hosting := false
var is_coop := true

var is_public := false

var mult_name := ""

# peer ids on each raft (team 0 -> raft1, team 1 -> raft2 in versus, everyone on team 1 in coop)
var team1_players: Array = []
var team2_players: Array = []

var ip_target := "127.0.0.1"
const port := 12702
const max_connections = 8

const DETAILED_LOGS_DIR := "user://detailed_logs"

func get_log_path(base_name: String) -> String:
	DirAccess.make_dir_recursive_absolute(DETAILED_LOGS_DIR)
	var d := Time.get_datetime_dict_from_system()
	var timestamp := "%04d-%02d-%02d_%02d-%02d-%02d" % [d.year, d.month, d.day, d.hour, d.minute, d.second]
	return "%s/%s_%s.log" % [DETAILED_LOGS_DIR, base_name, timestamp]

signal lobby_peer_ready (peer_id)
signal gameplay_peer_ready (peer_id)

var lobby_ready_peers := {}
var gameplay_ready_peers := {}

func clear_lobby_ready() -> void:
	lobby_ready_peers.clear()

func clear_teams() -> void:
	team1_players = []
	team2_players = []

func get_team_of_peer(peer_id: int) -> int:
	return 1 if team2_players.has(peer_id) else 0

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


# --- Latency probing --------------------------------------------------------
# Measures the RTT to each peer while connected but before sync starts, so the
# match can size rollback input_delay to the real network instead of a fixed
# guess. Each machine measures its own RTT; input_delay is a local-only
# setting, so per-peer asymmetry is fine.

const LATENCY_PROBE_INTERVAL := 0.25
const LATENCY_EWMA_ALPHA := 0.25

var _peer_rtt_msec := {}
var _probe_timer := 0.0

func get_measured_rtt_msec() -> int:
	var worst := 0
	for rtt in _peer_rtt_msec.values():
		worst = maxi(worst, rtt)
	return worst

func clear_rtt_measurements() -> void:
	_peer_rtt_msec.clear()

func _ready() -> void:
	multiplayer.peer_disconnected.connect(_on_probe_peer_disconnected)

func _on_probe_peer_disconnected(peer_id: int) -> void:
	_peer_rtt_msec.erase(peer_id)

func _process(delta: float) -> void:
	_probe_timer += delta
	if _probe_timer < LATENCY_PROBE_INTERVAL:
		return
	_probe_timer = 0.0
	_probe_peers()

func _probe_peers() -> void:
	if multiplayer.multiplayer_peer == null:
		return
	if multiplayer.multiplayer_peer.get_connection_status() != MultiplayerPeer.CONNECTION_CONNECTED:
		return
	if SyncManager.started:
		return # SyncManager runs its own pings during a match
	for peer_id in multiplayer.get_peers():
		_latency_probe_ping.rpc_id(peer_id, Time.get_ticks_msec())

@rpc("any_peer", "call_remote", "reliable")
func _latency_probe_ping(sent_msec: int) -> void:
	_latency_probe_pong.rpc_id(multiplayer.get_remote_sender_id(), sent_msec)

@rpc("any_peer", "call_remote", "reliable")
func _latency_probe_pong(sent_msec: int) -> void:
	var peer_id := multiplayer.get_remote_sender_id()
	var sample := maxi(Time.get_ticks_msec() - sent_msec, 1)
	if _peer_rtt_msec.has(peer_id):
		_peer_rtt_msec[peer_id] = int(round(lerpf(float(_peer_rtt_msec[peer_id]), float(sample), LATENCY_EWMA_ALPHA)))
	else:
		_peer_rtt_msec[peer_id] = sample
