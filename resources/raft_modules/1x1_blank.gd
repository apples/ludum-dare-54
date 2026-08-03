extends RaftModuleBase

static func get_structure():
	# [x]
	return {
		Vector2i(0, 0): preload("res://singleplayer_objects/raft_tile/raft_tile.tscn"),
#		Vector2i(0, 1): preload("res://singleplayer_objects/raft_tile/raft_tile.tscn"),
#		Vector2i(1, 1): preload("res://singleplayer_objects/raft_tile/raft_tile_cannon.tscn")
	}
