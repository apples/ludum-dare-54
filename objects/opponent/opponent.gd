extends "res://objects/character/character.gd"

func _get_player_input():
	var input := InputState.new()
	input.left = randi_range(0, 1) == 1
	input.right = randi_range(0, 1) == 1
	input.up = randi_range(0, 1) == 1
	input.down = randi_range(0, 1) == 1
	input.interact = randi_range(0, 1) == 1
	input.cancel = randi_range(0, 1) == 1
	return input
