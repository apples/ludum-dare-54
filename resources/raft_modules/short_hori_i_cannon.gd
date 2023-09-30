extends RaftModuleBase

static func get_structure():
	# [x, c]
	return {
		Vector2i(0, 0): preload("res://objects/raft_tile/raft_tile.tscn"),
		Vector2i(1, 0): preload("res://objects/raft_tile/raft_tile_cannon.tscn")
	}
