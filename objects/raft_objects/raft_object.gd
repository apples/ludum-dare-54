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

func _on_tree_exiting():
	if connected_player:
		connected_player.call_deferred("release")
		_on_player_disconnected()

func release_player():
	connected_player.call_deferred("release")
	connected_player = null
	_on_player_disconnected()
