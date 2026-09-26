class_name CoopRaft extends Node2D

const TILE_SPACING := Vector2(32, 32)

var raft_tile_scene = preload("res://coop_objects/tile/tile.tscn")
var cannonball_scene = preload("res://coop_objects/cannonball/cannonball.tscn")

@onready var gameplay = self.get_parent()

var tiles: Dictionary[Vector2i, CoopTile] = {}
var players = []

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

func get_highest_tile(column: int) -> CoopTile:
	for row in range(15):
		var tile: CoopTile = tiles.get(Vector2i(column, row))
		if tile != null:
			return tile
	return null

func remove_tile(coord: Vector2i) -> void:
	tiles.erase(coord)

func add_tile(tile: CoopTile) -> void:
	tiles[tile.grid_pos] = tile

func place_tile(coord: Vector2i) -> void:
	SyncManager.spawn("Tile_%s_%s" % [coord.x, coord.y], self, raft_tile_scene, {coord = coord})

func get_random_empty_tile() -> CoopTile:
	var empts = []
	for t:CoopTile in tiles.values():
		if not t.tile_object and not t.player_ref:
			empts.append(t)
	
	if empts.is_empty(): #TODO more graceful losing scene transition. Slowmo and a zoom in?
		UTILS.change_to_scene("res://scenes/lose_screen/lose_scene.tscn")
		return null
	
	var not_near_player = empts.duplicate()
	for e in empts:
		for p in players:
			var d = e.grid_pos - p.grid_pos
			var grid_dist = abs(d.x) + abs(d.y)
			if grid_dist <= 1:
				not_near_player.erase(e)
	
	if not not_near_player.is_empty():
		return not_near_player[MULT_UTILS.mult_rng.randi_range(0, not_near_player.size() - 1)]
	else:
		return empts[MULT_UTILS.mult_rng.randi_range(0, empts.size() - 1)]

func place_object(tile: CoopTile, object):
	tile.tile_object = object
	tile.tile_object.position = tile.position
	tile.tile_object.target_pos = tile.position
	tile.tile_object.grid_pos = tile.grid_pos
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
	
	var one_time = false
	for m_tile in match_tiles:
		if !one_time:
			match_effect(m_tile.grid_pos, type, level)
		else:
			#m_tile.tile_object.queue_free()
			SyncManager.despawn(m_tile.tile_object)
			m_tile.tile_object = null
		if type == GLOBAL_VARS.object_type.WOOD:
			one_time = true

func match_effect(coord: Vector2i, type: GLOBAL_VARS.object_type, level: int):
	match type:
		GLOBAL_VARS.object_type.WOOD:
			wood_effect(coord, level)
		GLOBAL_VARS.object_type.WATER:
			water_effect(coord, level)
		GLOBAL_VARS.object_type.HAMMER:
			hammer_effect(coord, level)
		GLOBAL_VARS.object_type.CANNON:
			cannon_effect(coord, level)
		GLOBAL_VARS.object_type.BOMB:
			bomb_effect(coord, level)
		GLOBAL_VARS.object_type.GEM:
			gem_effect(coord, level)
	
	var tile = get_tile(coord)
	if tile and tile.tile_object:
		SyncManager.despawn(tile.tile_object)
		#tile.tile_object.queue_free()
		tile.tile_object = null

func wood_effect(coord: Vector2i, level: int):
	gameplay.score += 10 * level
	gameplay.raft_charges += level

func water_effect(coord: Vector2i, level: int):
	gameplay.score += 1 * level
	var radius = level
	
	for x in range(-radius, radius + 1):
		for y in range(-radius, radius + 1):
			if x == 0 and y == 0:
				continue
			if abs(x) + abs(y) <= radius:
				var target_coord = coord + Vector2i(x, y)
				var tile = get_tile(target_coord)
				if tile and tile.tile_object and tile.tile_object.type == GLOBAL_VARS.object_type.BOMB:
					gameplay.score += 4 * level
					SyncManager.despawn(tile.tile_object)
					#tile.tile_object.queue_free()
					tile.tile_object = null

func hammer_effect(coord: Vector2i, level: int):
	gameplay.score += 1 * level
	var heal_strength = ((level + 1) % 2) + 1
	var radius = ceili(level / 2.0)
	
	for x in range(-radius, radius + 1):
		for y in range(-radius, radius + 1):
			if x == 0 and y == 0:
				continue
			if abs(x) + abs(y) <= radius:
				var target_coord = coord + Vector2i(x, y)
				var tile = get_tile(target_coord)
				if tile:
					if tile.health < tile.max_health:
						gameplay.score += 2 * level
					tile.damage(-heal_strength)

func cannon_effect(coord: Vector2i, level: int):
	gameplay.score += 5 * level
	SyncManager.spawn("Cannonball", self, cannonball_scene, {pos = grid_pos_to_global_position(coord)})

func bomb_effect(coord: Vector2i, level: int):
	var tile = get_tile(coord)
	tile.damage(ceili(level / 2.0))
	if MULT_UTILS.mult_rng.randi_range(0, 9) < level + 4:
		tile.ignite()

func gem_effect(coord: Vector2i, level: int):
	gameplay.score += 10 * level
	hammer_effect(coord, level + 2)
	water_effect(coord, level + 2)
	#TODO player combo +++

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
