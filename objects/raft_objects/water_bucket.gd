extends "res://objects/raft_objects/raft_object.gd"

var raft_tile_scene = preload("res://objects/raft_tile/raft_tile.tscn")
var water_splash_scene = preload("res://objects/VFX/water_splash/water_splash.tscn")
var sparkle_scene = preload("res://objects/VFX/sparkle/sparkle.tscn")

func get_kind() -> StringName:
	return "water_bucket"

func _process_unconnected(delta):
	var ball_nbors = match3()
	
	if ball_nbors.size() == 0:
		return
	
	GLOBAL_VARS.score += 10
	
	var splash: Node2D
	var trigger_sound = false
	for b in ball_nbors:
		for i in self.raft.get_tile_row(b.grid_pos.y):
			if(i.tile_object != null && i.tile_object.get_kind() == "fire"):
				self.raft.set_tile(raft_tile_scene, b.grid_pos.y, i.grid_pos.x)
				trigger_sound = true
			splash = water_splash_scene.instantiate()
			get_tree().get_root().add_child(splash)
			splash.global_position = i.global_position
		for i in self.raft.get_tile_column(b.grid_pos.x):
			if(i.tile_object != null && i.tile_object.get_kind() == "fire"):
				self.raft.set_tile(raft_tile_scene, i.grid_pos.y, b.grid_pos.x)
				trigger_sound = true
			splash = water_splash_scene.instantiate()
			get_tree().get_root().add_child(splash)
			splash.global_position = i.global_position
		var sparkle_scene_b = sparkle_scene.instantiate()
		sparkle_scene_b.init( Color(1,1,0))
		b.get_parent().add_child(sparkle_scene_b)
		if b == self and ball_nbors.size() >= 4:
			replace_with_gem()
		else:
			b.queue_free()

	if(trigger_sound):
		splash.get_node("SFX").play()
