class_name RaftTile extends Area2D

signal tile_object_changed

var damage_number_scene = preload("res://objects/damage_numbers/damage_numbers.tscn")
var tile_break_scene = preload("res://objects/VFX/tile_break/tile_break.tscn")
@onready var fire_burning = $FireBurning
@onready var fire_fix_meter = $FireSprite/FireFixMeter

var raft_ref: Node2D
var grid_pos: Vector2i

@onready var fire_sprite = $FireSprite
@onready var fire_damage_timer = $FireDamageTimer

@export var health: int = 3 :
	set = _set_health
@export var max_health: int =3

@export var tile_object: Node:
	get:
		return tile_object
	set(v):
		if tile_object == v:
			return
		if tile_object != null:
			tile_object.tree_exiting.disconnect(_on_tile_object_tree_exiting)
		tile_object = v
		if tile_object != null:
			tile_object.tree_exiting.connect(_on_tile_object_tree_exiting)
		tile_object_changed.emit()

var player_obj: Node

var fire_max_health := 1.25
var fire_health := 0.0

var is_on_fire: bool:
	get:
		return fire_health > 0.0

func _on_tile_object_tree_exiting():
	tile_object = null

func ignite():
	if not is_on_fire:
		fire_health = fire_max_health
	

# Called when the node enters the scene tree for the first time.
func _ready():
	if tile_object and raft_ref:
		raft_ref.initialize_object(self)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if is_on_fire:
		if not fire_burning.playing:
			fire_burning.play()
		if fire_damage_timer.is_stopped():
			fire_damage_timer.start()
		if player_obj != null:
			fire_damage_timer.paused = true
			if player_obj.is_standing():
				if Input.is_action_pressed("interact"):
					if Input.is_action_just_pressed("interact"):
						fire_health -= 0.1
					fire_health -= delta
		else:
			fire_damage_timer.paused = false
		fire_fix_meter.value = fire_health / fire_max_health
		fire_fix_meter.visible = fire_health < fire_max_health
	else:
		fire_burning.stop()
		fire_damage_timer.stop()
	
	fire_sprite.visible = is_on_fire


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
	if health > max_health:
		health = max_health

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

func visual_only():
	monitoring = false
	monitorable = false
	if tile_object:
		tile_object.process_mode = Node.PROCESS_MODE_DISABLED


func _on_fire_damage_timer_timeout():
	if not is_on_fire:
		return
	damage(1)
	spread_fire_to_adjacent_tiles()

func spread_fire_to_adjacent_tiles():
	var adjacent_tiles = get_surrounding_tiles()
	
	for tile in adjacent_tiles:
		var fire_spread_chance = randi_range(0, 5)
		
		if fire_spread_chance == 1:
			tile.ignite()
