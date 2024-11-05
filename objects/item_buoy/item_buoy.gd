extends Area2D

var item
var buoy_speed = 20
var raft

# Called when the node enters the scene tree for the first time.
func _ready():
	item.position = Vector2(0, -8)
	


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	self.position += Vector2(0, 1) * delta * buoy_speed


func _on_area_entered(area):
	raft = area.raft_ref
	if is_multiplayer_authority():
		var tile = raft.get_random_empty_tile()
		collision.rpc(tile.grid_pos)
		queue_free()

@rpc("authority", "call_local", "reliable")
func collision(grid_pos):
	if grid_pos:
		if !raft:
			raft = $"../../player_raft"
		raft.place_object(grid_pos, item)
		item.boss_toss(global_position, "good_thing", true)
