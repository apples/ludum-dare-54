extends Node2D

var item_type : GLOBAL_VARS.object_type
var raft_ref : CoopRaft

@onready var item_sprite = $ItemSprite

var warning_scene = preload("res://coop_objects/raft_object_warning/object_warning.tscn")


func _network_process(input: Dictionary):
	position += Vector2.DOWN * 0.3125 #close enough to a third while being a power of two

func _save_state() -> Dictionary:
	return {
		position = position,
	}

func _load_state(state: Dictionary) -> void:
	position = state['position']

func _network_spawn(data: Dictionary) -> void:
	item_type = data.type
	position = data.pos
	
	raft_ref = $"/root/CoopGameplay/Raft"
	
	match item_type:
		GLOBAL_VARS.object_type.WOOD:
			item_sprite.play("wood")
		GLOBAL_VARS.object_type.WATER:
			item_sprite.play("water")
		GLOBAL_VARS.object_type.HAMMER:
			item_sprite.play("hammer")
		GLOBAL_VARS.object_type.CANNON:
			item_sprite.play("cannon")
		GLOBAL_VARS.object_type.BOMB:
			item_sprite.play("bomb")
		GLOBAL_VARS.object_type.GEM:
			item_sprite.play("gem")


func _on_area_2d_area_entered(area: Area2D) -> void:
	#var tile : CoopTile = area.get_parent() # actually we don't need the tile for anything
	var spawn_pos = raft_ref.get_random_empty_tile().grid_pos
	SyncManager.spawn("alert", $"/root/CoopGameplay/ItemParent", warning_scene, {grid_pos = spawn_pos, buoy_pos = global_position, good = true, item = item_type})
	SyncManager.despawn(self)
	#queue_free()
