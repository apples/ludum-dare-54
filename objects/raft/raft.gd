class_name Raft extends Node2D

@export var raft_tile_length: int = 5
@export var raft_tile_height: int = 4
var raft_tile_scene = preload("res://objects/raft_tile/raft_tile.tscn")
var raft_tile_cannon_scene = preload("res://objects/raft_tile/raft_tile_cannon.tscn")
var raft_tile_fire_scene = preload("res://objects/raft_tile/raft_tile_fire.tscn")
var raft_tile_cannonball_scene = preload("res://objects/raft_tile/raft_tile_cannonball.tscn")

var raft_data_structure = {}

const NORTH := Vector2i(0, -1)
const SOUTH := Vector2i(0, 1)
const WEST := Vector2i(-1, 0)
const EAST := Vector2i(1, 0)

const TILE_SPACING := Vector2(32, 32)

# Called when the node enters the scene tree for the first time.
func _ready():
	generate_raft()
	swap_tile(raft_tile_cannonball_scene, 6, 7)
	swap_tile(raft_tile_cannonball_scene, 6, 8)
	swap_tile(raft_tile_cannonball_scene, 6, 10)
	
func swap_tile(tile_scene: PackedScene, row: int, column: int):
	var new_tile = tile_scene.instantiate()
	
	var prev = raft_data_structure.get(Vector2i(column, row))
	
	if prev != null:
		new_tile.copy_properties(raft_data_structure[Vector2i(column, row)])
		prev.queue_free()
	else:
		new_tile.raft_ref = self
		new_tile.row_index = row
		new_tile.column_index = column
		new_tile.set_position(TILE_SPACING * Vector2(column, row))
	
	raft_data_structure[Vector2i(column, row)] = new_tile
	
	self.add_child(new_tile)

func delete_tile(row: int, column: int):
	raft_data_structure.erase(Vector2i(row, column))
	if raft_data_structure.is_empty():
		queue_free()
		get_parent().raft_destroyed(self)

func generate_raft():
	for r in range(6, 9):
		for c in range(7, 12):
			generate_raft_tile(r, c)

func generate_raft_tile(row: int, column: int):
	var tile_to_spawn = raft_tile_scene
#	if row == 3 and column == 2:
#		tile_to_spawn = raft_tile_cannon_scene
	
	swap_tile(tile_to_spawn, row, column)

func rc_to_pos(rc: Vector2i) -> Vector2:
	return position + Vector2(rc.x, rc.y) * TILE_SPACING

func get_tile_at(pos: Vector2) -> RaftTile:
	var rc := Vector2i((pos + TILE_SPACING/2.0) / TILE_SPACING)
	return raft_data_structure.get(rc)

func get_tile(row: int, column: int) -> RaftTile:
	return raft_data_structure.get(Vector2i(column, row))

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
	return get_tile(tile.row_index + direction.y, tile.column_index + direction.x)

func get_relative_tile_rc(direction: Vector2i, row: int, column: int) -> RaftTile:
	return get_tile(row + direction.y, column + direction.x)

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

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func _on_child_exiting_tree(node):
	if node is RaftTile:
		if raft_data_structure.get(node.grid_pos) == node:
			raft_data_structure.erase(node.grid_pos)

func play_raft_hit_cannoball():
	$raft_hit_cannonball.play()
