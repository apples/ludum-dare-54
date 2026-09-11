extends Node2D

var item_type : GLOBAL_VARS.object_type
var raft_ref

@onready var item_sprite = $ItemSprite

const wood_frames = preload("res://assets/sprite_frames/wood_sprite_frames.tres")
const water_frames = preload("res://assets/sprite_frames/bucket_sprite_frames.tres")
const hammer_frames = preload("res://assets/sprite_frames/hammer_sprite_frames.tres")
const cannon_frames = preload("res://assets/sprite_frames/cannon_sprite_frames.tres")
const bomb_frames = preload("res://assets/sprite_frames/bomb_sprite_frames.tres")
const gem_frames = preload("res://assets/sprite_frames/gem_sprite_frames.tres")


func _network_process(input: Dictionary):
	position += Vector2.DOWN #this likely needs to be cut down to at third

func _save_state() -> Dictionary:
	return {
		position = position,
	}

func _load_state(state: Dictionary) -> void:
	position = state['position']

func _network_spawn(data: Dictionary) -> void:
	item_type = data.type
	position = data.pos
	
	raft_ref = get_parent().get_parent().find_child("Raft", false)
	
	match item_type:
		GLOBAL_VARS.object_type.WOOD:
			item_sprite.sprite_frames = wood_frames
		GLOBAL_VARS.object_type.WATER:
			item_sprite.sprite_frames = water_frames
		GLOBAL_VARS.object_type.HAMMER:
			item_sprite.sprite_frames = hammer_frames
		GLOBAL_VARS.object_type.CANNON:
			item_sprite.sprite_frames = cannon_frames
		GLOBAL_VARS.object_type.BOMB:
			item_sprite.sprite_frames = bomb_frames
		GLOBAL_VARS.object_type.GEM:
			item_sprite.sprite_frames = gem_frames
	item_sprite.play()


func _on_area_2d_area_entered(area: Area2D) -> void:
	#spawn indicator on weighted random tile
	pass # Replace with function body.
