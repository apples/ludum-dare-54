extends Node2D

var progress_ticks = 0
const max_ticks = 60
var level = 1
var target := Vector2.ZERO
var start_pos := Vector2.ZERO
var target_coord = null
var opponent_path := ^""

var bomb_item_scene = preload("res://versus_objects/raft_object/raft_object.tscn")

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

@export var simple_curve : Curve

func _network_process(_input: Dictionary):
	progress_ticks += 1
	var progress = progress_ticks / float(max_ticks)
	global_position = start_pos.lerp(target, progress)
	global_position.y += simple_curve.sample(progress)
	
	if progress_ticks >= max_ticks:
		_deliver_bomb()
		SyncManager.despawn(self)

func _deliver_bomb() -> void:
	if opponent_path == ^"":
		return
	var opponent: VersusRaft = get_node(opponent_path)
	
	# prefer the targeted tile; if something arrived there first, use any free tile on that raft
	var coord: Variant = null
	var tile : VersusTile = opponent.get_tile(target_coord) if target_coord != null else null
	if tile != null and not tile.tile_object and not tile.player_ref:
		coord = target_coord
	else:
		var alt_tile : VersusTile = opponent.get_random_empty_tile()
		coord = alt_tile.grid_pos if alt_tile != null else null
	
	if coord != null:
		SyncManager.spawn("item", opponent, bomb_item_scene, {type = GLOBAL_VARS.object_type.BOMB, grid_pos = coord})

func _save_state() -> Dictionary:
	return {
		progress_ticks = progress_ticks,
	}

func _load_state(state: Dictionary) -> void:
	progress_ticks = state['progress_ticks']

func _network_spawn(data: Dictionary) -> void:
	opponent_path = data.opponent_path
	target_coord = data.target_coord
	level = data.level
	global_position = data.pos
	start_pos = global_position
	progress_ticks = 0
	
	sprite.play("bomb")
	
	if target_coord != null:
		target = get_node(opponent_path).grid_pos_to_global_position(target_coord)
	else:
		# raft has no tiles (yet) - aim at its center
		target = get_node(opponent_path).global_position + Vector2(6, 10) * 32
