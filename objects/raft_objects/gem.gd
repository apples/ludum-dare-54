extends "res://objects/raft_objects/raft_object.gd"

var gem_sparkle_scene = preload("res://objects/VFX/gem_sparkle/gem_sparkle.tscn")

func get_kind() -> StringName:
	return "gem"

func _process_unconnected(delta):
	var ball_nbors = match3()
	
	if ball_nbors.size() == 0:
		return
	for b in ball_nbors:
		var gem_sparkle_scene_b = gem_sparkle_scene.instantiate()
		b.get_parent().add_child(gem_sparkle_scene_b)
		
		b.queue_free()
