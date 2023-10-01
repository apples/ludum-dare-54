extends "res://objects/raft_objects/raft_object.gd"

var raft_tile_scene = preload("res://objects/raft_tile/raft_tile.tscn")

func get_kind() -> StringName:
	return "water_bucket"

func _process_unconnected(delta):
	var ball_nbors = match3()
	
	if ball_nbors.size() == 0:
		return
	
	GLOBAL_VARS.score += 10
	
	for b in ball_nbors:
		for i in self.raft.get_tile_row(b.grid_pos.y):
			if(i.tile_object.get_kind() == "fire"):
				self.raft.swap_tile(raft_tile_scene, b.grid_pos.y, i.column_index)
		for i in self.raft.get_tile_column(b.grid_pos.x):
			if(i.tile_object.get_kind() == "fire"):
				self.raft.swap_tile(raft_tile_scene, i.row_index, b.grid_pos.x,)
		b.queue_free()
