class_name CoopRaft extends Node2D

const TILE_SPACING := Vector2(32, 32)

var raft_tile_scene = preload("res://coop_objects/tile/tile.tscn")
var cannonball_scene = preload("res://coop_objects/cannonball/cannonball.tscn")
var item_scene = preload("res://coop_objects/raft_object/raft_object.tscn")
var buoy_scene = load("res://coop_objects/buoy/buoy.tscn")

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

func get_highest_tile(column: int, below: Vector2 = Vector2(0, -1000)) -> CoopTile:
	var top_possible = (below.y - global_position.y) / TILE_SPACING.y
	for row in range(max(top_possible, 0), 15):
		var tile: CoopTile = tiles.get(Vector2i(column, row))
		if tile != null and tile.position.y:
			return tile
	return null

func remove_tile(coord: Vector2i) -> void:
	tiles.erase(coord)

func add_tile(tile: CoopTile) -> void:
	tiles[tile.grid_pos] = tile

func place_tile(coord: Vector2i) -> void:
	SyncManager.spawn("Tile_%s_%s" % [coord.x, coord.y], self, raft_tile_scene, {coord = coord})

func get_random_empty_tile_in_column(column: int) -> CoopTile:
	var offset = 0
	var col_tiles = []
	for i in range(15):
		for row in range(15):
			var tile: CoopTile = tiles.get(Vector2i(column + offset, row))
			if tile != null and not tile.tile_object and not tile.player_ref:
				col_tiles.append(tile)
		if col_tiles.size() > 0:
			break
		else:
			if offset > 0:
				offset = -offset
			else:
				offset = (-offset) + 1
	
	var not_near_player = col_tiles.duplicate()
	for e in col_tiles:
		for p in players:
			var d = e.grid_pos - p.grid_pos
			var grid_dist = abs(d.x) + abs(d.y)
			if grid_dist <= 1:
				not_near_player.erase(e)
	
	if not not_near_player.is_empty():
		return not_near_player[MULT_UTILS.mult_rng.randi_range(0, not_near_player.size() - 1)]
	else:
		if col_tiles.size() < 1: #TODO more graceful losing scene transition. Slowmo and a zoom in?
			UTILS.change_to_scene("res://scenes/lose_screen/lose_scene.tscn")
			return null
		return col_tiles[MULT_UTILS.mult_rng.randi_range(0, col_tiles.size() - 1)]

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

func place_object(tile: CoopTile, object, comboLevel = 0):
	tile.tile_object = object
	tile.tile_object.instant_move(tile.position)
	tile.tile_object.grid_pos = tile.grid_pos
	check_matches(tile, comboLevel)

func pickup_object(tile: CoopTile, player: CoopPlayer) -> void:
	player.held_object = tile.tile_object
	tile.tile_object = null
	player.held_object.instant_move(player.position + Vector2(0, -16) - position)

func check_matches(tile: CoopTile, comboLevel = 0) -> void:
	var start_coord := tile.grid_pos
	var type := tile.tile_object.type
	var match_tiles : Array[CoopTile] = [tile]
	
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
	
	match_effect(match_tiles, type, level + comboLevel)

func match_effect(match_tiles: Array[CoopTile], type: GLOBAL_VARS.object_type, level: int):
	match type:
		GLOBAL_VARS.object_type.WOOD:
			wood_effect(match_tiles, level)
		GLOBAL_VARS.object_type.WATER:
			water_effect(match_tiles, level)
		GLOBAL_VARS.object_type.HAMMER:
			hammer_effect(match_tiles, level)
		GLOBAL_VARS.object_type.CANNON:
			cannon_effect(match_tiles, level)
		GLOBAL_VARS.object_type.BOMB:
			bomb_effect(match_tiles, level)
		GLOBAL_VARS.object_type.GEM:
			gem_effect(match_tiles, level)
	
	for tile in match_tiles:
		var item = tile.tile_object
		if item:
			tile.tile_object = null
			SyncManager.despawn(item)
	
	if match_tiles.size() > 3 and type != GLOBAL_VARS.object_type.BOMB:
		var g_tile = match_tiles[MULT_UTILS.mult_rng.randi_range(0, match_tiles.size() - 1)]
		SyncManager.spawn("item", $"/root/CoopGameplay/ItemParent", item_scene, {type = GLOBAL_VARS.object_type.GEM, grid_pos = g_tile.grid_pos})

func wood_effect(match_tiles: Array[CoopTile], level: int):
	gameplay.score += 10 * level
	gameplay.raft_charges += level
	for tile in match_tiles:
		tile.play_effect("wood")

func water_effect(match_tiles: Array[CoopTile], level: int):
	gameplay.score += 1 * level
	var radius = level
	
	for source_tile in match_tiles:
		var coord = source_tile.grid_pos
		for x in range(-radius, radius + 1):
			for y in range(-radius, radius + 1):
				if x == 0 and y == 0:
					continue
				if abs(x) + abs(y) <= radius:
					var target_coord = coord + Vector2i(x, y)
					var tile = get_tile(target_coord)
					if tile:
						tile.play_effect("water")
						if tile.tile_object and tile.tile_object.type == GLOBAL_VARS.object_type.BOMB:
							gameplay.score += 4 * level
							SyncManager.despawn(tile.tile_object)
							tile.tile_object = null
						if tile.tile_object and tile.is_on_fire:
							gameplay.score += 1 * level
							tile.fire_health_ticks = 0

func hammer_effect(match_tiles: Array[CoopTile], level: int):
	gameplay.score += 1 * level
	var heal_strength = ((level + 1) % 2) + 1
	var radius = ceili(level / 2.0)
	
	for source_tile in match_tiles:
		var coord = source_tile.grid_pos
		for x in range(-radius, radius + 1):
			for y in range(-radius, radius + 1):
				if x == 0 and y == 0:
					continue
				if abs(x) + abs(y) <= radius:
					var target_coord = coord + Vector2i(x, y)
					var tile = get_tile(target_coord)
					if tile:
						tile.play_effect("hammer")
						if tile.health < tile.max_health:
							gameplay.score += 2 * level
						tile.damage(-heal_strength)
						if tile.tile_object and tile.is_on_fire:
							gameplay.score += 1 * level
							tile.fire_health_ticks = 0

func cannon_effect(match_tiles: Array[CoopTile], level: int):
	gameplay.score += 5 * level
	for tile in match_tiles:
		SyncManager.spawn("Cannonball", self, cannonball_scene, {pos = tile.global_position})
		tile.play_effect("cannon")

func bomb_effect(match_tiles: Array[CoopTile], level: int):
	for tile in match_tiles:
		#var t_player = tile.player_ref
		tile.play_effect("bomb")
		tile.damage(ceili(level / 2.0))
		if tile and tile.health > 0 and MULT_UTILS.mult_rng.randi_range(0, 9) < level + 4:
			tile.ignite()
		#if (!tile or tile.health < 1) and t_player: # splash player
			#t_player.rooted = true
			#SyncManager.spawn("Buoy", $"/root/CoopGameplay/BuoyParent", buoy_scene, {pos = grid_pos_to_global_position(t_player.grid_pos), player_path = t_player.get_path()})
			#t_player.grid_pos = Vector2i(-1, -1)

func gem_effect(match_tiles: Array[CoopTile], level: int):
	gameplay.score += 10 * level
	var object_counter = {}
	var vertical = (match_tiles[0].grid_pos.x - match_tiles[1].grid_pos.x) == 0
	
	for m_tile in match_tiles:
		m_tile.play_effect("gem")
		for i in range(15):
			var c_tile : CoopTile
			if vertical:
				c_tile = get_tile(Vector2(i, m_tile.grid_pos.y))
			else:
				c_tile = get_tile(Vector2(m_tile.grid_pos.x, i))
			
			if c_tile and c_tile.tile_object:
				var existing = object_counter.get(c_tile.tile_object.type)
				object_counter[c_tile.tile_object.type] = existing + 1 if existing else 1
				SyncManager.despawn(c_tile.tile_object)
				c_tile.tile_object = null
				c_tile.play_effect("gem")
				gameplay.score += 5
	
	for key in object_counter.keys():
		if object_counter[key] > 1:
			match_effect(match_tiles, key, object_counter[key] - 1)

func generate_initial_platform() -> void:
	for r in range(8, 12):
		for c in range(6, 11):
			place_tile(Vector2i(c, r))

func _save_state() -> Dictionary:
	var tile_paths := []
	for tile: CoopTile in tiles.values():
		if is_instance_valid(tile):
			tile_paths.append(tile.get_path())
	return {
		tile_paths = tile_paths,
	}

func _load_state(state: Dictionary) -> void:
	tiles.clear()
	for tile_path in state['tile_paths']:
		var tile := get_node_or_null(tile_path) as CoopTile
		if tile:
			add_tile(tile)
