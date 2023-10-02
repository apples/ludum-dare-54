extends "res://objects/raft_objects/raft_object.gd"

var sparkle_scene = preload("res://objects/VFX/sparkle/sparkle.tscn")

func get_kind() -> StringName:
	return "driftwood"

func _process_unconnected(delta):
	var ball_nbors = match3()
	
	if ball_nbors.size() == 0:
		return
	
	get_tree().get_root().get_node("gameplay").overlay_upgrade_scene(ball_nbors.size()-3)
	GLOBAL_VARS.score += 10
	var sparkle_scene_b 
	for b in ball_nbors:
		sparkle_scene_b = sparkle_scene.instantiate()
		sparkle_scene_b.init( Color(1,1,0))
		b.get_parent().add_child(sparkle_scene_b)
		if b == self and ball_nbors.size() >= 4:
			replace_with_gem()
		else:
			b.queue_free()
		
		sparkle_scene_b.play_hammer()
	