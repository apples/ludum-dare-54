extends Node

var _player_node: CharacterBody2D
signal player_node_changed
var player_node: CharacterBody2D:
	get:
		return _player_node
	set(v):
		_player_node = v
		player_node_changed.emit()

