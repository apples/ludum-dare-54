class_name Raft extends Node2D

@export var raft_tile_length: int = 5
@export var raft_tile_height: int = 4
@export var raft_starting_pos_x: float = 0
@export var raft_starting_pos_y: float = 0
var raft_tile_scene = preload("res://objects/raft_tile/raft_tile.tscn")
var raft_tile_cannon_scene = preload("res://objects/raft_tile/raft_tile_cannon.tscn")
var raft_tile_fire_scene = preload("res://objects/raft_tile/raft_tile_fire.tscn")

var raft_data_structure = {}

const NORTH := Vector2i(0, -1)
const SOUTH := Vector2i(0, 1)
const WEST := Vector2i(-1, 0)
const EAST := Vector2i(1, 0)

# Called when the node enters the scene tree for the first time.
func _ready():
	generate_raft()
	swap_tile(raft_tile_cannon_scene, 2, 4)
	swap_tile(raft_tile_fire_scene, 0, 0)
	swap_tile(raft_tile_fire_scene, 0, 1)
	swap_tile(raft_tile_fire_scene, 1, 1)
	swap_tile(raft_tile_fire_scene, 3, 4)
	
func swap_tile(tile_scene: PackedScene, row: int, column: int):
	var new_tile = tile_scene.instantiate()
	new_tile.copy_properties(raft_data_structure[Vector2i(row, column)])
	raft_data_structure[Vector2i(row, column)].queue_free()
	raft_data_structure[Vector2i(row, column)] = new_tile
	self.add_child(new_tile)

func generate_raft():
	var raft_pos_y: float = raft_starting_pos_y
	var raft_pos_x: float = raft_starting_pos_x
	
	for r in range(raft_tile_height):
		raft_pos_y += 32
		raft_pos_x = raft_starting_pos_x
		
		for c in range(raft_tile_length):
			generate_raft_tile(Vector2(raft_pos_x, raft_pos_y), r, c)
			raft_pos_x += 32

func generate_raft_tile(pos: Vector2, row: int, column: int):
	var tile_to_spawn = raft_tile_scene
#	if row == 3 and column == 2:
#		tile_to_spawn = raft_tile_cannon_scene
	
	var new_raft_tile = tile_to_spawn.instantiate()
	new_raft_tile.row_index = row
	new_raft_tile.column_index = column
	new_raft_tile.set_position(pos)
	raft_data_structure[Vector2i(row, column)] = new_raft_tile
#	raft_data_structure.keys()
	self.add_child(new_raft_tile)

func get_tile(row: int, column: int) -> RaftTile:
	return raft_data_structure.get(Vector2i(row, column))

func get_relative_tile(direction: Vector2i, tile: RaftTile) -> RaftTile:
	return get_tile(tile.row_index + direction.x, tile.column_index + direction.y)

func get_relative_tile_rc(direction: Vector2i, row: int, column: int) -> RaftTile:
	return get_tile(row + direction.x, column + direction.y)

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
