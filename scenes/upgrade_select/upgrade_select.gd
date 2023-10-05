extends Control
signal initiate_module_placement(module)
#var player_ref: PlayerCharacter # may not need

var options = []
var select_index = 0
var upgrade_type = "base"

# Called when the node enters the scene tree for the first time.
func _ready():
	$module_select_widget1.module_selected(true)
	$module_select_widget2.module_selected(false)
	$module_select_widget3.module_selected(false)
	
	var tetros = [
		"o", "i1", "i2", "s1", "s2", "z1", "z2", "t1", "t2", "t3", "t4",
		"j1", "j2", "j3", "j4", "l1", "l2", "l3", "l4",
	]
	var base_fmt = "res://resources/raft_modules/fixed_tetrominoes/%s_" + upgrade_type + ".gd"
	
	options = {
		0: [$module_select_widget1, load(base_fmt % tetros[randi() % tetros.size()]).get_structure()],
		1: [$module_select_widget2, load(base_fmt % tetros[randi() % tetros.size()]).get_structure()],
		2: [$module_select_widget3, load(base_fmt % tetros[randi() % tetros.size()]).get_structure()],
	}
	
	render_raft_module(options[0][1], options[0][0].global_position)
	render_raft_module(options[1][1], options[1][0].global_position)
	render_raft_module(options[2][1], options[2][0].global_position)

func render_raft_module(raft_module_structure, pos: Vector2):
	#var raft_module_structure = module.get_structure()
	var max_x = -999
	var max_y = -999
	var min_x = 999
	var min_y = 999
	for k in raft_module_structure:
		max_x = max(k.x, max_x)
		max_y = max(k.y, max_y)
		min_x = min(k.x, min_x)
		min_y = min(k.y, min_y)
	
	var module_width = (max(max_x, abs(min_x)) + 1) * 32
	var module_height = (max(max_y, abs(min_y)) + 1) * 32
		
	for k in raft_module_structure:
		var tile_x_offset = 32 * k.x + (32*4 - module_width)/2
		var tile_y_offset = 32 * k.y + (32*4 - module_height)/2
		var raft_tile = raft_module_structure[k].instantiate()
		raft_tile.position = pos
		raft_tile.position.x += tile_x_offset - module_width/2 + 16 #+ $module_select_widget1.size.x
		raft_tile.position.y += tile_y_offset - module_height/2 #+ $module_select_widget1.size.y
		raft_tile.visual_only()
		self.add_child(raft_tile)

func render_selected_module_widget(old_index: int, new_index: int):
	options[old_index][0].module_selected(false)
	options[new_index][0].module_selected(true)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	var old_select_index = select_index
	if Input.is_action_just_pressed("up"):
		if select_index == 0:
			select_index = 2
		else:
			select_index -= 1
		render_selected_module_widget(old_select_index, select_index)
		print(select_index)
		print(options[select_index][1])
		
	
	if Input.is_action_just_pressed("down"):
		if select_index == 2:
			select_index = 0
		else:
			select_index += 1
			
		render_selected_module_widget(old_select_index, select_index)
		print(select_index)
		print(options[select_index][1])
		
	if Input.is_action_just_pressed("interact"):
		queue_free()
		initiate_module_placement.emit(options[select_index][1])
#		get_parent().start_placing_module(options[select_index][1])
