extends Node2D

var item_type : GLOBAL_VARS.object_type
var raft_ref : CoopRaft

var has_hit := false
var column := 0

@onready var item_sprite = $ItemSprite

var warning_scene = preload("res://coop_objects/raft_object_warning/object_warning.tscn")


func _network_process(input: Dictionary):
	if has_hit:
		return
	position += Vector2.DOWN * 0.3125 #close enough to a third while being a power of two
	var highest_tile : CoopTile = raft_ref.get_highest_tile(column)
	if highest_tile != null and position.y + 32 >= highest_tile.global_position.y:
		launch()

func launch() -> void:
	has_hit = true
	var spawn_tile = raft_ref.get_random_empty_tile()
	if spawn_tile != null:
		SyncManager.spawn("alert", $"/root/CoopGameplay/ItemParent", warning_scene, {grid_pos = spawn_tile.grid_pos, buoy_pos = global_position, good = true, item = item_type})
	SyncManager.despawn(self)

func _save_state() -> Dictionary:
	return {
		position = position,
		has_hit = has_hit,
	}

func _load_state(state: Dictionary) -> void:
	position = state['position']
	has_hit = state['has_hit']

func _network_spawn(data: Dictionary) -> void:
	item_type = data.type
	position = data.pos
	
	raft_ref = $"/root/CoopGameplay/Raft"
	column = roundi((position.x - raft_ref.global_position.x) / 32.0)
	
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
