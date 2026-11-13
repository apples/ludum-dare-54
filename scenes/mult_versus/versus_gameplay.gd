extends Node2D

var mult_select_scene = "res://scenes/mult_select/mult_select.tscn"
var player_scene = preload("res://versus_objects/player/player.tscn")

@onready var sync_status = $SyncStatus
@onready var disconnect_notice = $DisconnectMessage
@onready var disconnect_timer = $DisconnectMessage/DisconnectTimer

@onready var raft1 := $Raft1
@onready var raft2 := $Raft2
@onready var rafts := [raft1, raft2]
@onready var buoy_parent = $BuoyParent

@onready var score_label := $Score
@onready var charge_labels := [$ChargeLabel1, $ChargeLabel2]

const CLIENT_LOAD_TIMEOUT := 15.0

var _scene_ready := false
var _start_failed := false
var _sync_start_timer: SceneTreeTimer
var _start_requested := false
var _game_over := false

var score = 0:
	set(x):
		score = x
		score_label.text = str(score)

var raft_charges : Array[int] = [1, 1]
var placed_tile_coords = []

var buoys : Array[Node2D] = []

func add_charges(raft_index: int, amount: int) -> void:
	raft_charges[raft_index] = maxi(raft_charges[raft_index] + amount, 0)
	_update_charge_labels(raft_index)

func spend_charge(raft_index: int) -> bool:
	if raft_charges[raft_index] <= 0:
		return false
	raft_charges[raft_index] -= 1
	_update_charge_labels(raft_index)
	return true

func _update_charge_labels(raft_index: int) -> void:
	charge_labels[raft_index].text = str(raft_charges[raft_index])

func _ready() -> void:
	multiplayer.peer_disconnected.connect(on_error)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	multiplayer.server_disconnected.connect(on_error)
	
	SyncManager.sync_started.connect(on_sync_start)
	SyncManager.sync_error.connect(on_error)
	SyncManager.sync_lost.connect(on_unsync)
	SyncManager.sync_regained.connect(on_resync)
	SyncManager.sync_stopped.connect(_on_sync_stopped)
	MULT_UTILS.gameplay_peer_ready.connect(_on_gameplay_peer_ready)
	
	raft1.opponent = raft2
	raft2.opponent = raft1
	
	_update_charge_labels(0)
	_update_charge_labels(1)
	_scene_ready = true
	
	if multiplayer.is_server():
		_try_start_sync()
	else:
		MULT_UTILS.notify_gameplay_ready()

func _on_gameplay_peer_ready(_peer_id: int) -> void:
	_try_start_sync()

func _try_start_sync() -> void:
	if _start_failed or _start_requested or not _scene_ready \
			or not multiplayer.is_server() or SyncManager.started:
		return
	
	for peer_id in multiplayer.get_peers():
		if not MULT_UTILS.gameplay_ready_peers.has(peer_id):
			if _sync_start_timer == null:
				_sync_start_timer = get_tree().create_timer(CLIENT_LOAD_TIMEOUT)
				_sync_start_timer.timeout.connect(_on_sync_start_timeout)
			return
	
	# everyone's loaded
	_start_requested = true
	_sync_start_timer = null
	MULT_UTILS.mult_rng.set_seed(randi())
	MULT_UTILS.sync_rng.rpc(MULT_UTILS.mult_rng.get_seed())
	SyncManager.start()

func _on_sync_start_timeout() -> void:
	_sync_start_timer = null
	if _start_failed or _start_requested or SyncManager.started:
		return
	
	for peer_id in multiplayer.get_peers():
		if not MULT_UTILS.gameplay_ready_peers.has(peer_id):
			_start_failed = true
			on_error("Timed out waiting for all players to finish loading")
			return

func _on_peer_disconnected(peer_id: int) -> void:
	MULT_UTILS.gameplay_ready_peers.erase(peer_id)

func on_sync_start():
	raft1.generate_initial_platform(Vector2(4, 8))
	raft2.generate_initial_platform(Vector2(3, 8))
	
	var mult_ids = []
	mult_ids.append(multiplayer.get_unique_id())
	mult_ids.append_array(multiplayer.get_peers())
	mult_ids.sort()
	
	var use_teams = not (MULT_UTILS.team1_players.is_empty() and MULT_UTILS.team2_players.is_empty())
	var per_raft_slots = {raft1: 0, raft2: 0}
	var player : VersusPlayer
	for i in range(mult_ids.size()):
		var peer = mult_ids[i]
		var raft_node
		if use_teams:
			raft_node = raft1 if MULT_UTILS.team1_players.has(peer) else raft2
		else:
			raft_node = raft1 if i % 2 == 0 else raft2
		var initial_pos = raft_node.get_upper_left_tile().grid_pos + Vector2i(per_raft_slots[raft_node], 0) # works up to 5 players per raft
		per_raft_slots[raft_node] += 1
		player = SyncManager.spawn("Player" + str(peer), self, player_scene, {grid_pos = initial_pos, raft_path = raft_node.get_path()})
		player.set_multiplayer_authority(peer)
		raft_node.players.append(player)
	
	if multiplayer.is_server():
		SyncManager.start_logging("user://detailed_logs/ServerLog.log")
	else:
		SyncManager.start_logging("user://detailed_logs/ClientLog.log")

func on_unsync():
	print("SYNC LOST")
	sync_status.show()

func end_game(loser_raft_index: int) -> void:
	if _game_over:
		return
	_game_over = true
	GLOBAL_VARS.score = score
	
	if _get_local_raft_index() == loser_raft_index:
		UTILS.change_to_scene("res://scenes/lose_screen/lose_scene.tscn")
	else:
		UTILS.change_to_scene("res://scenes/win_scene/win_scene.tscn")

func _get_local_raft_index() -> int:
	for i in range(2):
		for player in rafts[i].players:
			if player.is_multiplayer_authority():
				return i
	return 0

func on_resync():
	sync_status.hide()

func _on_sync_stopped():
	print("SYNC STOPPED")
	SyncManager.stop_logging()

func on_error(error = null):
	print("SYNC ERROR:")
	print(error)
	disconnect_notice.show()
	disconnect_timer.start()

func _on_disconnect_timer_timeout() -> void:
	SyncManager.stop()
	multiplayer.multiplayer_peer.close()
	SyncManager.clear_peers()
	UTILS.change_to_scene(mult_select_scene)

func get_buoy_in_range(coord: Vector2, height: int) -> Node2D:
	for buoy in buoys:
		@warning_ignore("integer_division")
		if buoy.position.x == coord.x and buoy.position.y < coord.y + (height / 2) and buoy.position.y > coord.y - (height / 2):
			return buoy
	return null

func _save_state() -> Dictionary:
	var buoy_paths := []
	for buoy in buoys:
		if is_instance_valid(buoy):
			buoy_paths.append(buoy.get_path())
	
	return {
		score = score,
		raft_charges = raft_charges.duplicate(),
		buoy_paths = buoy_paths,
	}

func _load_state(state: Dictionary) -> void:
	score = state['score']
	raft_charges = state['raft_charges'].duplicate()
	_update_charge_labels(0)
	_update_charge_labels(1)
	
	buoys.clear()
	for buoy_path in state['buoy_paths']:
		var buoy := get_node_or_null(buoy_path)
		if buoy:
			buoys.append(buoy)
