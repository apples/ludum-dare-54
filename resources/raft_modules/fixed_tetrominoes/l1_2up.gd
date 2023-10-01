extends RaftModuleBase

static func get_structure():
	# [x, _]
	# [x, c]
	return {
		Vector2i(-1, -1): random_tile(),
		Vector2i(0, -1): base_tile(),
		#Vector2i(1, -1): base_tile(),
		#Vector2i(-1, 0): base_tile(),
		Vector2i(0, 0): random_tile(),
		#Vector2i(1, 0): base_tile(),
		#Vector2i(-1, 1): base_tile(),
		Vector2i(0, 1): base_tile(),
		#Vector2i(1, 1): base_tile(),
	}
