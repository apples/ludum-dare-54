class_name RaftTile extends Area2D

var row_index: int = 0
var column_index: int = 0

@export var health: int = 3 :
	set = _set_health

var raft = get_parent()

func copy_properties(raft_tile: Node2D):
	self.row_index = raft_tile.row_index
	self.column_index = raft_tile.row_index
	self.position = raft_tile.position

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func interact(player):
	print("Player interacted with dumb tile at <%s, %s>." % [row_index, column_index])

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
		queue_free()

func damage(value: int):
	health -= value

func heal(value: int):
	health += value

func get_north_tile() -> RaftTile:
	return raft.get_relative_tile(raft.north, self)

func get_south_tile() -> RaftTile:
	return raft.get_relative_tile(raft.South, self)

func get_west_tile() -> RaftTile:
	return raft.get_relative_tile(raft.west, self)

func get_east_tile() -> RaftTile:
	return raft.get_relative_tile(raft.east, self)

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
