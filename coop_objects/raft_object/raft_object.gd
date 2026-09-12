class_name CoopItem extends Node2D

var grid_pos: Vector2i
var type : GLOBAL_VARS.object_type

var is_moving := false
var target_pos := Vector2.ZERO
var move_frames := 0
var start_pos := Vector2.ZERO

@onready var sprite := $AnimatedSprite2D


func _network_process(input: Dictionary):
	if is_moving:
		if move_frames == 0:
			start_pos = position
		move_frames += 1
		position = start_pos.lerp(target_pos, move_frames / 12.0) #32 pixels in 12 ticks
		if move_frames == 12:
			is_moving = false
			move_frames = 0

func _save_state() -> Dictionary:
	return {
		is_moving = is_moving,
		target_pos = target_pos,
		move_frames = move_frames,
		start_pos = start_pos,
	}

func _load_state(state: Dictionary) -> void:
	is_moving = state['is_moving']
	target_pos = state['target_pos']
	move_frames = state['move_frames']
	start_pos = state['start_pos']

func _network_spawn(data: Dictionary) -> void:
	type = data.type
	var raft : CoopRaft = $"/root/CoopGameplay/Raft"
	var tile = raft.get_tile(data.grid_pos)
	
	position = tile.position
	target_pos = position
	start_pos = position
	
	tile.tile_object = self
	
	match type:
		GLOBAL_VARS.object_type.WOOD:
			sprite.play("wood")
		GLOBAL_VARS.object_type.WATER:
			sprite.play("water")
		GLOBAL_VARS.object_type.HAMMER:
			sprite.play("hammer")
		GLOBAL_VARS.object_type.CANNON:
			sprite.play("cannon")
		GLOBAL_VARS.object_type.BOMB:
			sprite.play("bomb")
		GLOBAL_VARS.object_type.GEM:
			sprite.play("gem")
