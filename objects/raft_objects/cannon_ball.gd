extends "res://objects/raft_objects/raft_object.gd"

func get_kind() -> StringName:
	return "cannon_ball"

func _process_unconnected(_delta):
	var ball_nbors = match3()
	
	if ball_nbors.size() == 0:
		return
	
	for tile in ball_nbors:
		tile.tile_object.queue_free()
