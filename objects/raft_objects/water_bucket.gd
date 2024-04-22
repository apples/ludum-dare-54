extends "res://objects/raft_objects/raft_object.gd"

var raft_tile_scene = preload("res://objects/raft_tile/raft_tile.tscn")
var water_splash_scene = preload("res://objects/VFX/water_splash/water_splash.tscn")
var sparkle_scene = preload("res://objects/VFX/sparkle/sparkle.tscn")

func get_kind() -> StringName:
	return "water_bucket"

func _process_unconnected(_delta):
	var ball_nbors = match3()
	
	if ball_nbors.size() == 0:
		return
	
	GLOBAL_VARS.score += 10 * GLOBAL_VARS.level * (max(0, ball_nbors.size() - 3) + 1)
	
	var splash: Node2D
	var trigger_sound = false
	for tile in ball_nbors:
		for i in self.raft.get_tile_row(tile.grid_pos.y):
			if(i != null && i.is_on_fire):
				i.fire_health = 0
				trigger_sound = true
			splash = water_splash_scene.instantiate()
			get_tree().get_root().add_child(splash)
			splash.global_position = i.global_position
		for i in self.raft.get_tile_column(tile.grid_pos.x):
			if(i != null && i.is_on_fire):
				i.fire_health = 0
				trigger_sound = true
			splash = water_splash_scene.instantiate()
			get_tree().get_root().add_child(splash)
			splash.global_position = i.global_position
		var sparkle_scene_b = sparkle_scene.instantiate()
		sparkle_scene_b.init( Color(1,1,0))
		tile.add_child(sparkle_scene_b)
	
	if(trigger_sound):
		splash.get_node("SFX").play()
	
	for tile in ball_nbors:
		if tile.tile_object == self and ball_nbors.size() >= 4:
			replace_with_gem()
		else:
			raft.destroy_object(tile.grid_pos)
	
