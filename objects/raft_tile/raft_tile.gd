extends Node2D

var row_index = 0
var column_index = 0

func copy_properties(raft_tile: Node2D):
	self.row_index = raft_tile.row_index
	self.column_index = raft_tile.row_index
	self.position = raft_tile.position

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
