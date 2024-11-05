extends "res://objects/mult_character/mult_character.gd"

#var player_id = 1

func _get_player_input():
	var input := InputState.new()
	input.left = Input.is_action_pressed("left")
	input.right = Input.is_action_pressed("right")
	input.up = Input.is_action_pressed("up")
	input.down = Input.is_action_pressed("down")
	input.interact = Input.is_action_pressed("interact")
	input.cancel = Input.is_action_pressed("cancel")
	#input.mouse = Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)
	return input

func _player_special_process(_delta):
	if Input.is_action_just_pressed("debug_1"):
		held_object = preload("res://objects/raft_objects/water_bucket.tscn").instantiate()
		state_machine.goto("Holding")
	
	if Input.is_action_just_pressed("debug_2"):
		held_object = preload("res://objects/raft_objects/driftwood.tscn").instantiate()
		state_machine.goto("Holding")
	
	if Input.is_action_just_pressed("debug_3"):
		held_object = preload("res://objects/raft_objects/bomb.tscn").instantiate()
		state_machine.goto("Holding")
	
	if Input.is_action_just_pressed("debug_4"):
		held_object = preload("res://objects/raft_objects/gem.tscn").instantiate()
		state_machine.goto("Holding")
	
	if Input.is_action_just_pressed("debug_5"):
		held_object = preload("res://objects/raft_objects/cannon.tscn").instantiate()
		state_machine.goto("Holding")
	
	if Input.is_action_just_pressed("debug_6"):
		held_object = preload("res://objects/raft_objects/hammer.tscn").instantiate()
		state_machine.goto("Holding")
	
	if Input.is_action_just_pressed("debug_7"):
		get_tree().current_scene.get_node("Boss").death()
	
	if Input.is_action_just_pressed("debug_8"):
		get_tree().get_root().get_node("gameplay").overlay_upgrade_scene(1)
	
	if Input.is_action_pressed("debug_9"):
		Engine.time_scale = 10.0
	else:
		Engine.time_scale = 1.0
	
	if Input.is_action_just_pressed("debug_0"):
		for kind in [
			&"water_bucket",
			&"fire",
			&"hammer",
			&"cannon",
			&"gem",
			&"driftwood",
			&"cannon_ball",
			&"bomb",
		]:
			for tile in raft.find_all_tiles(kind):
				raft.destroy_object(tile.grid_pos)
		
		return true

#func _enter_tree() -> void:
	#set_multiplayer_authority(player_id)
