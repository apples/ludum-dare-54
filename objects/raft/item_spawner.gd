extends Node2D

@export var raft: Node
#var lose_screen_scene_file = "res://scenes/lose_screen/lose_scene.tscn"
var buoy_scene = preload("res://objects/item_buoy/item_buoy.tscn")
var spawn_rate_min = 2.0
var spawn_rate_max = 3.5
var spawn_acceleration := 60 # lower is faster acceleration

var col_bag := []
var col_ranges := [[1, 16], [5, 10], [7, 8]]

var spawnables_bag := []

var spawnables = [
	{ weight = 10, scene = preload("res://objects/raft_objects/water_bucket.tscn") },
	{ weight = 40, scene = preload("res://objects/raft_objects/driftwood.tscn") },
	#{ weight = 15.0, scene = preload("res://objects/raft_objects/bomb.tscn") },
	{ weight = 5, scene = preload("res://objects/raft_objects/gem.tscn") },
	{ weight = 10, scene = preload("res://objects/raft_objects/hammer.tscn") },
	{ weight = 20, scene = preload("res://objects/raft_objects/cannon.tscn") },
]

func _ready():
	for i in range(5, 10):
		col_bag.append(i)
	col_bag.shuffle()

func _pick_a_thing():
	if spawnables_bag.is_empty():
		for s in spawnables:
			for i in range(s.weight):
				spawnables_bag.append(s)
		spawnables_bag.shuffle()
	
	return spawnables_bag.pop_back()

func _get_col() -> int:
	if col_bag.is_empty():
		for r in col_ranges:
			for i in range(r[0], r[1]):
				col_bag.append(i)
		col_bag.shuffle()
	return col_bag.pop_back()

func _spawn_a_buoy():
	var buoy = buoy_scene.instantiate()
	if(raft):
		buoy.global_position = raft.global_position + Vector2(_get_col() * 32, 0)
	else:
		buoy.global_position =  Vector2(randi_range(8,22) * 32, 50)
		#buoy.z_index=5
	
	buoy.item = _pick_a_thing().scene.instantiate()
	buoy.item.position = Vector2(0, -8)
	buoy.add_child(buoy.item)
	
	get_parent().add_child(buoy)

func _on_timer_timeout():
	_spawn_a_buoy()
	spawn_rate_min -= (spawn_rate_min - 1) / spawn_acceleration
	spawn_rate_max -= (spawn_rate_max - 1) / spawn_acceleration
	$Timer.start(randf_range(spawn_rate_min, spawn_rate_max))
