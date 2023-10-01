extends Node2D

var connected_player: Node
var raft: Node
var grid_pos: Vector2i

@export var is_interactable := false
@export var is_pushable := false

func _process_connected(delta):
	pass

func _physics_process_connected(delta):
	pass

func _on_player_connected():
	pass

func _on_player_disconnected():
	pass

func _process(delta):
	if not connected_player:
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
		position = Vector2.ZERO
		next_tile.tile_object = self
		cur_tile.tile_object = null
		return 

func _on_tree_exiting():
	if connected_player:
		connected_player.call_deferred("release")
		_on_player_disconnected()

func release_player():
	connected_player.call_deferred("release")
	connected_player = null
	_on_player_disconnected()
