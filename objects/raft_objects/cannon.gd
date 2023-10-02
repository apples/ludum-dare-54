extends "res://objects/raft_objects/raft_object.gd"

var shoot_scene = preload("res://objects/VFX/cannon_shoot/cannon_shoot.tscn")

func get_kind() -> StringName:
	return "cannon"

func _process_unconnected(delta):
	var ball_nbors = match3()
	
	if ball_nbors.size() == 0:
		return
	
	GLOBAL_VARS.score += 10
	
	for b in ball_nbors:
		var shoot = shoot_scene.instantiate()
		shoot.position = Vector2.ZERO
		b.get_parent().add_child(shoot)
		b.queue_free()
