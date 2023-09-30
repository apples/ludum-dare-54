class_name raft_tile extends Area2D

var row_index: int = 0
var column_index: int = 0

@export var health: int = 3 :
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

func interact(player: PlayerCharacter):
	print("Player interacted with dumb tile at <%s, %s>." % [row_index, column_index])

func _on_body_entered(body):
	if body is Node:
		if body.is_in_group("player"):
			body.add_tile(self)


func _on_body_exited(body):
	if body is Node:
		if body.is_in_group("player"):
			body.remove_tile(self)

func _set_health(value: int):
	health = value
	if health <= 0:
		get_parent().remove_child(self)

func damage(value: int):
	health -= value

func heal(value: int):
	health += value
