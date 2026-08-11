extends Node2D

var mult_select_scene = "res://scenes/mult_select/mult_select.tscn"
var player_scene = preload("res://coop_objects/player/player.tscn")

@onready var sync_status = $SyncStatus
@onready var disconnect_notice = $DisconnectMessage
@onready var disconnect_timer = $DisconnectMessage/DisconnectTimer

@onready var raft = $Raft

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

func on_sync_start():
	var mult_ids = []
	mult_ids.append(multiplayer.get_unique_id())
	mult_ids.append_array(multiplayer.get_peers())
	mult_ids.sort()
	
	var player : CoopPlayer
	var initial_pos = Vector2i(11, 8)
	for peer in mult_ids:
		player = SyncManager.spawn("Player" + str(peer), self, player_scene, {grid_pos = initial_pos})
		initial_pos += Vector2i.LEFT
		player.set_multiplayer_authority(peer)
		player.raft = raft
	
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
