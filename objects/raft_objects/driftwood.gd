extends "res://objects/raft_objects/raft_object.gd"

var sparkle_scene = preload("res://objects/VFX/sparkle/sparkle.tscn")

func get_kind() -> StringName:
	return "driftwood"

func _process_unconnected(_delta):
	var ball_nbors = match3()
	
	if ball_nbors.size() == 0:
		return
	
	#get_tree().get_root().get_node("gameplay").overlay_upgrade_scene(ball_nbors.size()-3)
	# +1 charges for every match over 3, might need to change back to "bonus" items on raft section
	GLOBAL_VARS.upgradeCharges += max(1, ball_nbors.size() - 2)
	GLOBAL_VARS.score += 10 * GLOBAL_VARS.level * (max(0, ball_nbors.size() - 3) + 1)
	var sparkle_scene_b 
	for tile in ball_nbors:
		sparkle_scene_b = sparkle_scene.instantiate()
		sparkle_scene_b.init( Color(1,1,0))
		tile.add_child(sparkle_scene_b)
		if tile.tile_object == self and ball_nbors.size() >= 4:
			replace_with_gem()
		else:
			tile.tile_object.queue_free()
		
		sparkle_scene_b.play_hammer()
	
