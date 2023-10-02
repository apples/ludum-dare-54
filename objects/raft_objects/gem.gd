extends "res://objects/raft_objects/raft_object.gd"

var sparkle_scene = preload("res://objects/VFX/sparkle/sparkle.tscn")
var base_tile_scene = preload("res://objects/raft_tile/raft_tile.tscn")
func get_kind() -> StringName:
	return "gem"

func _process_unconnected(delta):
	var ball_nbors = match3()
	
	if ball_nbors.size() == 0:
		return
	
	GLOBAL_VARS.score += 25 * GLOBAL_VARS.level * (max(0, ball_nbors.size() - 3) + 1)
	
	for tile in raft.find_all_tiles("bomb"):
		raft.set_tile(base_tile_scene, tile.grid_pos.y, tile.grid_pos.x)
	
	raft.heal_all_tiles()
	
	var sparkle_scene_b 
	for b in ball_nbors:
		sparkle_scene_b= sparkle_scene.instantiate()
		sparkle_scene_b.init( Color(1,1,0))
		b.get_parent().add_child(sparkle_scene_b)
		b.queue_free()
		
	sparkle_scene_b.play_gem()
