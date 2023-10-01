extends Node2D

@onready var raft = get_parent()

var spawn_rate_min = 5.0
var spawn_rate_max = 7.0


var spawnables = [
	{ weight = 10.0, scene = preload("res://objects/raft_objects/water_bucket.tscn") },
	{ weight = 10.0, scene = preload("res://objects/raft_objects/fire.tscn") },
	{ weight = 1.0, scene = preload("res://objects/raft_objects/driftwood.tscn") },
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
	assert(t.tile_object == null)
	
	var obj = s.scene.instantiate()
	obj.grid_pos = t.grid_pos
	obj.raft = raft
	t.add_child(obj)
	t.tile_object = obj
	

func _on_timer_timeout():
	_spawn_a_thing()
	$Timer.start(randf_range(spawn_rate_min, spawn_rate_max))

