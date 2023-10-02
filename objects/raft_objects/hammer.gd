extends "res://objects/raft_objects/raft_object.gd"

var raft_tile_scene = preload("res://objects/raft_tile/raft_tile.tscn")
var repair_splash_scene = preload("res://objects/VFX/repair_splash/repair_splash.tscn")
var sparkle_scene = preload("res://objects/VFX/sparkle/sparkle.tscn")

func get_kind() -> StringName:
	return "hammer"

func _process_unconnected(delta):
	var ball_nbors = match3()
	
	if ball_nbors.size() == 0:
		return
	
	GLOBAL_VARS.score += 10
	
	var splash: Node2D
	for b in ball_nbors:
		for i in self.raft.get_tiles_in_radius(b.grid_pos.y, b.grid_pos.x, 1):
			i._set_health(3)
			splash = repair_splash_scene.instantiate()
			get_tree().get_root().add_child(splash)
			splash.global_position = i.global_position
		var sparkle_scene_b = sparkle_scene.instantiate()
		sparkle_scene_b.init( Color(1,1,0))
		b.get_parent().add_child(sparkle_scene_b)
		if b == self and ball_nbors.size() >= 4:
			replace_with_gem()
		else:
			b.queue_free()
