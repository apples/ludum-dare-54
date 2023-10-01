extends "res://objects/raft_objects/raft_object.gd"

func get_kind() -> StringName:
	return "cannon_ball"

func _process_unconnected(delta):
	var ball_nbors = find_neighboring_objects("cannon_ball")
	
	if ball_nbors.size() < 2:
		return
	
	var i = 0;
	while i < ball_nbors.size():
		for o in ball_nbors[i].find_neighboring_objects("cannon_ball"):
			if not o in ball_nbors:
				ball_nbors.append(o)
		i += 1
	
	for b in ball_nbors:
		b.queue_free()
	
	queue_free()
