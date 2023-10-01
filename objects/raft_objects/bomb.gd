extends "res://objects/raft_objects/raft_object.gd"
var bomb_explosion_scene = preload("res://objects/bomb_explosion/bomb_explosion.tscn")
var fire_scene = preload("res://objects/raft_objects/fire.tscn")
func get_kind() -> StringName:
	return "bomb"

func _process_unconnected(delta):
	var ball_nbors = match3()
	
	if ball_nbors.size() == 0:
		return
	
#	var bomb_match = false
	for b in ball_nbors:
#		bomb_match = true
		b.on_match()
		b.queue_free()

func on_match():
	# TODO: Chance of start fire
	explode_fire_dmg()
#		self.raft.get_tile(grid_pos.y, grid_pos.x).damage(3)
	print("boomy")
	for n in 3:
		generate_explosion()

func explode_fire_dmg():
	var obj_on_tile = self.raft.get_tile(grid_pos.y, grid_pos.x)
	obj_on_tile.damage(1)
	
	var fire = fire_scene.instantiate()
	fire.grid_pos = self.grid_pos
	fire.raft = self.raft
	obj_on_tile.add_child(fire)
	obj_on_tile.tile_object = fire
		
func generate_explosion():
	var bomb_explosion: Node2D = bomb_explosion_scene.instantiate()
	get_tree().get_root().add_child(bomb_explosion)
	bomb_explosion.position = self.global_position
