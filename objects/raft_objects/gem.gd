extends "res://objects/raft_objects/raft_object.gd"

var sparkle_scene = preload("res://objects/VFX/sparkle/sparkle.tscn")
var base_tile_scene = preload("res://objects/raft_tile/raft_tile.tscn")
func get_kind() -> StringName:
	return "gem"

func _process_unconnected(_delta):
	var ball_nbors = match3()
	
	if ball_nbors.size() == 0:
		return
	
	GLOBAL_VARS.score += 25 * GLOBAL_VARS.level * (max(0, ball_nbors.size() - 3) + 1)
	
	for tile in raft.find_all_tiles("bomb"):
		raft.destroy_object(tile.grid_pos)
	
	raft.heal_all_tiles()
	
	var sparkle_scene_b 
	for tile in ball_nbors:
		sparkle_scene_b = sparkle_scene.instantiate()
		sparkle_scene_b.init( Color(1,1,0))
		tile.add_child(sparkle_scene_b)
		raft.destroy_object(tile.grid_pos)
	
	sparkle_scene_b.play_gem()
