extends Node2D

@onready var raft = get_parent()
var lose_screen_scene_file = "res://scenes/lose_screen/lose_scene.tscn"

var spawn_rate_min = 5.0
var spawn_rate_max = 7.0


var spawnables = [
	{ weight = 10.0, scene = preload("res://objects/raft_objects/water_bucket.tscn") },
	{ weight = 10.0, scene = preload("res://objects/raft_objects/fire.tscn") },
	{ weight = 20.0, scene = preload("res://objects/raft_objects/driftwood.tscn") },
	{ weight = 15.0, scene = preload("res://objects/raft_objects/bomb.tscn") },
	{ weight = 15.0, scene = preload("res://objects/raft_objects/gem.tscn") },
	{ weight = 15.0, scene = preload("res://objects/raft_objects/hammer.tscn") },
	{ weight = 150000.0, scene = preload("res://objects/raft_objects/cannon.tscn") },
] 

func _pick_a_thing():
	var total_weight := 0.0
	for s in spawnables:
		total_weight += s.weight
	var roll := randf_range(0, total_weight)
	for s in spawnables:
		roll -= s.weight
		if roll <= 0:
			return s
	return null

func _spawn_a_thing():
	var s = _pick_a_thing()
	if not s:
		assert(false)
		return
	
	var t = raft.get_random_empty_tile()
	if t == null || t.tile_object != null:
		UTILS.change_to_scene(lose_screen_scene_file)
		return
#	assert(t.tile_object == null)
	
	var obj = s.scene.instantiate()
	obj.grid_pos = t.grid_pos
	obj.raft = raft
	t.add_child(obj)
	t.tile_object = obj
	

func _on_timer_timeout():
	_spawn_a_thing()
	spawn_rate_min -= (spawn_rate_min - 1) / 30
	spawn_rate_max -= (spawn_rate_max - 1) / 30
	$Timer.start(randf_range(spawn_rate_min, spawn_rate_max))

