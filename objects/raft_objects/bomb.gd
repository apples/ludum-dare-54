extends "res://objects/raft_objects/raft_object.gd"
var bomb_explosion_scene = preload("res://objects/bomb_explosion/bomb_explosion.tscn")

func get_kind() -> StringName:
	return "bomb"

func _process_unconnected(delta):
	var ball_nbors = match3()
	
	if ball_nbors.size() == 0:
		return
	
	var bomb_match = false
	for b in ball_nbors:
		bomb_match = true
		b.queue_free()

	if bomb_match:
		print("boomy")
		for n in 3:
			generate_explosion()
		
func generate_explosion():
	var bomb_explosion: Node2D = bomb_explosion_scene.instantiate()
	get_parent().add_child(bomb_explosion)
