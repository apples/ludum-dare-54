extends Node2D

var connected_player: Node
var raft: Node
var grid_pos: Vector2i

@export var is_interactable := false
@export var is_pushable := false
@export var is_holdable := false

var held_by: Node = null

var being_pushed := false
var push_speed := 32.0 * 12.0

func get_kind() -> StringName:
	assert(false, "get_kind() not implemented")
	return ""

func _process_unconnected(delta):
	pass

func _process_connected(delta):
	pass

func _physics_process_connected(delta):
	pass

func _on_player_connected():
	pass

func _on_player_disconnected():
	pass

func _init():
	z_index = 5

func _exit_tree():
	if connected_player:
		connected_player.call_deferred("release")
		_on_player_disconnected()
	detach_raft()

func detach_raft():
	if raft:
		var t = raft.get_tile(grid_pos.y, grid_pos.x)
		if t.tile_object == self:
			t.tile_object = null

func _process(delta):
	if being_pushed:
		position = position.move_toward(Vector2.ZERO, push_speed * delta)
		if position == Vector2.ZERO:
			being_pushed = false
		else:
			return
	
	if not connected_player:
		_process_unconnected(delta)
		return
	
	_process_connected(delta)

func _physics_process(delta):
	if not connected_player:
		return
	
	_physics_process_connected(delta)

func interact(player):
	if not is_interactable:
		return
	
	connected_player = player
	connected_player.eat_inputs()
	
	_on_player_connected()

func push(player_grid_pos: Vector2i):
	var cur_tile = raft.get_tile(grid_pos.y, grid_pos.x)	
	var d := grid_pos - player_grid_pos
	var next_pos := grid_pos + d
	var next_tile = raft.get_tile(next_pos.y, next_pos.x)
	if next_tile and next_tile.tile_object == null:
		reparent(next_tile)
		grid_pos = next_tile.grid_pos
		next_tile.tile_object = self
		cur_tile.tile_object = null
		being_pushed = true
		return

func release_player():
	connected_player.call_deferred("release")
	connected_player = null
	_on_player_disconnected()

func find_neighboring_objects(of_kind: StringName):
	var nbors = []
	
	for d in [Vector2i(-1, 0), Vector2i(1, 0), Vector2i(0, -1), Vector2i(0, 1)]:
		var nbor = raft.get_tile(grid_pos.y + d.y, grid_pos.x + d.x)
		if not nbor:
			continue
		if not nbor.tile_object:
			continue
		if nbor.tile_object.being_pushed:
			continue
		if nbor.tile_object.get_kind() == of_kind:
			nbors.append(nbor.tile_object)
	
	return nbors

func match3():
	if not raft:
		return []
		
	var kind := get_kind()
	var ball_nbors = [self]
	
	var i = 0;
	while i < ball_nbors.size():
		for o in ball_nbors[i].find_neighboring_objects(kind):
			if not o in ball_nbors:
				ball_nbors.append(o)
		i += 1
	
	if ball_nbors.size() < 3:
		return []
	
	return ball_nbors

