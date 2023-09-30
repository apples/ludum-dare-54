class_name raft_tile extends Node2D

var row_index: int = 0
var column_index: int = 0

var health: int = 100 :
	set = _set_health

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

func _set_health(value: int):
	health = value
	if health <= 0:
		get_parent().remove_child(self)

func damage(value: int):
	health -= value

func heal(value: int):
	health += value
