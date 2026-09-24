extends Node2D

var options := []
var selection := 0
var selected := false
var valid := false

@onready var option_nodes : Array[AnimatedSprite2D] = [
	$UpgradeSelection/Box1/AnimatedSprite2D,
	$UpgradeSelection/Box2/AnimatedSprite2D,
	$UpgradeSelection/Box3/AnimatedSprite2D
	]
@onready var raft : CoopRaft = $"/root/CoopGameplay/Raft"
@onready var gameplay = self.get_parent()

@onready var module = $Module

var tetriminos = [
	[Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0), Vector2i(3, 0)],
	[Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0), Vector2i(2, 1)],
	[Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0), Vector2i(2, -1)],
	[Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1)],
	[Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0), Vector2i(1, 1)],
	[Vector2i(0, 0), Vector2i(1, 0), Vector2i(1, 1), Vector2i(2, 1)],
	[Vector2i(0, 0), Vector2i(1, 0), Vector2i(1, -1), Vector2i(2, -1)],
	]

func _ready():
	render_selection()
	
	options.append(tetriminos.pop_at(randi_range(0, tetriminos.size() - 1)))
	options.append(tetriminos.pop_at(randi_range(0, tetriminos.size() - 1)))
	options.append(tetriminos.pop_at(randi_range(0, tetriminos.size() - 1)))
	
	for i in range(3):
		var nodes = option_nodes[i].get_parent().get_children()
		for j in range(4):
			nodes[j + 1].position = options[i][j] * 32
			

func _process(delta: float) -> void:
	if not selected:
		if Input.is_action_just_pressed("down"):
			selection = (selection + 1) % 3
		if Input.is_action_just_pressed("up"):
			selection = posmod(selection - 1, 3)
		render_selection()
		
		if Input.is_action_just_pressed("interact"):
			selected = true
			$UpgradeSelection.hide()
			module.show()
			for i in range(4):
				options[selection][i] += Vector2i(6, 6)
			check_valid()
			update_tile_pos()
			
	else:
		var dir := Vector2i(
			int(Input.is_action_just_pressed("right")) - int(Input.is_action_just_pressed("left")),
			int(Input.is_action_just_pressed("down")) - int(Input.is_action_just_pressed("up"))
		)
		
		if dir != Vector2i.ZERO:
			for i in range(4):
				options[selection][i] += dir
			check_valid()
			update_tile_pos()
		
		if Input.is_action_just_pressed("interact") and valid:
			gameplay.placed_tile_coords = options[selection]
			queue_free()

func render_selection():
	option_nodes[0].play("selected" if selection == 0 else "unselected")
	option_nodes[1].play("selected" if selection == 1 else "unselected")
	option_nodes[2].play("selected" if selection == 2 else "unselected")

func update_tile_pos():
	var tiles = module.get_children()
	for i in range(4):
		tiles[i].position = raft.grid_pos_to_global_position(options[selection][i])

func check_valid():
	var colliding = false
	var touching = false
	for i in range(4):
		var coord = options[selection][i]
		if raft.get_tile(coord) != null:
			colliding = true
		if raft.get_adjacent_tiles(coord).size() > 0:
			touching = true
	
	if touching and not colliding:
		valid = true
		for tile : AnimatedSprite2D in module.get_children():
			tile.modulate = Color.GREEN
	else:
		valid = false
		for tile : AnimatedSprite2D in module.get_children():
			tile.modulate = Color.RED
