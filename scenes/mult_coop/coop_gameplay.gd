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
var column_bag := []:
	get:
		if column_bag.is_empty():
			for r in column_ranges:
				for i in range(r[0], r[1]):
					column_bag.append(i)
			seed(MULT_UTILS.mult_rng.randi())
			column_bag.shuffle()
		return column_bag

var spawnables = [
	{ weight = 40, scene = GLOBAL_VARS.object_type.WOOD },
	{ weight = 20, scene = GLOBAL_VARS.object_type.CANNON },
	{ weight = 10, scene = GLOBAL_VARS.object_type.WATER },
	{ weight = 10, scene = GLOBAL_VARS.object_type.HAMMER },
	{ weight = 1, scene = GLOBAL_VARS.object_type.GEM},
	{ weight = 1, scene = GLOBAL_VARS.object_type.BOMB },
]
var spawnables_bag := []:
	get:
		if spawnables_bag.is_empty():
			for s in spawnables:
				for i in range(s.weight):
					spawnables_bag.append(s.scene)
			seed(MULT_UTILS.mult_rng.randi())
			spawnables_bag.shuffle()
		return spawnables_bag

func _ready() -> void:
	multiplayer.peer_disconnected.connect(on_error)
	multiplayer.server_disconnected.connect(on_error)
	
	SyncManager.sync_started.connect(on_sync_start)
	SyncManager.sync_error.connect(on_error)
	SyncManager.sync_lost.connect(on_unsync)
	SyncManager.sync_regained.connect(on_resync)
	SyncManager.sync_stopped.connect(_on_sync_stopped)
	
	raft.generate_initial_platform()
	
	if multiplayer.is_server():
		MULT_UTILS.mult_rng.set_seed(randi())
		MULT_UTILS.sync_rng.rpc(MULT_UTILS.mult_rng.get_seed())
		SyncManager.start()
	
	charge_label.text = str(raft_charges)

func on_sync_start():
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
	sync_status.show()

func on_resync():
	sync_status.hide()

func _on_sync_stopped():
	SyncManager.stop_logging()

func on_error(error):
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
		raft_charges = raft_charges,
	}

func _load_state(state: Dictionary) -> void:
	score = state['score']
	raft_charges = state['raft_charges']


func _on_network_timer_timeout() -> void:
	var spawn_type = spawnables_bag.pop_back()
	var spawn_pos = raft.global_position + Vector2(column_bag.pop_back() * 32, 0)
	SyncManager.spawn("Buoy", buoy_parent, buoy_scene, {pos = spawn_pos, type = spawn_type})
