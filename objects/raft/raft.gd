class_name Raft extends Node2D

@export var raft_tile_length: int = 5
@export var raft_tile_height: int = 4
@export var raft_starting_pos_x: float = 0
@export var raft_starting_pos_y: float = 0
var raft_tile_scene = preload("res://objects/raft_tile/raft_tile.tscn")
var raft_tile_cannon_scene = preload("res://objects/raft_tile/raft_tile_cannon.tscn")
var raft_tile_fire_scene = preload("res://objects/raft_tile/raft_tile_fire.tscn")

var raft_data_structure = {}

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

const north := Vector2i(0, -1)
const south := Vector2i(0, 1)
const west := Vector2i(-1, 0)
const east := Vector2i(1, 0)

func get_relative_tile(direction: Vector2i, tile: RaftTile) -> RaftTile:
	return get_tile(tile.row_index + direction.x, tile.column_index + direction.y)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
