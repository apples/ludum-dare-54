extends Node2D

@export var raft_tile_length = 5
@export var raft_tile_height = 4
@export var raft_starting_pos_x = 350
@export var raft_starting_pos_y = 100

# Called when the node enters the scene tree for the first time.
func _ready():
	generate_raft()

func generate_raft():
	var raft_pos_y = raft_starting_pos_y
	var raft_pos_x = raft_starting_pos_x
	
	for r in range(raft_tile_height):
		raft_pos_y += 32
		raft_pos_x = raft_starting_pos_x
		
		for c in range(raft_tile_length):
			generate_raft_tile(Vector2(raft_pos_x, raft_pos_y))
			raft_pos_x += 32

func generate_raft_tile(pos: Vector2):
	var new_raft_tile = Sprite2D.new()
	new_raft_tile.texture = preload("res://assets/textures/raft.png")
	new_raft_tile.set_position(pos)
	self.add_child(new_raft_tile)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
