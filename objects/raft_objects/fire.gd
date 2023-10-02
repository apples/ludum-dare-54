extends "res://objects/raft_objects/raft_object.gd"

var fire_being_fixed = false
var max_fire_value = 150

var raft_tile_scene = preload("res://objects/raft_tile/raft_tile.tscn")
var smoke_scene = preload("res://objects/VFX/smoke/smoke.tscn")
var fire_scene = load("res://objects/raft_objects/fire.tscn") # load not preload
var sparkle_scene = load("res://objects/VFX/sparkle/sparkle.tscn")

func get_kind() -> StringName:
	return "fire"

func _process_connected(delta):
	if connected_player.is_action_just_released("interact"):
		connected_player.release()
		$fire_fix_meter.visible = false
		fire_being_fixed = false
		$fire_fix_meter.value = max_fire_value
		$fire_damage_timer.start()
	
	if fire_being_fixed:
		$fire_fix_meter.value -= 1
		
	if $fire_fix_meter.value <= 0:
		connected_player.release()
		if "tile_object" in get_parent():
			get_parent().tile_object = null
		var sparkle_scene_b = sparkle_scene.instantiate()
		sparkle_scene_b.init( Color(1,1,1))
		sparkle_scene_b.play_hammer()
		get_parent().add_child(sparkle_scene_b)
		queue_free()
		print("fire fixed!")


func _on_player_connected():
	$fire_damage_timer.stop()
	$fire_fix_meter.visible = true
	fire_being_fixed = true
	connected_player.fix()


func _on_fire_damage_timer_timeout():
	var burning_tile = raft.get_tile(grid_pos.y, grid_pos.x)
	
	if burning_tile:
		burning_tile.damage(1)
		spread_fire_to_adjacent_tiles(burning_tile)

func spread_fire_to_adjacent_tiles(burning_tile: RaftTile):
	var adjacent_tiles = burning_tile.get_surrounding_tiles()
	
	for tile in adjacent_tiles:
		var fire_spread_chance = randi_range(0, 5)
		
		if fire_spread_chance == 1:
			if tile.tile_object == null:
				var fire = fire_scene.instantiate()
				fire.grid_pos = tile.grid_pos
				fire.raft = self.raft
				tile.add_child(fire)
				tile.tile_object = fire

func _on_smoke_added_timer_timeout():
	add_smoke()
	add_smoke()
	add_smoke()

func add_smoke():
	var smoke = smoke_scene.instantiate()
	smoke.position = self.global_position
	smoke.position.x += randf_range(-3, 3)
	smoke.position.y += randf_range(-5, 5)

	get_tree().get_root().add_child(smoke)
