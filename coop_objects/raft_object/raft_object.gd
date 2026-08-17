class_name CoopItem extends Node2D

var grid_pos: Vector2i
var type : GLOBAL_VARS.object_type

var is_moving := false

@onready var sprite := $AnimatedSprite2D

const push_speed := 32.0 * 12.0

const wood_frames = preload("res://assets/sprite_frames/wood_sprite_frames.tres")
const water_frames = preload("res://assets/sprite_frames/bucket_sprite_frames.tres")
const hammer_frames = preload("res://assets/sprite_frames/hammer_sprite_frames.tres")
const cannon_frames = preload("res://assets/sprite_frames/cannon_sprite_frames.tres")
const bomb_frames = preload("res://assets/sprite_frames/bomb_sprite_frames.tres")
const gem_frames = preload("res://assets/sprite_frames/gem_sprite_frames.tres")

func _process(delta: float) -> void:
	if position != Vector2.ZERO:
		position = position.move_toward(Vector2.ZERO, push_speed * delta)

func _network_process(input: Dictionary):
	pass



func _network_spawn(data: Dictionary) -> void:
	type = data.type
	
	get_parent().tile_object = self
	
	match type:
		GLOBAL_VARS.object_type.WOOD:
			sprite.sprite_frames = wood_frames
		GLOBAL_VARS.object_type.WATER:
			sprite.sprite_frames = water_frames
		GLOBAL_VARS.object_type.HAMMER:
			sprite.sprite_frames = hammer_frames
		GLOBAL_VARS.object_type.CANNON:
			sprite.sprite_frames = cannon_frames
		GLOBAL_VARS.object_type.BOMB:
			sprite.sprite_frames = bomb_frames
		GLOBAL_VARS.object_type.GEM:
			sprite.sprite_frames = gem_frames
