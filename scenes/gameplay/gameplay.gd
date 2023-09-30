extends Node2D
var upgrade_select_scene = preload("res://scenes/upgrade_select/upgrade_select.tscn")

# Called when the node enters the scene tree for the first time.
func _ready():
	pass
#	enemy_destroyed()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	pass


func enemy_destroyed():
	$Player._change_state(PlayerCharacter.STATE_SIT)
	var display_upgrade_select = upgrade_select_scene.instantiate()
	self.add_child(display_upgrade_select)
