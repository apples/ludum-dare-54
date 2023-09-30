extends "res://objects/character/character.gd"

func _get_player_input():
	var input := InputState.new()
	input.left = Input.is_action_pressed("left")
	input.right = Input.is_action_pressed("right")
	input.up = Input.is_action_pressed("up")
	input.down = Input.is_action_pressed("down")
	input.interact = Input.is_action_pressed("interact")
	input.cancel = Input.is_action_pressed("cancel")
	return input
