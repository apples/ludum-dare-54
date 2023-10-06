extends "res://objects/raft_objects/raft_object.gd"

var shoot_scene = preload("res://objects/VFX/cannon_shoot/cannon_shoot.tscn")
var sparkle_scene = preload("res://objects/VFX/sparkle/sparkle.tscn")
var shoot_confetti_scene = preload("res://objects/VFX/cannon_confetti/cannon_confetti.tscn")

func get_kind() -> StringName:
	return "cannon"

func _process_unconnected(_delta):
	var ball_nbors = match3()
	
	if ball_nbors.size() == 0:
		return
	
	GLOBAL_VARS.score += 10 * GLOBAL_VARS.level * (max(0, ball_nbors.size() - 3) + 1)
	
	var extra_shots = (ball_nbors.size() - 3) * 2
	
	var shot_scene = shoot_scene
	
	if not get_node("/root/gameplay/Boss").is_alive:
		extra_shots = 0
		shot_scene = shoot_confetti_scene
	
	var sparkle_scene_b
	for tile in ball_nbors:
		var shoot = shot_scene.instantiate()
		shoot.position = Vector2.ZERO
		sparkle_scene_b = sparkle_scene.instantiate()
		sparkle_scene_b.init(Color(1,1,1))
		tile.add_child(sparkle_scene_b)
		tile.add_child(shoot)
		if tile.tile_object == self and ball_nbors.size() >= 4:
			replace_with_gem()
		else:
			tile.tile_object.queue_free()
			
		sparkle_scene_b.play_cannon()
		
		if extra_shots > 0:
			var shoot2 = shot_scene.instantiate()
			shoot2.extra_shot = true
			extra_shots -= 1
			shoot2.position = Vector2.ZERO
			tile.add_child(shoot2)
