extends raft_tile
var player_ref: PlayerCharacter

# Called when the node enters the scene tree for the first time.
func _ready():
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if not player_ref:
		return
		
	if Input.is_action_just_released("interact"):
		player_ref._change_state(PlayerCharacter.STATE_IDLE)

func interact(player: PlayerCharacter):
	player_ref = player
#	player.input_disabled = true
	player._change_state(PlayerCharacter.STATE_FIX)
	print("Player interacted with FIRE LETS GOOOO at <%s, %s>." % [row_index, column_index])


func _on_fire_damage_timer_timeout():
	self.health -= 1
	print(self.health)

