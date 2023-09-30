extends Control
#var player_ref: PlayerCharacter # may not need

var options = []
var select_index = 0

# Called when the node enters the scene tree for the first time.
func _ready():
	options = {
		0: [$option_1, preload("res://resources/raft_modules/1x1_blank.gd")],
		1: [$option_2, preload("res://resources/raft_modules/1x1_blank.gd")],
		2: [$option_3, preload("res://resources/raft_modules/1x1_blank.gd")],
	}
	
	render_raft_module(options[0][1], options[0][0].position)
	render_raft_module(options[1][1], options[1][0].position)
	render_raft_module(options[2][1], options[2][0].position)

func render_raft_module(module, pos: Vector2):
	var raft_module_structure = module.get_structure()
	var max_x = -999
	var max_y = -999
	var min_x = 999
	var min_y = 999
	for k in raft_module_structure:
		max_x = max(k.x, max_x)
		max_y = max(k.y, max_y)
		min_x = min(k.x, min_x)
		min_y = min(k.y, min_y)
	
	var module_width = (max_x - min_x + 1) * 32
	var module_height = (max_y - min_y + 1) * 32
		
	for k in raft_module_structure:
		var tile_x_offset = 32 * k.x
		var tile_y_offset = 32 * k.y
		var raft_tile = raft_module_structure[k].instantiate()
		raft_tile.position = pos
		raft_tile.position.x += tile_x_offset + $option_1.size.x/2 - module_width/4
		raft_tile.position.y += tile_y_offset + $option_1.size.y/2 - module_height/4
		self.add_child(raft_tile)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if Input.is_action_just_pressed("up"):
		if select_index > 0:
			select_index -= 1
			print(select_index)
			$selected_option.position = options[select_index][0].position
			print(options[select_index][1])
			$selected_option.position.y -= 5
			$selected_option.position.x -= 5
			print("up yo")
	
	if Input.is_action_just_pressed("down"):
		if select_index < 2:
			select_index += 1
			print(select_index)
#			print($selected_option.position)
			$selected_option.position = options[select_index][0].position
			print(options[select_index][1])
			$selected_option.position.y -= 5
			$selected_option.position.x -= 5
			print("down yo")
