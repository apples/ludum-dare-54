extends RaftTile
var player_ref: PlayerCharacter
var fire_being_fixed = false
var max_fire_value = 300

var damage_number_scene = preload("res://objects/damage_numbers/damage_numbers.tscn")
var raft_tile_scene = preload("res://objects/raft_tile/raft_tile.tscn")

# Called when the node enters the scene tree for the first time.
func _ready():
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if not player_ref:
		return
		
	if Input.is_action_just_released("interact"):
		player_ref._change_state(PlayerCharacter.STATE_IDLE)
		$fire_fix_meter.visible = false
		fire_being_fixed = false
		$fire_fix_meter.value = max_fire_value
		$fire_damage_timer.start()
	
	if fire_being_fixed:
		$fire_fix_meter.value -= 1
		
	if $fire_fix_meter.value <= 0:
		player_ref._change_state(PlayerCharacter.STATE_IDLE)
		raft_ref.swap_tile(raft_tile_scene, row_index, column_index)
		print("fire fixed!")
		

func interact(player: PlayerCharacter):
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

