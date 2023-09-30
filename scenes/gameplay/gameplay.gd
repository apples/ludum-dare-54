extends Node2D


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	var x = randi() % 100
	if x > 90:
		var tiles = $raft.get_children()
		if tiles.size() > 0:
			var tile = tiles.front() as raft_tile
			tile.damage(randi() % 100)
