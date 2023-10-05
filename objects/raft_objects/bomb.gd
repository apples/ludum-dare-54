extends "res://objects/raft_objects/raft_object.gd"
var bomb_explosion_scene = preload("res://objects/VFX/bomb_explosion/bomb_explosion.tscn")

func get_kind() -> StringName:
	return "bomb"

func _process_unconnected(_delta):
	var ball_nbors = match3()
	
	if ball_nbors.size() == 0:
		return
	
	GLOBAL_VARS.score -= 5 * (max(0, ball_nbors.size() - 3) + 1)
	
	for b in ball_nbors:
		b.on_match()
		b.queue_free()

func on_match():
	explode_fire_dmg()

func explode_fire_dmg():
	var obj_on_tile = self.raft.get_tile(grid_pos.y, grid_pos.x)
	obj_on_tile.damage(1)
	
	for n in 3:
		var bomb_explosion: Node2D = bomb_explosion_scene.instantiate()
		get_tree().get_root().add_child(bomb_explosion)
		bomb_explosion.position = self.global_position
		if n == 0:
			bomb_explosion.get_node("SFX").play()
	
	var random_fire_chance = randi_range(0, 1)
	if random_fire_chance == 1:
		obj_on_tile.ignite()
