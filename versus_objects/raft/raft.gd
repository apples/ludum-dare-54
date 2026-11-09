class_name VersusRaft extends Node2D

const TILE_SPACING := Vector2(32, 32)
const BUILD_COLUMNS := 12
const BUILD_ROWS := 15
const BASE_TIMER_TICKS = 180
const DAZE_SECONDS := 5.0
const DAZE_EFFECT_TICKS := 300 # DAZE_SECONDS * 60 (60 ticks per second)

var raft_tile_scene = preload("res://versus_objects/tile/tile.tscn")
#var bomb_projectile_scene = preload("res://versus_objects/cannonball/cannonball.tscn")
var item_scene = preload("res://versus_objects/raft_object/raft_object.tscn")
var buoy_scene = load("res://versus_objects/buoy/buoy.tscn")
var warning_scene = preload("res://versus_objects/raft_object_warning/object_warning.tscn")

@onready var gameplay = self.get_parent()
@onready var buoy_timer = $BuoyTimer

@export var raft_index := 0 # 0 = raft1, 1 = raft2

var opponent: VersusRaft = null

var tiles: Dictionary[Vector2i, VersusTile] = {}
var players = []

var boost_mult = 1

var column_ranges := [[0, 12], [3, 8], [5, 7]]
var column_bag := []

var spawnables = [
	{ weight = 40, scene = GLOBAL_VARS.object_type.WOOD },
	{ weight = 20, scene = GLOBAL_VARS.object_type.CANNON },
	{ weight = 10, scene = GLOBAL_VARS.object_type.WATER },
	{ weight = 10, scene = GLOBAL_VARS.object_type.HAMMER },
	{ weight = 1, scene = GLOBAL_VARS.object_type.GEM},
	{ weight = 1, scene = GLOBAL_VARS.object_type.BOMB },
]
var spawnables_bag := []

var daze_ticks := 0

const NORTH := Vector2i(0, -1)
const SOUTH := Vector2i(0, 1)
const WEST := Vector2i(-1, 0)
const EAST := Vector2i(1, 0)

func _ready() -> void:
	pass

func _network_process(_input: Dictionary) -> void:
	_process_fires()
	
	if daze_ticks > 0:
		daze_ticks -= 1
		if daze_ticks <= 0:
			buoy_timer.unpause()

func _process_fires() -> void:
	var burning: Array[VersusTile] = []
	for tile: VersusTile in tiles.values():
		if tile.is_on_fire:
			burning.append(tile)
	burning.sort_custom(_tile_pos_sort)
	for tile in burning:
		if is_instance_valid(tile) and tiles.get(tile.grid_pos) == tile:
			tile.process_fire()

func _tile_pos_sort(a: VersusTile, b: VersusTile) -> bool:
	if a.grid_pos.x != b.grid_pos.x:
		return a.grid_pos.x < b.grid_pos.x
	return a.grid_pos.y < b.grid_pos.y

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

func get_tile(coord: Vector2i) -> VersusTile:
	return tiles.get(coord)

func get_highest_tile(column: int, below: Vector2 = Vector2(0, -1000)) -> VersusTile:
	if column < 0 or column >= BUILD_COLUMNS:
		return null
	var top_possible = (below.y - global_position.y) / TILE_SPACING.y
	for row in range(max(top_possible, 0), BUILD_ROWS):
		var tile: VersusTile = tiles.get(Vector2i(column, row))
		if tile != null and tile.position.y:
			return tile
	return null

func remove_tile(coord: Vector2i) -> void:
	tiles.erase(coord)

func add_tile(tile: VersusTile) -> void:
	tiles[tile.grid_pos] = tile

func place_tile(coord: Vector2i) -> void:
	SyncManager.spawn("Tile_%s_%s" % [coord.x, coord.y], self, raft_tile_scene, {coord = coord})

func get_random_tile() -> VersusTile:
	if tiles.is_empty():
		return null
	var tile_list = tiles.values()
	return tile_list[MULT_UTILS.mult_rng.randi_range(0, tile_list.size() - 1)]

func get_random_empty_tile_in_column(column: int) -> VersusTile:
	var offset = 0
	var col_tiles = []
	for i in range(BUILD_COLUMNS * BUILD_ROWS):
		if column + offset >= 0 and column + offset < BUILD_COLUMNS:
			for row in range(BUILD_ROWS):
				var tile: VersusTile = tiles.get(Vector2i(column + offset, row))
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
		if col_tiles.size() < 1: #TODO more graceful ending scene transition. Slowmo and a zoom in?
			gameplay.end_game(raft_index)
			return null
		return col_tiles[MULT_UTILS.mult_rng.randi_range(0, col_tiles.size() - 1)]

func get_random_empty_tile() -> VersusTile:
	var empts = []
	for t: VersusTile in tiles.values():
		if not t.tile_object and not t.player_ref:
			empts.append(t)
	
	if empts.is_empty(): #TODO more graceful losing scene transition. Slowmo and a zoom in?
		gameplay.end_game(raft_index)
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

func place_object(tile: VersusTile, object, comboLevel = 0):
	tile.tile_object = object
	tile.tile_object.instant_move(tile.position)
	tile.tile_object.grid_pos = tile.grid_pos
	check_matches(tile, comboLevel)

func pickup_object(tile: VersusTile, player: VersusPlayer) -> void:
	player.held_object = tile.tile_object
	tile.tile_object = null
	player.held_object.instant_move(player.position + Vector2(0, -16) - position)

func check_matches(tile: VersusTile, comboLevel = 0) -> void:
	var start_coord := tile.grid_pos
	var type := tile.tile_object.type
	var match_tiles : Array[VersusTile] = [tile]
	
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

func match_effect(match_tiles: Array[VersusTile], type: GLOBAL_VARS.object_type, level: int):
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
	
	if type != GLOBAL_VARS.object_type.BOMB:
		_daze_opponent()
		if match_tiles.size() > 3:
			var g_tile = match_tiles[MULT_UTILS.mult_rng.randi_range(0, match_tiles.size() - 1)]
			SyncManager.spawn("item", self, item_scene, {type = GLOBAL_VARS.object_type.GEM, grid_pos = g_tile.grid_pos})

func _daze_opponent() -> void:
	if opponent:
		opponent.daze_ticks += DAZE_EFFECT_TICKS
		opponent.buoy_timer.pause()

func wood_effect(match_tiles: Array[VersusTile], level: int):
	gameplay.score += 10 * level
	gameplay.add_charges(raft_index, level)
	for tile in match_tiles:
		tile.play_effect("wood")

func water_effect(match_tiles: Array[VersusTile], level: int):
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

func hammer_effect(match_tiles: Array[VersusTile], level: int):
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

func cannon_effect(match_tiles: Array[VersusTile], level: int):
	gameplay.score += 5 * level
	if opponent == null:
		return
	for i in range(level - 1):
		var rand_match = match_tiles[MULT_UTILS.mult_rng.randi_range(0, match_tiles.size())]
		match_tiles.append(rand_match)
	for tile in match_tiles:
		tile.play_effect("cannon")
		var target_tile = opponent.get_random_empty_tile()
		if target_tile:
			SyncManager.spawn("alert", opponent, warning_scene, {
				grid_pos = target_tile.grid_pos, buoy_pos = tile.global_position, good = false, item = GLOBAL_VARS.object_type.BOMB})
		else:
			return

func bomb_effect(match_tiles: Array[VersusTile], level: int):
	for tile in match_tiles:
		tile.play_effect("bomb")
		tile.damage(ceili(level / 2.0))
		if tile and tile.health > 0 and MULT_UTILS.mult_rng.randi_range(0, 9) < level + 4:
			tile.ignite()

func gem_effect(match_tiles: Array[VersusTile], level: int):
	gameplay.score += 10 * level
	var object_counter = {}
	var vertical = (match_tiles[0].grid_pos.x - match_tiles[1].grid_pos.x) == 0
	
	for m_tile in match_tiles:
		m_tile.play_effect("gem")
		for i in range(BUILD_ROWS):
			var c_tile : VersusTile
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

func fill_column_bag():
	for r in column_ranges:
		for i in range(r[0], r[1]):
			column_bag.append(i)
	seed(MULT_UTILS.mult_rng.randi())
	column_bag.shuffle()

func fill_spawnables_bag():
	for s in spawnables:
		for i in range(s.weight):
			spawnables_bag.append(s.scene)
	seed(MULT_UTILS.mult_rng.randi())
	spawnables_bag.shuffle()

func change_buoy_speed(amount):
	boost_mult = maxi(boost_mult + amount, 1)
	
	@warning_ignore("integer_division")
	var new_wait: int = BASE_TIMER_TICKS / boost_mult
	SyncManager.set_synced(buoy_timer, "ticks_left", maxi((buoy_timer.ticks_left * new_wait) / buoy_timer.wait_ticks, 1))
	SyncManager.set_synced(buoy_timer, "wait_ticks", new_wait)

func _on_buoy_timer_timeout() -> void:
	if column_bag.is_empty():
		fill_column_bag()
	if spawnables_bag.is_empty():
		fill_spawnables_bag()
	var spawn_type = spawnables_bag.pop_back()
	var spawn_pos = global_position + Vector2(column_bag.pop_back() * 32, 0)
	SyncManager.spawn("Buoy", gameplay.buoy_parent, buoy_scene, {pos = spawn_pos, raft_path = get_path(), type = spawn_type})

func _save_state() -> Dictionary:
	var tile_paths := []
	for tile: VersusTile in tiles.values():
		if is_instance_valid(tile) and tile.is_inside_tree():
			tile_paths.append(tile.get_path())
	return {
		tile_paths = tile_paths,
		daze_ticks = daze_ticks,
		boost_mult = boost_mult,
		column_bag = column_bag.duplicate(),
		spawnables_bag = spawnables_bag.duplicate(),
	}

func _load_state(state: Dictionary) -> void:
	tiles.clear()
	for tile_path in state['tile_paths']:
		var tile := get_node_or_null(tile_path) as VersusTile
		if tile:
			add_tile(tile)
	daze_ticks = state['daze_ticks']
	boost_mult = state['boost_mult']
	column_bag = state['column_bag'].duplicate()
	spawnables_bag = state['spawnables_bag'].duplicate()
