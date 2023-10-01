extends Resource
class_name RaftModuleBase

static func random_tile():
	return [
		preload("res://objects/raft_tile/raft_tile.tscn"),
		preload("res://objects/raft_tile/raft_tile_driftwood.tscn"),
		preload("res://objects/raft_tile/raft_tile_water_bucket.tscn")
	][randi() % 3]

static func base_tile():
	return preload("res://objects/raft_tile/raft_tile.tscn")

static func get_structure():
	return {}
