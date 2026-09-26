class_name CoopItemWarning extends CoopItem

var spawn_item : GLOBAL_VARS.object_type
var is_good := true
var last_buoy_pos := Vector2.ZERO
var launch_frames := 0

const frame_target = 60

@onready var alert_sprite := $AlertSprite

var item_scene = preload("res://coop_objects/raft_object/raft_object.tscn")

@export var simple_curve : Curve

func _network_process(input: Dictionary):
	super._network_process(input)
	
	launch_frames += 1
	var progress = launch_frames / float(frame_target)
	sprite.global_position = last_buoy_pos.lerp(global_position, progress)
	sprite.global_position.y -= simple_curve.sample(progress) * 100
	
	if launch_frames == frame_target:
		SyncManager.spawn("item", $"/root/CoopGameplay/ItemParent", item_scene, {type = spawn_item, grid_pos = grid_pos})
		#queue_free()
		SyncManager.despawn(self)

func _save_state() -> Dictionary:
	return {
		is_moving = is_moving,
		target_pos = target_pos,
		move_frames = move_frames,
		start_pos = start_pos,
		launch_frames = launch_frames,
	}

func _load_state(state: Dictionary) -> void:
	is_moving = state['is_moving']
	target_pos = state['target_pos']
	move_frames = state['move_frames']
	start_pos = state['start_pos']
	launch_frames = state['launch_frames']

func _network_spawn(data: Dictionary) -> void:
	type = GLOBAL_VARS.object_type.ALERT
	var raft : CoopRaft = $"/root/CoopGameplay/Raft"
	var tile = raft.get_tile(data.grid_pos)
	
	grid_pos = tile.grid_pos
	position = tile.position
	target_pos = position
	start_pos = position
	
	tile.tile_object = self
	
	last_buoy_pos = data.buoy_pos
	
	is_good = data.good
	if is_good:
		alert_sprite.play("good")
	else:
		alert_sprite.play("bad")
	
	spawn_item = data.item
	match spawn_item:
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
