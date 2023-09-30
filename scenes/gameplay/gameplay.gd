extends Node2D
var upgrade_select_scene = preload("res://scenes/upgrade_select/upgrade_select.tscn")

# Called when the node enters the scene tree for the first time.
func _ready():
	pass
#	raft_destroyed($enemy_raft)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	pass


func raft_destroyed(raft: Raft):
	if raft == $enemy_raft:
		$Player.sit()
		var display_upgrade_select = upgrade_select_scene.instantiate()
		self.add_child(display_upgrade_select)
	elif raft == $player_raft:
		print("oops you lost") # game over
