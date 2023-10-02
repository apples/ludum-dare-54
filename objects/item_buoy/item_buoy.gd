extends Area2D

var item
var buoy_speed = 20
var spawnables = [
	{ weight = 10.0, scene = preload("res://objects/raft_objects/water_bucket.tscn") },
	#{ weight = 10.0, scene = preload("res://objects/raft_objects/fire.tscn") },
	{ weight = 20.0, scene = preload("res://objects/raft_objects/driftwood.tscn") },
	#{ weight = 15.0, scene = preload("res://objects/raft_objects/bomb.tscn") },
	{ weight = 15.0, scene = preload("res://objects/raft_objects/gem.tscn") },
	{ weight = 15.0, scene = preload("res://objects/raft_objects/hammer.tscn") },
	{ weight = 15.0, scene = preload("res://objects/raft_objects/cannon.tscn") },
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

# Called when the node enters the scene tree for the first time.
func _ready():
	item = _pick_a_thing().scene.instantiate()
	item.position = Vector2(0, -8)
	add_child(item)
	


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	self.position += Vector2(0, 1) * delta * buoy_speed


func _on_area_entered(area):
	var raft = area.raft_ref
	item.raft = raft
	var tile = raft.get_random_empty_tile()
	if tile:
		item.grid_pos = tile.grid_pos
		item.reparent(tile)
		tile.tile_object = item
		item.boss_toss(item.global_position, Color(0.1, 0.9, 0.1, 0.9))
	queue_free()
