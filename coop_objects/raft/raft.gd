class_name CoopRaft extends Node2D

const TILE_SPACING := Vector2(32, 32)

var raft_tile_scene = preload("res://singleplayer_objects/raft_tile/raft_tile.tscn")

var tiles = {}

const NORTH := Vector2i(0, -1)
const SOUTH := Vector2i(0, 1)
const WEST := Vector2i(-1, 0)
const EAST := Vector2i(1, 0)

func _ready() -> void:
	pass

func get_adjacent_tiles(coord : Vector2i):
	var adj_tiles = []
	
	if tiles.get(coord + NORTH) != null:
		adj_tiles.append(tiles.get(coord + NORTH))
	if tiles.get(coord + SOUTH) != null:
		adj_tiles.append(tiles.get(coord + SOUTH))
	if tiles.get(coord + WEST) != null:
		adj_tiles.append(tiles.get(coord + WEST))
	if tiles.get(coord + EAST) != null:
		adj_tiles.append(tiles.get(coord + EAST))
	
	return adj_tiles

func grid_pos_to_global_position(coord: Vector2i) -> Vector2:
	return global_position + (Vector2(coord.x, coord.y) * TILE_SPACING)

func get_tile(coord: Vector2i):
	return tiles.get(coord)
