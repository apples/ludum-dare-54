extends "res://objects/raft_objects/raft_object.gd"

func get_kind() -> StringName:
	return "driftwood"

func _process_unconnected(delta):
	var ball_nbors = match3()
	
	if ball_nbors.size() == 0:
		return
	
	get_tree().get_root().get_node("gameplay").overlay_upgrade_scene()
	GLOBAL_VARS.score += 10
	
	for b in ball_nbors:
		b.queue_free()
