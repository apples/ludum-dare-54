extends Node2D

static var next_id = 1
var id = 0
var connected_player: Node
var raft: Node
var grid_pos: Vector2i

@export var is_interactable := false
@export var is_pushable := false
@export var is_holdable := false

var held_by: Node = null

@onready var sfx_zoop = $SFXZoop
@onready var sfx_zeep = $SFXZeep

@onready var state_machine: StateMachine = $StateMachine

func get_kind() -> StringName:
	assert(false, "get_kind() not implemented")
	return ""

func _process_unconnected(_delta):
	pass

func _process_connected(_delta):
	pass

func _on_player_connected():
	pass

func _on_player_disconnected():
	pass

func _init():
	id = next_id
	next_id += 1

func _exit_tree():
	if connected_player:
		connected_player.call_deferred("release")
		_on_player_disconnected()

func is_idle():
	return state_machine.current_state.name == "Idle"

func interact(player):
	if not is_interactable:
		return
	
	connected_player = player
	connected_player.eat_inputs()
	
	_on_player_connected()

func push(player_grid_pos: Vector2i):
	if not is_idle():
		return false
	var d := grid_pos - player_grid_pos
	var next_pos := grid_pos + d
	var next_tile = raft.get_tile(next_pos.y, next_pos.x)
	if next_tile and next_tile.tile_object == null:
		raft.move_object(next_tile.grid_pos, self)
		return true

func find_neighboring_objects(of_kind: StringName):
	var nbors = []
	
	for d in [Vector2i(-1, 0), Vector2i(1, 0), Vector2i(0, -1), Vector2i(0, 1)]:
		var nbor = raft.get_tile(grid_pos.y + d.y, grid_pos.x + d.x)
		if not nbor:
			continue
		if not nbor.tile_object:
			continue
		if not nbor.tile_object.is_idle():
			continue
		if nbor.tile_object.get_kind() == of_kind:
			nbors.append(nbor.tile_object)
	
	return nbors

func match3() -> Array[Node]:
	if GLOBAL_VARS.match3_paused:
		return []
	
	if not raft:
		return []
	
	var region: RaftRegion = raft.get_region(grid_pos)
	
	if region.tile_list.size() < 3:
		return []
	
	if region.tile_list[0].tile_object.id != id:
		return []
	
	for tile in region.tile_list:
		if not tile.tile_object.can_be_matched():
			return []
	
	return region.tile_list

func can_be_matched():
	return is_idle()

func replace_with_gem():
	raft.replace_object(grid_pos, preload("res://objects/raft_objects/gem.tscn").instantiate())

func moved():
	state_machine.goto("Pushed")

func boss_toss(toss_start: Vector2, reticle_animation: StringName = "bad_thing", buoy: bool = false):
	if buoy:
		sfx_zeep.play()
	else:
		sfx_zoop.play()
	
	state_machine.goto("Tossed", { toss_start = toss_start, reticle_animation = reticle_animation })
