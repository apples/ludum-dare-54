class_name RaftTile extends Area2D

var row_index: int = 0
var column_index: int = 0
var raft_ref: Node2D

var grid_pos: Vector2i:
	get:
		return Vector2i(column_index, row_index)

@export var health: int = 3 :
	set = _set_health

@export var tile_object: Node:
	get:
		return tile_object
	set(v):
		if tile_object:
			tile_object.tree_exited.disconnect(_on_tile_object_tree_exited)
		tile_object = v
		if tile_object:
			tile_object.tree_exited.connect(_on_tile_object_tree_exited)

func _on_tile_object_tree_exited():
	tile_object = null

func copy_properties(raft_tile: Node2D):
	self.raft_ref = raft_tile.raft_ref
	self.row_index = raft_tile.row_index
	self.column_index = raft_tile.column_index
	self.position = raft_tile.position

# Called when the node enters the scene tree for the first time.
func _ready():
	if tile_object:
		tile_object.raft = raft_ref
		tile_object.grid_pos = grid_pos

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func _on_body_entered(body):
	if body is Node:
		if body.is_in_group("player"):
			body.add_tile(self)


func _on_body_exited(body):
	if body is Node:
		if body.is_in_group("player"):
			body.remove_tile(self)

func _set_health(value: int):
	health = value
	if health <= 0:
		raft_ref.delete_tile(row_index, column_index)
		queue_free()

func damage(value: int):
	health -= value

func heal(value: int):
	health += value

func get_north_tile() -> RaftTile:
	return raft_ref.get_relative_tile(raft_ref.NORTH, self)

func get_south_tile() -> RaftTile:
	return raft_ref.get_relative_tile(raft_ref.SOUTH, self)

func get_west_tile() -> RaftTile:
	return raft_ref.get_relative_tile(raft_ref.WEST, self)

func get_east_tile() -> RaftTile:
	return raft_ref.get_relative_tile(raft_ref.EAST, self)

func get_surrounding_tiles() -> Array[RaftTile]:
	var array: Array[RaftTile] = []

	var north_tile = get_north_tile()
	if north_tile != null:
		array.append(north_tile)

	var south_tile = get_south_tile()
	if north_tile != null:
		array.append(north_tile)

	var west_tile = get_west_tile()
	if north_tile != null:
		array.append(north_tile)

	var east_tile = get_east_tile()
	if north_tile != null:
		array.append(north_tile)

	return array

func get_surrounding_tile_count() -> int:
	return get_surrounding_tiles().size()
