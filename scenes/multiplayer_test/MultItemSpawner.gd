extends MultiplayerSpawner

@export var raft: Node
#var lose_screen_scene_file = "res://scenes/lose_screen/lose_scene.tscn"
var buoy_scene = preload("res://objects/item_buoy/item_buoy.tscn")
var spawn_rate_min = 2.0
var spawn_rate_max = 3.5
var spawn_acceleration := 60 # lower is faster acceleration

var col_bag := []
var col_ranges := [[1, 16], [5, 10], [7, 8]]

var spawnables_bag := []

var spawnWeights = [
	{ weight = 10, name = "water" },
	{ weight = 40, name = "wood" },
	{ weight = 1, name = "bomb" },
	{ weight = 5, name = "gem" },
	{ weight = 10, name = "hammer" },
	{ weight = 20, name = "cannon" },
]

var spawnables = {
	"water" : preload("res://objects/raft_objects/water_bucket.tscn"),
	"wood" : preload("res://objects/raft_objects/driftwood.tscn"),
	"bomb" : preload("res://objects/raft_objects/bomb.tscn"),
	"gem" : preload("res://objects/raft_objects/gem.tscn"),
	"hammer" : preload("res://objects/raft_objects/hammer.tscn"),
	"cannon" : preload("res://objects/raft_objects/cannon.tscn"),
}

func _init() -> void:
	spawn_function = _spawn_function

func _ready():
	for i in range(5, 10):
		col_bag.append(i)
	col_bag.shuffle()

func _pick_a_thing():
	if spawnables_bag.is_empty():
		for s in spawnWeights:
			for i in range(s.weight):
				spawnables_bag.append(s)
		spawnables_bag.shuffle()
	
	return spawnables_bag.pop_back().name

func _get_col() -> int:
	if col_bag.is_empty():
		for r in col_ranges:
			for i in range(r[0], r[1]):
				col_bag.append(i)
		col_bag.shuffle()
	return col_bag.pop_back()

func _spawn_function(chosenSpawn) -> Node:
	var buoy = load(get_spawnable_scene(0)).instantiate()
	if(raft):
		buoy.global_position = raft.global_position + Vector2(_get_col() * 32, 0)
	else:
		buoy.global_position =  Vector2(randi_range(8,22) * 32, 50)
		#buoy.z_index=5
	
	buoy.item = spawnables[chosenSpawn].instantiate()
	buoy.item.position = Vector2(0, -8)
	buoy.add_child(buoy.item)
	
	buoy.name = "buoy" + str(MULT_UTILS.current_rand)
	buoy.item.name = "item" + str(MULT_UTILS.current_rand)
	
	return buoy

func _on_timer_timeout() -> void:
	if(is_multiplayer_authority()):
		var _multBuoy = spawn(_pick_a_thing())
	spawn_rate_min -= (spawn_rate_min - 1) / spawn_acceleration
	spawn_rate_max -= (spawn_rate_max - 1) / spawn_acceleration
	$Timer.start(randf_range(spawn_rate_min, spawn_rate_max))
