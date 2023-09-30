extends RaftTile
var player_ref
var fire_being_fixed = false
var max_fire_value = 300

var damage_number_scene = preload("res://objects/damage_numbers/damage_numbers.tscn")
var raft_tile_scene = preload("res://objects/raft_tile/raft_tile.tscn")
var smoke_scene = preload("res://objects/smoke/smoke.tscn")

# Called when the node enters the scene tree for the first time.
func _ready():
	$smoke_added_timer.start()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if not player_ref:
		return
		
	if player_ref.is_action_just_released("interact"):
		player_ref.release()
		$fire_fix_meter.visible = false
		fire_being_fixed = false
		$fire_fix_meter.value = max_fire_value
		$fire_damage_timer.start()
	
	if fire_being_fixed:
		$fire_fix_meter.value -= 1
		
	if $fire_fix_meter.value <= 0:
		player_ref.release()
		raft_ref.swap_tile(raft_tile_scene, row_index, column_index)
		print("fire fixed!")


func interact(player):
	$fire_damage_timer.stop()
	$fire_fix_meter.visible = true
	fire_being_fixed = true
	player_ref = player
	player.fix()
	print("Player interacted with FIRE LETS GOOOO at <%s, %s>." % [row_index, column_index])


func _on_fire_damage_timer_timeout():
	self.health -= 1
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
