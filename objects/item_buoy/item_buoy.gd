extends Area2D

var item
var buoy_speed = 20
var raft

var dead = false

#var spawnables = {
	#"water" : preload("res://objects/raft_objects/water_bucket.tscn"),
	#"wood" : preload("res://objects/raft_objects/driftwood.tscn"),
	#"bomb" : preload("res://objects/raft_objects/bomb.tscn"),
	#"gem" : preload("res://objects/raft_objects/gem.tscn"),
	#"hammer" : preload("res://objects/raft_objects/hammer.tscn"),
	#"cannon" : preload("res://objects/raft_objects/cannon.tscn"),
#}

# Called when the node enters the scene tree for the first time.
func _ready():
	if item:
		item.position = Vector2(0, -8)


func _network_spawn(data):
	item = SyncManager.spawn("item", self, GLOBAL_VARS.spawnables[data.item], {})
	position = data.pos
	item.position = Vector2(0, -8)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	self.position += Vector2(0, 1) * delta * buoy_speed
	
	#if dead:
		#SyncManager.despawn(self)


func _on_area_entered(area):
	raft = area.raft_ref
	#seed(MULT_UTILS.mult_rng.randi())
	var tile = raft.get_random_empty_tile()
	if tile:
		raft.place_object(tile.grid_pos, item)
		item.boss_toss(global_position, "good_thing", true)
	#dead = true
	#you can't call the despawn method here, and you can't defer call it, and you also can't have it happen in the regular process so I'm just queue freeing
	#likely can cause a desync if you grab right as it get's launched onto the raft, which could be somewhat repeatable
	queue_free()
