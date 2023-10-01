extends "res://objects/raft_objects/raft_object.gd"

func get_kind() -> StringName:
	return "gem"

func _process_unconnected(delta):
	var ball_nbors = match3()
	
	if ball_nbors.size() == 0:
		return
	
	GLOBAL_VARS.score += 25
	
	for b in ball_nbors:
		b.queue_free()
