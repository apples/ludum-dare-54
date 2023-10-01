extends Node2D

# Called when the node enters the scene tree for the first time.
func _ready():
#	player_vars = get_node("/root/PlayerVariables")
	$RichTextLabel.text = "You Got a Score of %s!" % GLOBAL_VARS.score

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func _on_start_game_pressed():
	GLOBAL_VARS.score=0
	GLOBAL_VARS.match3_paused = false
	UTILS.change_to_scene("res://scenes/gameplay/gameplay.tscn")
