class_name RaftTile extends Area2D

var damage_number_scene = preload("res://objects/damage_numbers/damage_numbers.tscn")
var tile_break_scene = preload("res://objects/VFX/tile_break/tile_break.tscn")

var raft_ref: Node2D
var grid_pos: Vector2i

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
		queue_free()
		var tile_break= tile_break_scene.instantiate()
		tile_break.position = self.position
		get_parent().add_child(tile_break)
	else:
		process_damage_frames(health)

func damage(value: int):
	health -= value
	generate_dmg_number(-value)
	process_damage_frames(health)

func process_damage_frames(current_health_value):
	match current_health_value:
		2:
			$AnimatedSprite2D.frame = 1
		1:
			$AnimatedSprite2D.frame = 2
		_:
			$AnimatedSprite2D.frame = 0
	

func generate_dmg_number(number_value):
	var dmg_number = damage_number_scene.instantiate()
	dmg_number.number_value = number_value
	dmg_number.position = self.position
	get_parent().add_child(dmg_number)

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
	if south_tile != null:
		array.append(south_tile)

	var west_tile = get_west_tile()
	if west_tile != null:
		array.append(west_tile)

	var east_tile = get_east_tile()
	if east_tile != null:
		array.append(east_tile)

	return array

func get_surrounding_tile_count() -> int:
	return get_surrounding_tiles().size()
