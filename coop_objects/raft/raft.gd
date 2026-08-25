class_name CoopRaft extends Node2D

const TILE_SPACING := Vector2(32, 32)

var raft_tile_scene = preload("res://coop_objects/tile/tile.tscn")

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

func get_tile(coord: Vector2i) -> CoopTile:
	return tiles.get(coord)

func remove_tile(coord: Vector2i) -> void:
	tiles.erase(coord)

func place_object(tile: CoopTile, object):
	tile.tile_object = object
	tile.tile_object.position = tile.position
	tile.tile_object.target_pos = tile.position
	check_matches(tile)

func pickup_object(tile: CoopTile, player: CoopPlayer) -> void:
	player.held_object = tile.tile_object
	tile.tile_object = null
	player.held_object.global_position = player.global_position + Vector2(0, -16)
	player.held_object.target_pos = player.held_object.position

func check_matches(tile: CoopTile) -> void:
	var start_coord := tile.grid_pos
	var type := tile.tile_object.type
	var match_tiles := [tile]
	
	var axes = [
		[Vector2i.LEFT, Vector2i.RIGHT], 
		[Vector2i.UP, Vector2i.DOWN]
	]
	
	for axis in axes:
		var axis_matches = []
		for dir in axis:
			for i in range(1, 18):
				var current = get_tile(start_coord + (dir * i))
				
				if current and current.tile_object and current.tile_object.type == type:
					axis_matches.append(current)
				else:
					break
		
		if axis_matches.size() >= 2:
			match_tiles.append_array(axis_matches)
	
	var level = match_tiles.size() - 2
	
	if level < 1:
		return
	
	for m_tile in match_tiles:
		m_tile.match_effect(type, level)

func generate_initial_platform() -> void:
	var new_tile : CoopTile
	for r in range(8,12):
		for c in range(6,11):
			new_tile = raft_tile_scene.instantiate()
			new_tile.name = "Tile_%s_%s" % [c, r]
			new_tile.raft_ref = self
			new_tile.grid_pos = Vector2i(c, r)
			new_tile.position = TILE_SPACING * Vector2(c, r)
			tiles.set(Vector2i(c, r), new_tile)
			add_child(new_tile)
