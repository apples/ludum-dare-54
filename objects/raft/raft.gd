class_name Raft extends Node2D

@export var player: Node
@export var raft_tile_length: int = 5
@export var raft_tile_height: int = 4
var raft_tile_scene = preload("res://objects/raft_tile/raft_tile.tscn")
var raft_tile_cannon_scene = preload("res://objects/raft_tile/raft_tile_cannon.tscn")
var raft_tile_cannonball_scene = preload("res://objects/raft_tile/raft_tile_cannonball.tscn")
var raft_tile_water_bucket_scene = preload("res://objects/raft_tile/raft_tile_water_bucket.tscn")
var raft_tile_driftwood_scene = preload("res://objects/raft_tile/raft_tile_driftwood.tscn")
var raft_tile_bomb_scene = preload("res://objects/raft_tile/raft_tile_bomb.tscn")
var raft_tile_gem_scene = preload("res://objects/raft_tile/raft_tile_gem.tscn")

var raft_data_structure = {}

## Maps all tiles to their group regions. Access via get_region().
var _raft_regions: Dictionary = {}

const NORTH := Vector2i(0, -1)
const SOUTH := Vector2i(0, 1)
const WEST := Vector2i(-1, 0)
const EAST := Vector2i(1, 0)

const TILE_SPACING := Vector2(32, 32)

# Called when the node enters the scene tree for the first time.
func _ready():
	match GLOBAL_VARS.difficulty:
		GLOBAL_VARS.DIFF_EASY:
			generate_easy_raft()
		GLOBAL_VARS.DIFF_MED:
			generate_medium_raft()
		GLOBAL_VARS.DIFF_HARD:
			generate_hard_raft()

# initializes an object that's already attached to a raft tile
# this is meant mainly for spawning new raft pieces which have prefab objects
func initialize_object(tile: Node) -> void:
	assert(tile.grid_pos in raft_data_structure)
	var obj_node = tile.tile_object
	assert(obj_node != null)
	obj_node.grid_pos = tile.grid_pos
	obj_node.raft = self
	_raft_regions.clear()

# places an object onto the raft
# the object must not currently be on the raft
func place_object(grid_pos: Vector2i, node: Node) -> void:
	assert(grid_pos in raft_data_structure)
	var tile = raft_data_structure[grid_pos]
	assert(tile.tile_object == null)
	if node.get_parent():
		node.reparent(tile)
	else:
		tile.add_child(node)
	tile.tile_object = node
	initialize_object(tile)

# removes the object from the raft, but does not free it
func pickup_object(grid_pos: Vector2i) -> Node:
	assert(grid_pos in raft_data_structure)
	var tile = raft_data_structure[grid_pos]
	assert(tile.tile_object != null)
	var node = tile.tile_object
	tile.tile_object = null
	tile.remove_child(node)
	_raft_regions.clear()
	return node

# removes the object from the raft and frees it
func destroy_object(grid_pos: Vector2i):
	pickup_object(grid_pos).queue_free()

# moves an object from one place to another on the raft
func move_object(new_grid_pos: Vector2i, node: Node):
	assert(new_grid_pos in raft_data_structure)
	assert(node.grid_pos in raft_data_structure)
	var new_tile = raft_data_structure[new_grid_pos]
	assert(new_tile.tile_object == null)
	var old_tile = raft_data_structure[node.grid_pos]
	assert(old_tile.tile_object == node)
	
	old_tile.tile_object = null
	node.reparent(new_tile)
	new_tile.tile_object = node
	node.grid_pos = new_grid_pos
	_raft_regions.clear()
	node.moved()

# destroys an existing object and places a new one
func replace_object(grid_pos: Vector2i, node: Node):
	destroy_object(grid_pos)
	place_object(grid_pos, node)

func get_region(grid_pos: Vector2i):
	if _raft_regions.is_empty():
		_calculate_regions()
	return _raft_regions.get(grid_pos)

func _calculate_regions():
	assert(_raft_regions.is_empty())
	
	# Disjoint Set / Union Find
	# https://www.youtube.com/watch?v=ayW5B2W9hfo
	# a cell is considered a root node if its parent is itself
	# if a cell is not keyed in this dictionary, its parent is assumed to be itself
	var cell_parent_map := {}
	
	# find the root/representative of the given cell's group
	var get_root := func get_root(grid_pos: Vector2i) -> Vector2i:
		var current := grid_pos
		var parent: Vector2i = cell_parent_map.get(current, current)
		while parent != current:
			current = parent
			parent = cell_parent_map.get(current, current)
		cell_parent_map[grid_pos] = current
		return current
	
	# join two groups together
	var join := func join(grid_pos_a: Vector2i, grid_pos_b: Vector2i):
		var root_a: Vector2i = get_root.call(grid_pos_a)
		var root_b: Vector2i = get_root.call(grid_pos_b)
		cell_parent_map[root_a] = root_b
	
	# checks if a pair of cells needs to be in the same group and joins them
	var check_pair := func check_pair(a: Node, a_kind: StringName, b: Node):
		if a == null or b == null:
			return
		var b_kind = "" if b.tile_object == null else b.tile_object.get_kind()
		if a_kind == b_kind:
			join.call(a.grid_pos, b.grid_pos)
	
	# visit each cell and check its north and west neighbors
	# this will fully construct all of the disjoint sets
	for pos in raft_data_structure:
		var this = raft_data_structure[pos]
		assert(this != null)
		var kind: StringName = ""
		if this.tile_object != null:
			kind = this.tile_object.get_kind()
		check_pair.call(this, kind, raft_data_structure.get(pos + NORTH))
		check_pair.call(this, kind, raft_data_structure.get(pos + WEST))
	
	# now that we have the sets, flatten them into a simpler list of regions
	for pos in raft_data_structure:
		var tile = raft_data_structure[pos]
		var root: Vector2i = get_root.call(pos)
		var region: RaftRegion = _raft_regions.get(root)
		if not region:
			region = RaftRegion.new()
			region.kind = "" if tile.tile_object == null else tile.tile_object.get_kind()
			_raft_regions[root] = region
		region.tile_list.append(tile)
		_raft_regions[pos] = region
	
	return

func find_all_tiles(tile_type):
	var rval = []
	for coord in raft_data_structure:
		var tile_ref = raft_data_structure[coord]
		if tile_ref.tile_object and tile_ref.tile_object.get_kind() == tile_type:
				rval.append(tile_ref)
	return rval


func create_tile(grid_pos: Vector2i, tile_scene: PackedScene):
	assert(raft_data_structure.get(grid_pos) == null)
	
	var new_tile: Node = tile_scene.instantiate()
	new_tile.name = "Tile_%s" % [grid_pos]
	new_tile.raft_ref = self
	new_tile.grid_pos = grid_pos
	new_tile.position = TILE_SPACING * Vector2(grid_pos)
	new_tile.tree_exiting.connect(func ():
		if raft_data_structure.get(new_tile.grid_pos) == new_tile:
			remove_tile(new_tile.grid_pos)
	)
	new_tile.tile_object_changed.connect(func ():
		_raft_regions.clear())
	
	raft_data_structure[new_tile.grid_pos] = new_tile
	
	add_child(new_tile)


func remove_tile(grid_pos: Vector2i):
	assert(grid_pos in raft_data_structure)
	raft_data_structure.erase(grid_pos)
	_raft_regions.clear()


func replace_tile(grid_pos: Vector2i, tile_scene: PackedScene):
	remove_tile(grid_pos)
	create_tile(grid_pos, tile_scene)


func generate_easy_raft():
	for r in range(8, 12):
		for c in range(5,12):
			create_tile(Vector2i(c, r), raft_tile_scene)
	
	replace_tile(Vector2i(6, 9), raft_tile_driftwood_scene)
	replace_tile(Vector2i(7, 9), raft_tile_driftwood_scene)
	replace_tile(Vector2i(9, 9), raft_tile_driftwood_scene)


func generate_medium_raft():
	for r in range(8,12):
		for c in range(6,11):
			create_tile(Vector2i(c, r), raft_tile_scene)
			
	replace_tile(Vector2i(6, 9), raft_tile_driftwood_scene)
	replace_tile(Vector2i(7, 9), raft_tile_driftwood_scene)
	replace_tile(Vector2i(9, 9), raft_tile_driftwood_scene)


func generate_hard_raft():
	for r in range(8, 10):
		for c in range(6,8):
			create_tile(Vector2i(c, r), raft_tile_scene)


func rc_to_pos(rc: Vector2i) -> Vector2:
	return position + Vector2(rc.x, rc.y) * TILE_SPACING


func get_tile_at(pos: Vector2) -> RaftTile:
	var rc := Vector2i((pos + TILE_SPACING/2.0) / TILE_SPACING)
	return raft_data_structure.get(rc)


func get_tile(row: int, column: int) -> RaftTile:
	return raft_data_structure.get(Vector2i(column, row))


func get_tile_row(row: int) -> Array:
	var tiles = []
	var tile
	for i in range(0, 12):
		tile = get_tile(row, i)
		if tile != null:
			tiles.push_back(tile)
	return tiles


func get_tile_column(column: int) -> Array:
	var tiles = []
	var tile
	for i in range(0, 14):
		tile = get_tile(i, column)
		if tile != null:
			tiles.push_back(tile)
	return tiles


func get_closest_empty_tile(pos: Vector2):
	var gp := Vector2i((pos + TILE_SPACING/2.0) / TILE_SPACING)
	var closest_gp: Vector2i
	var closest_dist_sq: float = INF
	for k in raft_data_structure:
		var d = (gp - k).length_squared()
		if d < closest_dist_sq:
			closest_dist_sq = d
			closest_gp = k
	return raft_data_structure[closest_gp]


func get_relative_tile(direction: Vector2i, tile: RaftTile) -> RaftTile:
	return get_tile(tile.grid_pos.y + direction.y, tile.grid_pos.x + direction.x)


func get_relative_tile_rc(direction: Vector2i, row: int, column: int) -> RaftTile:
	return get_tile(row + direction.y, column + direction.x)


func get_random_empty_tile():
	var empts = []
	for k in raft_data_structure:
		if raft_data_structure[k] != null and \
			raft_data_structure[k].tile_object == null and \
			player.grid_pos != k:
			empts.append(raft_data_structure[k])
	# If anything tries to find an empty tile and can't we transition to the lose state
	if empts.is_empty():
		UTILS.change_to_scene("res://scenes/lose_screen/lose_scene.tscn")
		return null

	# filter out tiles near player if possible
	var not_near_player = []
	for e in empts:
		var d = e.grid_pos - player.grid_pos
		var grid_dist = abs(d.x) + abs(d.y)
		if grid_dist > 1:
			not_near_player.append(e)
	
	if not_near_player.is_empty():
		return empts.pick_random()
	else:
		return not_near_player.pick_random()


var relative_tile_in_radius_cache = {}
func get_relative_positions_in_radius(radius: float) -> Array[Vector2i]:
	if relative_tile_in_radius_cache.has(radius):
		return relative_tile_in_radius_cache.get(radius)
	
	var positions: Array[Vector2i] = []
	
	# https://www.redblobgames.com/grids/circle-drawing/#bounding-circle
	var top: int = ceil(-radius)
	var bottom: int = floor(radius)
	
	for y in range(top, bottom + 1):
		var dy: int = y
		var dx: float = sqrt(radius * radius - dy * dy)
		
		var left: int = ceil(-dx)
		var right: int = floor(dx)
		
		for x in range(left, right + 1):
			positions.append(Vector2i(x, y))
	
	relative_tile_in_radius_cache[radius] = positions
	
	return positions


func get_tiles_in_radius(row: int, column: int, radius: float) -> Array[RaftTile]:
	var positions: Array[Vector2i] = get_relative_positions_in_radius(radius)
	var tiles: Array[RaftTile] = []

	for pos in positions:
		var tile: RaftTile = get_relative_tile_rc(pos, row, column)
		if tile != null:
			tiles.append(tile)
	return tiles


func heal_all_tiles(amt: int = 1):
	for coord in raft_data_structure:
		raft_data_structure[coord].heal(amt)
		raft_data_structure[coord].fire_health = 0


func _on_child_exiting_tree(node):
	if node is RaftTile:
		if raft_data_structure.get(node.grid_pos) == node:
			raft_data_structure.erase(node.grid_pos)


func play_raft_hit_cannoball():
	$raft_hit_cannonball.play()


func _on_boss_boss_defeated():
	for k in raft_data_structure:
		if raft_data_structure[k].tile_object and raft_data_structure[k].tile_object.get_kind() == "bomb":
			raft_data_structure[k].tile_object.queue_free()
