extends "res://objects/raft_objects/raft_object.gd"

var fire_being_fixed = false
var max_fire_value = 300

var damage_number_scene = preload("res://objects/damage_numbers/damage_numbers.tscn")
var raft_tile_scene = preload("res://objects/raft_tile/raft_tile.tscn")
var smoke_scene = preload("res://objects/smoke/smoke.tscn")

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
		queue_free()
		print("fire fixed!")


func _on_player_connected():
	$fire_damage_timer.stop()
	$fire_fix_meter.visible = true
	fire_being_fixed = true
	connected_player.fix()


func _on_fire_damage_timer_timeout():
	raft.get_tile(grid_pos.y, grid_pos.x).damage(1)
	var dmg_number = damage_number_scene.instantiate()
	dmg_number.position = self.position
	get_parent().add_child(dmg_number)


func _on_smoke_added_timer_timeout():
	add_smoke()
	add_smoke()
	add_smoke()

func add_smoke():
	var smoke = smoke_scene.instantiate()
	smoke.position = self.position
	smoke.position.x += randf_range(-3, 3)
	smoke.position.y += randf_range(-5, 5)
	get_parent().add_child(smoke)
