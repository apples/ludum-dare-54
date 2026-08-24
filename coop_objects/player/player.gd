class_name CoopPlayer extends CharacterBody2D

@export var raft: CoopRaft

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var hold_root = $HoldRoot
@onready var grab_area = $GrabArea

var debug_item = preload("res://coop_objects/raft_object/raft_object.tscn")

var walk_speed := 300
var grid_pos : Vector2i
var last_grid_pos: Vector2i = grid_pos
var facing_dir := Vector2i(1, 0)
var last_direction : Vector2i

var held_object : CoopItem:
	set(value):
		held_object = value
		held_object_name = held_object.name if held_object else StringName("")
var held_object_name : StringName

const move_delay_time_ticks := 6 # really this should be configurable in the options, 6 = 0.1 seconds
const move_ticks_target := 8
var move_ticks := 0
var push_ticks := 0
var recent_input_dir := Vector2i(0, 0)

func _process(delta: float) -> void:
	match facing_dir:
		Vector2i.LEFT:
			anim.play("left")
		Vector2i.RIGHT:
			anim.play("right")
		Vector2i.UP:
			anim.play("up")
		_:
			anim.play("down")

func _network_process(input: Dictionary):
	#held_object_name = held_object.name if held_object else StringName("")
	if !input:
		return
	
	var lr: int = (1 if input["right"] else 0) - (1 if input["left"] else 0)
	var ud: int = (1 if input["down"] else 0) - (1 if input["up"] else 0)
	var direction := Vector2i(lr, ud)
	
	if direction.x != 0 and direction.y != 0: #diagonal
		if recent_input_dir != Vector2i(0, 0):
			direction = recent_input_dir
		elif last_direction != Vector2i(0, 0):
			recent_input_dir = direction - last_direction
			direction = recent_input_dir
		else:
			direction.y = 0
	else:
		recent_input_dir = Vector2i(0, 0)
	
	if direction != Vector2i(0, 0):
		facing_dir = direction
	var facing_pos = grid_pos + facing_dir
	var facing_tile := raft.get_tile(facing_pos)
	var facing_obj = facing_tile.tile_object if facing_tile else null
	var facing_player = facing_tile.player_ref if facing_tile else null
	
	if direction == Vector2i.ZERO:
		push_ticks = 0
	else:
		if held_object && (last_direction != direction && direction != Vector2i.ZERO): #directional place
			if facing_player && !facing_player.held_object: #place on ally
				facing_player.held_object = held_object
				held_object = null
			elif facing_tile && !facing_obj: #place on tile
				raft.place_object(facing_tile, held_object)
		elif facing_obj || facing_player: # start pushing
			push_ticks += 1
			if push_ticks >= move_delay_time_ticks:
				if facing_tile.push(grid_pos):
					walk(direction)
		elif facing_tile: # simply walk
			walk(direction)
	
	if input["interact"]:
		if !held_object:
			if facing_obj: #pickup object
				pass
			elif facing_player: #pickup player
				pass
			else: #pickup buoy
				pass
		elif facing_tile && !facing_obj: #swap-drop
			pass
	
	if input["debug1"]:
		SyncManager.spawn("debugItem", raft.get_tile(grid_pos), debug_item, {type = GLOBAL_VARS.object_type.WOOD})
	
	move_ticks += 1
	global_position = lerp(
		raft.grid_pos_to_global_position(last_grid_pos),
		 raft.grid_pos_to_global_position(grid_pos),
		 clampf(float(move_ticks) / float(move_ticks_target), 0.0, 1.0))
	last_direction = direction

func walk(direction: Vector2i):
	if move_ticks >= move_ticks_target:
		last_grid_pos = grid_pos
		grid_pos += direction
		raft.get_tile(last_grid_pos).player_ref = null
		raft.get_tile(grid_pos).player_ref = self
		move_ticks = 0

func _save_state() -> Dictionary:
	return {
		grid_pos = grid_pos,
		last_grid_pos = last_grid_pos,
		last_direction = last_direction,
		move_ticks = move_ticks,
		recent_input_dir = recent_input_dir,
	}

func _load_state(state: Dictionary) -> void:
	grid_pos = state['grid_pos']
	last_grid_pos = state['last_grid_pos']
	last_direction = state['last_direction']
	move_ticks = state['move_ticks']
	recent_input_dir = state['recent_input_dir']

func _network_spawn(data: Dictionary) -> void:
	grid_pos = data.get("grid_pos")
	last_grid_pos = grid_pos
	raft = get_parent().find_child("Raft")
	position = raft.grid_pos_to_global_position(grid_pos)
	var tile = raft.get_tile(grid_pos)
	tile.player_ref = self
	tile.player_ref_name = name

func _get_local_input() -> Dictionary:
	var input := {}
	input["left"] = Input.is_action_pressed("left")
	input["right"] = Input.is_action_pressed("right")
	input["up"] = Input.is_action_pressed("up")
	input["down"] = Input.is_action_pressed("down")
	input["interact"] = Input.is_action_just_pressed("interact")
	
	input["debug1"] = Input.is_action_just_pressed("debug_1")
	return input

func _predict_remote_input(previous_input: Dictionary, ticks_since_real_input: int) -> Dictionary: # just setting all "is_action_just_pressed" actions to false
	if ticks_since_real_input > 0:
		previous_input["interact"] = false
	return previous_input
