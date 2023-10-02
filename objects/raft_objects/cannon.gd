extends "res://objects/raft_objects/raft_object.gd"

var shoot_scene = preload("res://objects/VFX/cannon_shoot/cannon_shoot.tscn")
var sparkle_scene = preload("res://objects/VFX/sparkle/sparkle.tscn")

func get_kind() -> StringName:
	return "cannon"

func _process_unconnected(delta):
	var ball_nbors = match3()
	
	if ball_nbors.size() == 0:
		return
	
	GLOBAL_VARS.score += 10
	var sparkle_scene_b
	for b in ball_nbors:
		var shoot = shoot_scene.instantiate()
		shoot.position = Vector2.ZERO
		sparkle_scene_b = sparkle_scene.instantiate()
		sparkle_scene_b.init( Color(1,1,1))
		b.get_parent().add_child(sparkle_scene_b)
		b.get_parent().add_child(shoot)
		b.queue_free()
	sparkle_scene_b.play_cannon()
