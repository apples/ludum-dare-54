extends Area2D

var item
var buoy_speed = 20

# Called when the node enters the scene tree for the first time.
func _ready():
	item.position = Vector2(0, -8)
	


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	self.position += Vector2(0, 1) * delta * buoy_speed


func _on_area_entered(area):
	var raft = area.raft_ref
	var tile = raft.get_random_empty_tile()
	if tile:
		raft.place_object(tile.grid_pos, item)
		item.boss_toss(global_position, "good_thing", true)
	queue_free()
