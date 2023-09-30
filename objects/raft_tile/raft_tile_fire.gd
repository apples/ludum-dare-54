extends RaftTile
var player_ref
var damage_number_scene = preload("res://objects/damage_numbers/damage_numbers.tscn")
# Called when the node enters the scene tree for the first time.
func _ready():
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if not player_ref:
		return
		
	if Input.is_action_just_released("interact"):
		player_ref.release()

func interact(player):
	player_ref = player
	player.fix()
	print("Player interacted with FIRE LETS GOOOO at <%s, %s>." % [row_index, column_index])


func _on_fire_damage_timer_timeout():
	self.health -= 1
	var dmg_number = damage_number_scene.instantiate()
	dmg_number.position = self.position
	get_parent().add_child(dmg_number)
	print(self.health)

