extends CharacterBody2D

@export var raft: CoopRaft

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var hold_root = $HoldRoot
@onready var grab_area = $GrabArea

var walk_speed := 300
var grid_pos : Vector2i
var last_grid_pos: Vector2i = grid_pos
var facing_dir := Vector2i(1, 0)

var held_object : Node
var held_object_name : StringName

const move_delay_time_ticks := 6 # really this should be configurable in the options, 6 = 0.1 seconds
const move_ticks_target := 8
var move_ticks := 0
var push_ticks := 0



func _network_process(input: Dictionary):
	var lr: int = (1 if input["right"] else 0) - (1 if input["left"] else 0)
	var ud: int = (1 if input["down"] else 0) - (1 if input["up"] else 0)
	var direction := Vector2i(lr, ud)
	
	if direction != Vector2i(0, 0):
		facing_dir = direction
	var facing_pos = grid_pos + facing_dir
	var facing_tile = raft.get_tile(facing_pos)
	var facing_obj = facing_tile.tile_object if facing_tile else null
	
	if direction == Vector2i.ZERO:
		push_ticks = 0
	else:
		if facing_obj: # start pushing
			push_ticks += 1
			if push_ticks >= move_delay_time_ticks:
				pass
				#if facing_obj.push(grid_pos):
					#if move_ticks >= move_ticks_target:
						#last_grid_pos = grid_pos
						#grid_pos += direction
						#move_ticks = 0
		elif facing_tile and not held_object: # simply walk
			if move_ticks >= move_ticks_target:
				last_grid_pos = grid_pos
				grid_pos += direction
				move_ticks = 0
	
	move_ticks += 1
	global_position = lerp(
		raft.grid_pos_to_global_position(last_grid_pos),
		 raft.grid_pos_to_global_position(grid_pos),
		 clampf(float(move_ticks) / float(move_ticks_target), 0.0, 1.0))

func _save_state() -> Dictionary:
	return {
		grid_pos = grid_pos,
		last_grid_pos = last_grid_pos,
	}

func _load_state(state: Dictionary) -> void:
	grid_pos = state['grid_pos']
	last_grid_pos = state['last_grid_pos']
