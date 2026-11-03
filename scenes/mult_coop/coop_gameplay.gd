extends Node2D

var mult_select_scene = "res://scenes/mult_select/mult_select.tscn"
var player_scene = preload("res://coop_objects/player/player.tscn")
var buoy_scene = preload("res://coop_objects/buoy/buoy.tscn")

@onready var sync_status = $SyncStatus
@onready var disconnect_notice = $DisconnectMessage
@onready var disconnect_timer = $DisconnectMessage/DisconnectTimer

@onready var raft = $Raft
@onready var buoy_parent = $BuoyParent

@onready var score_label := $Score
@onready var charge_label := $Charges

@onready var buoy_timer = $NetworkTimer
const base_timer_ticks = 180
const CLIENT_LOAD_TIMEOUT := 15.0
var boost_mult = 1

var _scene_ready := false
var _start_failed := false
var _sync_start_timer: SceneTreeTimer
var _start_requested := false

var score = 0:
	set(x):
		score = x
		score_label.text = str(score)
var raft_charges = 1:
	set(x):
		raft_charges = x
		charge_label.text = str(raft_charges)
var placed_tile_coords = []

var column_ranges := [[1, 16], [5, 12], [7, 10]]
var column_bag := []

var spawnables = [
	{ weight = 40, scene = GLOBAL_VARS.object_type.WOOD },
	{ weight = 20, scene = GLOBAL_VARS.object_type.CANNON },
	{ weight = 10, scene = GLOBAL_VARS.object_type.WATER },
	{ weight = 10, scene = GLOBAL_VARS.object_type.HAMMER },
	{ weight = 1, scene = GLOBAL_VARS.object_type.GEM},
	{ weight = 1, scene = GLOBAL_VARS.object_type.BOMB },
]
var spawnables_bag := []

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
	
	
	charge_label.text = str(raft_charges)
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
	raft.generate_initial_platform()
	
	var mult_ids = []
	mult_ids.append(multiplayer.get_unique_id())
	mult_ids.append_array(multiplayer.get_peers())
	mult_ids.sort()
	
	var player : CoopPlayer
	var initial_pos = Vector2i(10, 8)
	for peer in mult_ids:
		player = SyncManager.spawn("Player" + str(peer), self, player_scene, {grid_pos = initial_pos})
		initial_pos += Vector2i.LEFT
		player.set_multiplayer_authority(peer)
		raft.players.append(player)
	
	if multiplayer.is_server():
		SyncManager.start_logging("user://detailed_logs/Horse1.log")
	else:
		SyncManager.start_logging("user://detailed_logs/Horse2.log")

func on_unsync():
	print("SYNC LOST")
	sync_status.show()

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

func _save_state() -> Dictionary:
	return {
		score = score,
		boost_mult = boost_mult,
		raft_charges = raft_charges,
		column_bag = column_bag.duplicate(),
		spawnables_bag = spawnables_bag.duplicate(),
	}

func _load_state(state: Dictionary) -> void:
	score = state['score']
	boost_mult = state['boost_mult']
	raft_charges = state['raft_charges']
	column_bag = state['column_bag'].duplicate()
	spawnables_bag = state['spawnables_bag'].duplicate()

func fill_column_bag():
	for r in column_ranges:
		for i in range(r[0], r[1]):
			column_bag.append(i)
	seed(MULT_UTILS.mult_rng.randi())
	column_bag.shuffle()

func fill_spawnables_bag():
	for s in spawnables:
		for i in range(s.weight):
			spawnables_bag.append(s.scene)
	seed(MULT_UTILS.mult_rng.randi())
	spawnables_bag.shuffle()

func change_speed(amount):
	boost_mult = maxi(boost_mult + amount, 1)
	
	var new_wait: int = base_timer_ticks / boost_mult
	SyncManager.set_synced(buoy_timer, "ticks_left", maxi((buoy_timer.ticks_left * new_wait) / buoy_timer.wait_ticks, 1))
	SyncManager.set_synced(buoy_timer, "wait_ticks", new_wait)

func _on_network_timer_timeout() -> void:
	if column_bag.is_empty():
		fill_column_bag()
	if spawnables_bag.is_empty():
		fill_spawnables_bag()
	var spawn_type = spawnables_bag.pop_back()
	var spawn_pos = raft.global_position + Vector2(column_bag.pop_back() * 32, 0)
	SyncManager.spawn("Buoy", buoy_parent, buoy_scene, {pos = spawn_pos, type = spawn_type})
