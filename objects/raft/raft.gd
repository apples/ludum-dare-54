class_name Raft extends Node2D

@export var player: Node
@export var raft_tile_length: int = 5
@export var raft_tile_height: int = 4
var raft_tile_scene = preload("res://objects/raft_tile/raft_tile.tscn")
var raft_tile_cannon_scene = preload("res://objects/raft_tile/raft_tile_cannon.tscn")
var raft_tile_fire_scene = preload("res://objects/raft_tile/raft_tile_fire.tscn")
var raft_tile_cannonball_scene = preload("res://objects/raft_tile/raft_tile_cannonball.tscn")
var raft_tile_water_bucket_scene = preload("res://objects/raft_tile/raft_tile_water_bucket.tscn")
var raft_tile_driftwood_scene = preload("res://objects/raft_tile/raft_tile_driftwood.tscn")
var raft_tile_bomb_scene = preload("res://objects/raft_tile/raft_tile_bomb.tscn")
var raft_tile_gem_scene = preload("res://objects/raft_tile/raft_tile_gem.tscn")

var raft_data_structure = {}

const NORTH := Vector2i(0, -1)
const SOUTH := Vector2i(0, 1)
const WEST := Vector2i(-1, 0)
const EAST := Vector2i(1, 0)

const TILE_SPACING := Vector2(32, 32)

# Called when the node enters the scene tree for the first time.
func _ready():
	print(DATA_STORE.current.highscore)
	generate_raft()
	set_tile(raft_tile_driftwood_scene, 6, 7)
	set_tile(raft_tile_driftwood_scene, 6, 8)
	set_tile(raft_tile_driftwood_scene, 6, 10)
	#set_tile(raft_tile_driftwood_scene, 7, 9)
	set_tile(raft_tile_cannon_scene, 7, 7)
	set_tile(raft_tile_cannon_scene, 7, 8)
	set_tile(raft_tile_cannon_scene, 7, 10)


func find_all_tiles(tile_type):
	var rval = []
	for coord in raft_data_structure:
		var tile_ref = raft_data_structure[coord]
		if tile_ref.tile_object and tile_ref.tile_object.get_kind() == tile_type:
				rval.append(tile_ref)
	return rval


func set_tile(tile_scene: PackedScene, row: int, column: int):
	var new_tile: Node = tile_scene.instantiate()
	new_tile.name = "Tile_%s_%s" % [row, column]
	new_tile.raft_ref = self
	new_tile.grid_pos = Vector2i(column, row)
	new_tile.position = TILE_SPACING * Vector2(new_tile.grid_pos)
	new_tile.tree_exiting.connect(func ():
		if raft_data_structure[new_tile.grid_pos] == new_tile:
			raft_data_structure.erase(new_tile.grid_pos)
	)
	
	var prev = raft_data_structure.get(Vector2i(column, row))
	
	if prev != null:
		prev.queue_free()
	
	raft_data_structure[new_tile.grid_pos] = new_tile
	
	self.add_child(new_tile)

func delete_tile(row: int, column: int):
	raft_data_structure.erase(Vector2i(row, column))
	if raft_data_structure.is_empty():
		queue_free()
		get_parent().raft_destroyed(self)

func generate_raft():
	for r in range(6, 9):
		for c in range(7, 12):
			set_tile(raft_tile_scene, r, c)

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
		check_and_set_highscore()
		
		DATA_STORE.current['highscore']
	return empts.pick_random()

func check_and_set_highscore():
	if DATA_STORE.current.has('highscore'):
		if DATA_STORE.current.highscore < GLOBAL_VARS.score:
			DATA_STORE.current.highscore = GLOBAL_VARS.score
			DATA_STORE.save()

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

	for position in positions:
		var tile: RaftTile = get_relative_tile_rc(position, row, column)
		if tile != null:
			tiles.append(tile)
	return tiles


func heal_all_tiles(amt: int = 1):
	for coord in raft_data_structure:
		raft_data_structure[coord].heal(amt)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func _on_child_exiting_tree(node):
	if node is RaftTile:
		if raft_data_structure.get(node.grid_pos) == node:
			raft_data_structure.erase(node.grid_pos)

func play_raft_hit_cannoball():
	$raft_hit_cannonball.play()
